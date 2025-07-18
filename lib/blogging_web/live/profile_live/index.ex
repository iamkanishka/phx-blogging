defmodule BloggingWeb.ProfileLive.Index do
  use BloggingWeb, :live_view

  alias Blogging.Accounts

  alias Blogging.Contents.Posts.{Posts}

  @impl true
  def mount(_params, session, socket) do
    current_user = Accounts.get_user_by_session_token(session["user_token"])

    {:ok,
     socket
     |> assign(:posts, list_posts(current_user.id))
     |> assign(:current_user, current_user)
     |> assign(:current_user_id, current_user.id)
     |> assign(:page_title, "Posts")
     |> assign(:pagination, nil)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Posts")
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    post = Posts.get_post(id)
    {:ok, _} = Posts.delete_post(post)

    {:noreply, assign(socket, :posts, list_posts(socket.assigns.current_user_id))}
  end

  defp list_posts(user_id) do
    Posts.list_posts_by_user(user_id, page: 1, page_size: 10)
  end
end
