defmodule BloggingWeb.PostLive.Show do
  alias Blogging.Contents.Comments.Comments
  alias Blogging.Contents.Reactions.Reactions
  alias Blogging.Accounts.EmailSubscriptions
  alias Blogging.Contents.Bookmarks.Bookmarks
  alias Blogging.Accounts
  use BloggingWeb, :live_view

  alias Blogging.Contents.Posts.Posts
  alias Blogging.Accounts.UserFollowers
  alias Blogging.Contents.Comments.Comment

  @impl true
  def mount(_params, session, socket) do
    current_user = Accounts.get_user_by_session_token(session["user_token"])

    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(:page_title, "Post Details")
      |> assign(:post, nil)
      |> assign(:is_following, false)
      |> assign(:is_subscribed, false)
      |> assign(:bookmarked, false)
      |> assign(:reactions, %{})
      |> assign(:comments, [])
      |> assign(:comment_changeset, Comment.changeset(%Comment{}, %{}))
      |> assign(:reply_to, nil)
      |> assign(:comment_offset, 0)
      |> assign(:comments_per_load, 5)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, url, socket) do
    if connected?(socket) do
      # Subscribe to reaction and comment updates
      BloggingWeb.Endpoint.subscribe("post:reactions:#{id}")
      BloggingWeb.Endpoint.subscribe("post:comments:#{id}")
    end

    post =
      Posts.get_post(id)
      |> Blogging.Repo.preload([
        :user
      ])

    current_path = URI.parse(url).path

    bookmarked =
      case Bookmarks.get_bookmark_by_user_and_post(socket.assigns.current_user.id, post.id) do
        nil -> false
        _ -> true
      end

    is_following? =
      if socket.assigns.current_user do
        UserFollowers.following?(socket.assigns.current_user, post.user)
      else
        false
      end

    is_subscribed? =
      if socket.assigns.current_user do
        EmailSubscriptions.subscribed?(post.user.id, socket.assigns.current_user.id)
      else
        false
      end

    reactions =
      Blogging.Contents.Reactions.Reactions.count_reactions_and_user_reaction(
        "post",
        post.id,
        socket.assigns.current_user && socket.assigns.current_user.id
      )

    comments =
      Comments.get_comments(
        post.id,
        socket.assigns.current_user && socket.assigns.current_user.id,
        socket.assigns.comments_per_load,
        socket.assigns.comment_offset
      )

    IO.inspect(comments, label: "Loaded Comments")

    replies =
      Comments.get_replies(
        List.first(comments).id,
        socket.assigns.current_user && socket.assigns.current_user.id,
        socket.assigns.comments_per_load,
        socket.assigns.comment_offset
      )

    IO.inspect(replies, label: "Loaded Replies")

    replies_two =
      Comments.get_replies(
        List.first(replies).id,
        socket.assigns.current_user && socket.assigns.current_user.id,
        socket.assigns.comments_per_load,
        socket.assigns.comment_offset
      )

    IO.inspect(replies_two, label: "Loaded Replies two 2")

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:post, post)
     |> assign(:current_path, current_path)
     |> assign(:bookmarked?, bookmarked)
     |> assign(:is_subscribed, is_subscribed?)
     |> assign(:is_following, is_following?)
     |> assign(:reactions, reactions)
     |> assign(:comments, comments)
     |> assign(:total_comments, 100)}
  end

  @impl true
  def handle_event("add_comment", %{"comment" => comment_params}, socket) do
    case socket.assigns.current_user do
      nil ->
        {:noreply, put_flash(socket, :error, "You must be logged in to comment")}

      user ->
        comment_params =
          comment_params
          |> Map.put("user_id", user.id)
          |> Map.put("post_id", socket.assigns.post.id)
          |> Map.put("parent_id", socket.assigns.reply_to)

        case Blogging.Repo.insert(Comment.changeset(%Comment{}, comment_params)) do
          {:ok, comment} ->
            topic = "post:comments:#{socket.assigns.post.id}"
            BloggingWeb.Endpoint.broadcast(topic, "new_comment", %{comment: comment})

            {:noreply,
             socket
             |> assign(:comment_changeset, Comment.changeset(%Comment{}, %{}))
             |> assign(:reply_to, nil)
             |> put_flash(:info, "Comment added!")}

          {:error, changeset} ->
            {:noreply, assign(socket, :comment_changeset, changeset)}
        end
    end
  end

  def handle_event("reply", %{"comment-id" => comment_id}, socket) do
    {:noreply, assign(socket, :reply_to, comment_id)}
  end

  def handle_event("cancel_reply", _, socket) do
    {:noreply, assign(socket, :reply_to, nil)}
  end

  def handle_event("load-more-comments", _params, socket) do
    new_offset = socket.assigns.comment_offset + socket.assigns.comments_per_load

    new_comments =
      Comments.get_comments(
        socket.assigns.post.id,
        socket.assigns.current_user && socket.assigns.current_user.id,
        socket.assigns.comments_per_load,
        new_offset
      )

    comments =
      build_comment_tree_with_offset(
        new_comments,
        socket.assigns.comment_offset,
        socket.assigns.comments_per_load
      )

    updated_comments = socket.assigns.comments ++ comments

    {:noreply,
     socket |> assign(:comments, updated_comments) |> assign(:comment_offset, new_offset)}
  end

  def handle_event("load-comments", _params, socket) do
    Reactions.populate_data(
      socket.assigns.current_user && socket.assigns.current_user.id,
      socket.assigns.post.id
    )

    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "new_reaction"}, socket) do
    reactions =
      Blogging.Contents.Reactions.Reactions.count_reactions_and_user_reaction(
        "post",
        socket.assigns.post.id,
        socket.assigns.current_user && socket.assigns.current_user.id
      )

    {:noreply, assign(socket, :reactions, reactions)}
  end

  @impl true
  def handle_info(%{event: "new_comment", payload: %{comment: new_comment}}, socket) do
    updated_comments =
      insert_comment_into_tree(
        socket.assigns.comments,
        new_comment
      )

    {:noreply, assign(socket, :comments, updated_comments)}
  end

  #   BloggingWeb.Endpoint.broadcast(
  #   "comments:post:#{post_id}",
  #   "new_comment",
  #   %{comment: new_comment}
  # )

  defp insert_comment_into_tree(comments, new_comment) do
    # Top-level comment
    if is_nil(new_comment.parent) do
      [Map.put(new_comment, :replies, []) | comments]
    else
      Enum.map(comments, fn comment ->
        if comment.id == new_comment.parent do
          replies = (comment.replies || []) ++ [Map.put(new_comment, :replies, [])]
          Map.put(comment, :replies, replies)
        else
          Map.update(comment, :replies, [], fn child_replies ->
            insert_comment_into_tree(child_replies, new_comment)
          end)
        end
      end)
    end
  end

  @impl true
  def handle_info(%{event: "update_comment", payload: %{comment: updated_comment}}, socket) do
    updated_comments =
      update_comment_in_tree(
        socket.assigns.comments,
        updated_comment
      )

    {:noreply, assign(socket, :comments, updated_comments)}
  end

  # BloggingWeb.Endpoint.broadcast(
  #   "comments:post:#{post_id}",
  #   "update_comment",
  #   %{comment: updated_comment}
  # )

  defp update_comment_in_tree(comments, updated_comment) do
    Enum.map(comments, fn comment ->
      cond do
        comment.id == updated_comment.id ->
          Map.merge(comment, updated_comment)

        Map.has_key?(comment, :replies) ->
          Map.update!(comment, :replies, fn replies ->
            update_comment_in_tree(replies, updated_comment)
          end)

        true ->
          comment
      end
    end)
  end

  @impl true
  def handle_info(%{event: "add_reaction", payload: %{comment: updated_comment}}, socket) do
    updated_comments =
      update_reaction_in_tree(
        socket.assigns.comments,
        updated_comment.id,
        updated_comment.reaction_data
      )

    {:noreply, assign(socket, :comments, updated_comments)}
  end

  # BloggingWeb.Endpoint.broadcast(
  #   "comments:post:#{post_id}",
  #   "add_reaction",
  #   %{comment: %{id: comment.id, reaction_data: updated_reaction_data}}
  # )

  defp update_reaction_in_tree(comments, target_id, new_reaction_data) do
    Enum.map(comments, fn comment ->
      cond do
        comment.id == target_id ->
          Map.put(comment, :reaction_data, new_reaction_data)

        Map.has_key?(comment, :replies) ->
          updated_replies = update_reaction_in_tree(comment.replies, target_id, new_reaction_data)
          Map.put(comment, :replies, updated_replies)

        true ->
          comment
      end
    end)
  end

  defp build_comment_tree_with_offset(comments, offset, limit) do
    comments_by_id = Enum.group_by(comments, & &1.id)

    comments
    |> Enum.filter(&is_nil(&1.parent_id))
    |> Enum.sort_by(& &1.inserted_at, {:desc, NaiveDateTime})
    |> Enum.drop(offset)
    |> Enum.take(limit)
    |> Enum.map(&add_replies(&1, comments_by_id))
  end

  defp add_replies(comment, comments_by_id) do
    replies =
      (comments_by_id[comment.id] || [])
      |> Enum.flat_map(& &1.replies)
      |> Enum.map(&add_replies(&1, comments_by_id))

    %{comment | replies: replies}
  end

  defp page_title(:show), do: "Show Post"
  defp page_title(:edit), do: "Edit Post"
end
