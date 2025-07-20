defmodule BloggingWeb.PostLive.Index do
alias Blogging.Accounts
  use BloggingWeb, :live_view

  alias Blogging.Contents.Posts.{Posts}

  @impl true
  def mount(_params, session, socket) do
    current_user = Accounts.get_user_by_session_token(session["user_token"])

    {:ok,
     socket
     |> assign(:posts, list_posts(current_user.id))

      |> assign(:current_user_id, current_user.id)
     |> assign(:page_title, "Posts")
     |> assign(:pagination, nil)}
  end

  @impl true
  def handle_params(params, url, socket) do
     current_path = URI.parse(url).path

    {:noreply,
     socket
     |> assign(:current_path, current_path)
     |>  apply_action(socket.assigns.live_action, params)}
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
   data =  Posts.list_posts_by_user(user_id,  page: 1, page_size: 10)
   IO.inspect(data, label: "Posts Data")
   data
  end
end
