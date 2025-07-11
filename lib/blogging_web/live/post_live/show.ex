defmodule BloggingWeb.PostLive.Show do
  use BloggingWeb, :live_view

  alias Blogging.Contents.Posts.Posts
  alias Blogging.Accounts.UserFollowers

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    post = Posts.get_post(id)
    current_user = post.user

    is_following? =
      if current_user do
        UserFollowers.following?(current_user, post.user)
      else
        false
      end

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:post, post)
     |> assign(:current_user, current_user)
     |> assign(:is_following, is_following?)}
  end

  @impl true
  def handle_event("follow", _params, socket) do
    current_user = socket.assigns.current_user
    post_author = socket.assigns.post.user

    UserFollowers.follow_user(current_user, post_author)

    {:noreply, assign(socket, :is_following, true)}
  end

  @impl true
  def handle_event("unfollow", _params, socket) do
    current_user = socket.assigns.current_user
    post_author = socket.assigns.post.user

    UserFollowers.unfollow_user(current_user, post_author)

    {:noreply, assign(socket, :is_following, false)}
  end

  defp page_title(:show), do: "Show Post"
  defp page_title(:edit), do: "Edit Post"
end
