defmodule BloggingWeb.NotificationLive.Index do
  alias Blogging.Accounts
  use BloggingWeb, :live_view

  alias Blogging.Contents.Posts.{Posts}

  @impl true
  def mount(_params, session, socket) do
    current_user = Accounts.get_user_by_session_token(session["user_token"])

    activities = [
      %{
        name: "Felix da Maa",
        avatar: "https://example.com/felix.png",
        action: "clapped for 🥳😍",
        timestamp: "2 days ago"
      },
      %{
        name: "Narghiza Ergashova",
        avatar: "https://example.com/narghiza.png",
        action: "clapped for 🥰😃",
        timestamp: "3 days ago"
      },
      %{
        name: "Eilen Lexus",
        avatar: "https://example.com/eilen.png",
        action:
          "clapped for <span class=\"font-medium\">Next.js vs Phoenix: Choosing the Right Framework for Your Project</span>",
        timestamp: "4 days ago"
      },
      %{
        name: "Kaushalsinh",
        avatar: nil,
        action: "subscribed to get email notifications for your stories",
        timestamp: "Jul 12, 2025"
      },
      %{
        name: "Kaushalsinh",
        avatar: nil,
        action: "followed you",
        timestamp: "Jul 12, 2025"
      },
      %{
        name: "CodeQuest",
        avatar: "https://example.com/codequest.png",
        action: "followed you",
        timestamp: "Jul 10, 2025"
      },
      %{
        name: "yuuenchi + 1 other",
        avatar: nil,
        action: "followed you",
        timestamp: "Jul 5, 2025"
      },
      %{
        name: "S Kamalakannan",
        avatar: "https://example.com/s_karma.png",
        action: "subscribed to get email notifications for your stories",
        timestamp: "Jul 1, 2025"
      },
      %{
        name: "S Kamalakannan",
        avatar: "https://example.com/s_karma.png",
        action: "followed you",
        timestamp: "Jul 1, 2025"
      },
      %{
        name: "Kratagya Tripathi",
        avatar: "https://example.com/kratagya.png",
        action: "followed you",
        timestamp: "Jun 30, 2025"
      },
      %{
        name: "Kratagya Tripathi",
        avatar: "https://example.com/kratagya.png",
        action: "subscribed to get email notifications for your stories",
        timestamp: "Jun 30, 2025"
      },
      %{
        name: "Elias Haider",
        avatar: "https://example.com/elias.png",
        action: "followed you",
        timestamp: "Jun 10, 2025"
      }
    ]

    {:ok,
     socket
     |> assign(:posts, list_posts(current_user.id))
     |> assign(:current_user_id, current_user.id)
     |> assign(:current_user, current_user)


     |> assign(:activities, activities)
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
    data = Posts.list_posts_by_user(user_id, page: 1, page_size: 10)
    IO.inspect(data, label: "Posts Data")
    data
  end
end
