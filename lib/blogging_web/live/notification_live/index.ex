defmodule BloggingWeb.NotificationLive.Index do
  use BloggingWeb, :live_view

  alias Blogging.Notifications.Notifications
  alias Blogging.Accounts

  @impl true
  def mount(_params, session, socket) do
    current_user = Accounts.get_user_by_session_token(session["user_token"])

    if connected?(socket) do
      BloggingWeb.Endpoint.subscribe("notifications:#{current_user.id}")
    end

    notifications =
      current_user
      |> Notifications.list_notifications()

    IO.inspect(notifications, label: "Notifications")

    {:ok,
     socket
     |> assign(:current_user_id, current_user.id)
     |> assign(:current_user, current_user)
     |> assign(:notifications, notifications)
     |> assign(:page_title, "Posts")
     |> assign(:pagination, nil)}
  end

  @impl true
  def handle_params(params, url, socket) do
    current_path = URI.parse(url).path

    {:noreply,
     socket
     |> assign(:current_path, current_path)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Posts")
  end

  @impl true

  def handle_info(
        %{
          event: "new_notification",
          payload: %{notification: notification}
        },
        socket
      ) do
    {:noreply,
     socket
     |> assign(:notifications, [notification | socket.assigns.notifications])}
  end
end
