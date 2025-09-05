defmodule BloggingWeb.PostLive.ShowBackup do
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
      |> Blogging.Repo.preload([:user, comments: [:user, :reactions], reactions: [:user]])

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

    # Group reactions by type
    # reactions =
    #   post.reactions
    #   |> Enum.group_by(& &1.type)
    #   |> Map.new(fn {k, v} -> {k, length(v)} end)

    reactions =
      Blogging.Contents.Reactions.Reactions.count_reactions_and_user_reaction(
        "post",
        post.id,
        socket.assigns.current_user && socket.assigns.current_user.id
      )

    # IO.inspect(post.reactions, label: "Reactions")

    # Build comment tree
    comments = build_comment_tree(post.comments)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:post, post)
     |> assign(:current_path, current_path)
     |> assign(:bookmarked?, bookmarked)
     |> assign(:is_subscribed, is_subscribed?)
     |> assign(:is_following, is_following?)
     |> assign(:reactions, reactions)
     |> assign(:comments, comments)}
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
            # Broadcast the new comment to all subscribers
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

  @impl true


  @impl true
  def handle_info(%{event: "new_comment", payload: %{comment: _comment}}, socket) do
    post =
      Posts.get_post(socket.assigns.post.id)
      |> Blogging.Repo.preload(comments: [:user, :reactions])

    comments = build_comment_tree(post.comments)

    {:noreply, assign(socket, :comments, comments)}
  end

  # Keep all your existing follow/unfollow, subscribe/unsubscribe, bookmark handlers
  # ... (they remain the same as in your original code)

  defp build_comment_tree(comments) do
    comments_by_id = Enum.group_by(comments, & &1.id)

    _roots =
      comments
      |> Enum.filter(&is_nil(&1.parent_id))
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
