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
    comment_changeset = Comment.changeset(%Comment{}, %{"content" => ""})

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
      |> assign_form(comment_changeset)
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

    %{comments: comments_list, has_next: has_next} =
      Comments.get_comments(
        post.id,
        socket.assigns.current_user && socket.assigns.current_user.id,
        socket.assigns.comments_per_load,
        socket.assigns.comment_offset
      )

    IO.inspect(comments_list, label: "Comments List")

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:post, post)
     |> assign(:current_path, current_path)
     |> assign(:bookmarked?, bookmarked)
     |> assign(:is_subscribed, is_subscribed?)
     |> assign(:is_following, is_following?)
     |> assign(:reactions, reactions)
     # ✅ assign only the list
     |> assign(:comments, comments_list)
     # ✅ store has_next flag
     |> assign(:comments_has_next, has_next)
     |> assign(:comment_changeset, Comment.changeset(%Comment{}, %{"content" => ""}))
     |> assign(:total_comments, 100)}
  end

  @impl true

  def handle_event("add_comment", %{"comment" => comment_params}, socket) do
    add_comment_or_reply(socket, comment_params)
  end

  defp add_comment_or_reply(socket, comment, reply_to \\ nil) do
    # IO.inspect(content, label: "Content for Reply")
    case socket.assigns.current_user do
      nil ->
        {:noreply, put_flash(socket, :error, "You must be logged in to comment")}

      user ->
        comment_params =
          %{}
          |> Map.put("content", comment)
          |> Map.put("user_id", user.id)
          |> Map.put("post_id", socket.assigns.post.id)
          |> Map.put("parent_id", reply_to)

        case Blogging.Repo.insert(Comment.changeset(%Comment{}, comment_params)) do
          {:ok, comment} ->
            enriched_comment = Comments.get_single_comment(comment.id, comment.user_id)
            topic = "post:comments:#{socket.assigns.post.id}"
            BloggingWeb.Endpoint.broadcast(topic, "new_comment", %{comment: enriched_comment})

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

  @impl true
  def handle_info({:add_reply, %{parent_id: parent_id, content: content}}, socket) do
    IO.inspect(parent_id, label: "Parent ID for Reply")
    IO.inspect(content, label: "Content for Reply")
    # Ensure the content is not empty
    add_comment_or_reply(socket, content, parent_id)
  end

  @impl true
  def handle_info({:edit_reply, %{comment_id: comment_id, content: content}}, socket) do
    edit_comment_or_reply(socket, comment_id, content)
  end

  @impl true
  def handle_info({:edit_comment, %{comment_id: comment_id, content: content}}, socket) do
    edit_comment_or_reply(socket, comment_id, content)
  end

  defp edit_comment_or_reply(socket, comment_id, content) do
    with %Comment{} = comment <- Blogging.Repo.get(Comment, comment_id),
         {:ok, updated_comment} <-
           Blogging.Repo.update(Comment.changeset(comment, %{content: content})),
         enriched_comment <-
           Comments.get_single_comment(updated_comment.id, updated_comment.user_id) do
      topic = "post:comments:#{socket.assigns.post.id}"

      BloggingWeb.Endpoint.broadcast(topic, "update_comment", %{content: enriched_comment})

      {:noreply, socket}
    else
      nil ->
        {:noreply, put_flash(socket, :error, "Comment not found")}

      {:error, changeset} ->
        {:noreply, assign(socket, :comment_changeset, changeset)}
    end
  end

  def handle_info(
        %{event: "update_comment", payload: %{content: content}},
        socket
      ) do
    updated_comments =
      update_comment_in_tree(
        socket.assigns.comments,
        content
      )

    {:noreply, assign(socket, :comments, updated_comments)}
  end

  # @impl true
  # def handle_info({:comment_updated, updated_comment}, socket) do
  #   updated_comments =
  #     update_comment_in_tree(socket.assigns.comments, updated_comment)

  #   {:noreply, assign(socket, :comments, updated_comments)}
  # end

  def handle_event("cancel_reply", _, socket) do
    {:noreply, assign(socket, :reply_to, nil)}
  end

  def handle_event("load-more-comments", _params, socket) do
    new_offset = socket.assigns.comment_offset + socket.assigns.comments_per_load

    %{comments: comments_list, has_next: has_next} =
      Comments.get_comments(
        socket.assigns.post.id,
        socket.assigns.current_user && socket.assigns.current_user.id,
        socket.assigns.comments_per_load,
        new_offset
      )

    updated_comments = socket.assigns.comments ++ comments_list

    {:noreply,
     socket
     |> assign(:comments, updated_comments)
     |> assign(:comment_offset, new_offset)
     |> assign(:comments_has_next, has_next)}
  end

  def handle_event("load-comments", _params, socket) do
    Reactions.populate_data(
      socket.assigns.current_user && socket.assigns.current_user.id,
      socket.assigns.post.id
    )

    {:noreply, socket}
  end

  @impl true
  def handle_info({:load_replies, %{"parent_id" => parent_id}}, socket) do
    current_user_id = socket.assigns.current_user.id

    # ensure a map
    offsets = Map.get(socket.assigns, :reply_offsets, %{})
    offset = Map.get(offsets, parent_id, 0)
    limit = 3

    replies =
      Blogging.Contents.Comments.Comments.get_replies(parent_id, current_user_id, limit, offset)

    updated_comments =
      insert_or_append_replies(socket.assigns.comments, parent_id, replies)

    updated_offsets = Map.put(offsets, parent_id, offset + limit)

    IO.inspect(updated_comments, label: "Updated Comments after loading replies")

    {:noreply,
     socket
     |> assign(:comments, updated_comments)
     |> assign(:reply_offsets, updated_offsets)}
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

    IO.inspect(new_comment, label: "New Comment Received")

    {:noreply, assign(socket, :comments, updated_comments)}
  end

  # def handle_info({:load_replies, %{"parent_id" => parent_id}}, socket) do

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

  @impl true
  def handle_info({:delete_comment, %{comment_id: comment_id}}, socket) do
    case socket.assigns.current_user do
      nil ->
        {:noreply, put_flash(socket, :error, "You must be logged in to delete a comment")}

      _user ->
        comment = Blogging.Repo.get!(Comment, comment_id)

        # Optional: check if the current user is the owner
        # if comment.user_id != socket.assigns.current_user.id do
        #   {:noreply, put_flash(socket, :error, "Unauthorized")}
        # else

        {:ok, _} = Blogging.Repo.delete(comment)

        # Broadcast removal to all connected clients
        topic = "post:comments:#{socket.assigns.post.id}"
        BloggingWeb.Endpoint.broadcast(topic, "delete_comment", %{comment_id: comment_id})

        {:noreply, put_flash(socket, :info, "Comment deleted")}
    end
  end

  @impl true
  def handle_info(%{event: "delete_comment", payload: %{comment_id: id}}, socket) do
    updated_comments = remove_comment_from_tree(socket.assigns.comments, id)
    {:noreply, assign(socket, :comments, updated_comments)}
  end

  defp remove_comment_from_tree(comments, target_id) do
    comments
    |> Enum.reject(&(&1.id == target_id))
    |> Enum.map(fn comment ->
      Map.update(comment, :replies, [], fn replies ->
        remove_comment_from_tree(replies, target_id)
      end)
    end)
  end

  #   BloggingWeb.Endpoint.broadcast(
  #   "comments:post:#{post_id}",
  #   "new_comment",
  #   %{comment: new_comment}
  # )

  defp insert_comment_into_tree(comments, new_comment) do
    # Top-level comment
    if is_nil(new_comment.parent) do
      IO.inspect(new_comment, label: "Inserting Top-level Comment")
      [Map.put(new_comment, :replies, []) | comments]
    else
      Enum.map(comments, fn comment ->
        if comment.id == new_comment.parent do
          IO.inspect(comment, label: "Inserting Reply into Comment")

          replies = (comment.replies || []) ++ [Map.put(new_comment, :replies, [])]

          comment
          |> Map.put(:replies, replies)
          |> Map.update!(:reply_count, &(&1 + 1))
        else
          Map.update(comment, :replies, [], fn child_replies ->
            insert_comment_into_tree(child_replies, new_comment)
          end)
        end
      end)
    end
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

  # def handle_event("load-replies", %{"parent_id" => parent_id}, socket) do
  #   user_id = socket.assigns.current_user.id
  #   replies = Blogging.Contents.Comments.get_replies(parent_id, user_id)

  #   updated_comments = insert_replies_in_tree(socket.assigns.comments, parent_id, replies)

  #   {:noreply, assign(socket, :comments, updated_comments)}
  # end

  defp insert_or_append_replies(comments, parent_id, %{replies: new_replies, has_next: has_next}) do
    Enum.map(comments, fn comment ->
      cond do
        # If this is the parent comment where replies need to be appended
        comment.id == parent_id ->
          updated_replies = (comment[:replies] || []) ++ new_replies

          comment
          |> Map.put(:replies, updated_replies)
          # ✅ store has_next for replies
          |> Map.put(:replies_has_next, has_next)
          # ✅ ensure replies are visible
          |> Map.put(:hide_replies, false)

        # If this comment has nested replies, search deeper
        Map.has_key?(comment, :replies) ->
          updated_children =
            insert_or_append_replies(comment.replies, parent_id, %{
              replies: new_replies,
              has_next: has_next
            })

          comment
          |> Map.put(:replies, updated_children)

        # If no match, return comment as is
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

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp page_title(:show), do: "Show Post"
  defp page_title(:edit), do: "Edit Post"
end
