defmodule BloggingWeb.FollowingFollwers.Index do
  alias Blogging.Accounts.EmailSubscriptions
  use BloggingWeb, :live_view

  alias Blogging.Accounts.UserFollowers
  alias Blogging.Accounts

  @impl true
  def mount(_params, session, socket) do
    current_user = Accounts.get_user_by_session_token(session["user_token"])

     if connected?(socket) do
       BloggingWeb.Endpoint.subscribe("notifications_badge:#{current_user.id}")
      end

    following_users =
      UserFollowers.list_followers_with_subscription(current_user.id, current_user.id)

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(following_users: following_users)
     |> assign(following_count: length(following_users))}
  end

  @impl true
  def handle_params(_unsigned_params, url, socket) do
    current_path = URI.parse(url).path

    {:noreply,
     socket
     |> assign(:current_path, current_path)}
  end

  @impl true
  def handle_event("follow", %{"user_id" => user_id, "index" => index_str}, socket) do
    current_user = socket.assigns.current_user
    UserFollowers.follow_user(current_user.id, user_id)

    index = String.to_integer(index_str)
    following_users = update_following(socket.assigns.following_users, index, true)

    {:noreply,
     socket
     |> assign(:following_users, following_users)
     |> assign(:following_count, socket.assigns.following_count + 1)}
  end

  def handle_event("unfollow", %{"user_id" => user_id, "index" => index_str}, socket) do
    current_user = socket.assigns.current_user
    UserFollowers.unfollow_user(current_user.id, user_id)

    index = String.to_integer(index_str)
    following_users = update_following(socket.assigns.following_users, index, false)

    {:noreply,
     socket
     |> assign(:following_users, following_users)
     |> assign(:following_count, socket.assigns.following_count - 1)}
  end

  def handle_event("subscribe", %{"user_id" => user_id, "index" => index_str}, socket) do
    current_user = socket.assigns.current_user

    EmailSubscriptions.subscribe_user(user_id, current_user.id)

    index = String.to_integer(index_str)
    following_users = update_subscribe(socket.assigns.following_users, index, true)

    {:noreply, assign(socket, :following_users, following_users)}
  end

  def handle_event("unsubscribe", %{"user_id" => user_id, "index" => index_str}, socket) do
    current_user = socket.assigns.current_user
    EmailSubscriptions.unsubscribe_user(user_id, current_user.id)

    index = String.to_integer(index_str)
    following_users = update_subscribe(socket.assigns.following_users, index, false)

    {:noreply, assign(socket, :following_users, following_users)}
  end

  defp update_following(following_list, index, new_value) do
    List.update_at(following_list, index, fn entry ->
      %{entry | is_following: new_value}
    end)
  end

  defp update_subscribe(following_list, index, new_value) do
    List.update_at(following_list, index, fn entry ->
      %{entry | is_subscribed: new_value}
    end)
  end
end
