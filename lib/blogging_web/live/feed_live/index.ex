defmodule BloggingWeb.FeedLive.Index do
  use BloggingWeb, :live_view
  alias Blogging.Accounts
  alias Blogging.Contents.Feeds.Feeds

  @all_topics [
    "For you",
    "Following"
  ]

  @impl true
  def mount(_params, session, socket) do
    current_user = Accounts.get_user_by_session_token(session["user_token"])

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:page_title, "Feed Blogging")
     |> assign(:active_tab, "For you")
     |> assign(:posts, [])
     |> assign(:bookmarks, [])
     |> assign(:pagination, nil)
     |> assign(:has_new_notifications, false)
     |> assign_bookmark(current_user.id)
     |> assign(:all_topics, (current_user && @all_topics ++ current_user.intrests) || @all_topics)}
  end

  @impl true
  def handle_params(params, url, socket) do
    current_user = socket.assigns.current_user

    current_path = URI.parse(url).path

    page =
      case params do
        %{"feed" => "following"} ->
          Feeds.list_network_posts(current_user, params)

        %{"tag" => tag} ->
          Feeds.list_by_tag(String.capitalize(tag), current_user, params)

        _ ->
          Feeds.list_relevant_posts(current_user, %{
            "page" => Map.get(params, "page", "1"),
            "page_size" => Map.get(params, "page_size", "10")
          })
      end

    new_tab =
      cond do
        params["feed"] == "following" -> "Following"
        params["tag"] -> String.capitalize(params["tag"])
        true -> "For you"
      end

    {:noreply,
     assign(socket,
       active_tab: new_tab,
       posts: page.entries,
       current_path: current_path,
       pagination: page
     )}
  end

  @impl true
  def handle_event(
        "load-more",
        _params,
        %{assigns: %{pagination: pagination, current_user: user, active_tab: tab}} = socket
      ) do
    next_page = pagination.page_number + 1

    next_page_data =
      case tab do
        "Following" ->
          Feeds.list_network_posts(user, %{"page" => next_page})

        "For you" ->
          Feeds.list_relevant_posts(user, %{"page" => next_page})

        tag ->
          Feeds.list_by_tag(tag, user, %{"page" => next_page})
      end

    {:noreply,
     socket
     |> assign(:pagination, next_page_data)
     |> update(:posts, &(&1 ++ next_page_data.entries))}
  end

  def handle_event("scroll_left", _params, socket) do
    {:noreply, push_event(socket, "scroll_left", %{})}
  end

  def handle_event("scroll_right", _params, socket) do
    {:noreply, push_event(socket, "scroll_right", %{})}
  end

  defp assign_bookmark(socket, user_id) do
    bookmarks = Blogging.Contents.Bookmarks.Bookmarks.list_recent_bookmarks(user_id)

    assign(socket, :bookmarks, bookmarks)
  end

  @impl true

  def handle_info(
        %{event: "render_new_notification_badge", payload: %{notification: _notification}},
        socket
      ) do
    IO.inspect("Received new notification badge")
    {:noreply, assign(socket, :has_new_notifications, true)}
  end
end
