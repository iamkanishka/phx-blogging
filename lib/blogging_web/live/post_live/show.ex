defmodule BloggingWeb.PostLive.Show do
  alias Blogging.Contents.Bookmarks.Bookmarks
  alias Blogging.Accounts
  use BloggingWeb, :live_view

  alias Blogging.Contents.Posts.Posts
  alias Blogging.Accounts.UserFollowers

  @impl true
  def mount(_params, session, socket) do
    current_user = Accounts.get_user_by_session_token(session["user_token"])

    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(:page_title, "Post Details")
      |> assign(:post, nil)
      |> assign(:is_following, false)
      |> assign(:bookmarked, false)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    post = Posts.get_post(id)

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

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:post, post)
     |> assign(:bookmarked?, bookmarked)
     |> assign(:is_following, is_following?)}
  end

  @impl true
  def handle_event("follow", _params, socket) do
    current_user = socket.assigns.current_user
    post_author = socket.assigns.post.user

    UserFollowers.follow_user(current_user.id, post_author.id)

    {:noreply, assign(socket, :is_following, true)}
  end

  @impl true
  def handle_event("unfollow", _params, socket) do
    current_user = socket.assigns.current_user
    post_author = socket.assigns.post.user
    UserFollowers.unfollow_user(current_user.id, post_author.id)

    {:noreply, assign(socket, :is_following, false)}
  end

  def handle_event("toggle_bookmark", _params, socket) do
    user_id = socket.assigns.current_user.id
    post_id = socket.assigns.post.id

    case Bookmarks.get_bookmark_by_user_and_post(user_id, post_id) do
      nil ->
        case Bookmarks.create_bookmark(%{user_id: user_id, post_id: post_id}) do
          {:ok, _bookmark} ->
            {:noreply, assign(socket, :bookmarked?, true)}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Could not bookmark the post")}
        end

      _bookmark ->
        case Bookmarks.delete_bookmark_by_user_and_post(user_id, post_id) do
          {1, _} ->
            {:noreply, assign(socket, :bookmarked?, false)}

          _ ->
            {:noreply, put_flash(socket, :error, "Could not remove bookmark")}
        end
    end
  end

  defp page_title(:show), do: "Show Post"
  defp page_title(:edit), do: "Edit Post"
end
