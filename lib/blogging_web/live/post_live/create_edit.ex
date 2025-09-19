defmodule BloggingWeb.PostLive.CreateEdit do
  use BloggingWeb, :live_view

  alias Blogging.Accounts
  alias Blogging.Contents.Posts.Post
  alias Blogging.Contents.Posts.Posts

  @impl true
  def mount(_params, session, socket) do
    current_user = Accounts.get_user_by_session_token(session["user_token"])

     if connected?(socket) do

      BloggingWeb.Endpoint.subscribe("notifications_badge:#{current_user.id}")

    end

    {:ok, assign(socket, user: current_user)}
  end

  @impl true
  def handle_params(%{"id" => id}, url, socket) do
    post = Posts.get_post(id)

    current_path = URI.parse(url).path



    {:noreply,
     socket
     |> assign(:page_title, "Edit Post")
     |> assign(:post, post)
     |> assign(:current_path, current_path)
     |> assign(:action, :edit)
     |> assign(:user_id, post.user_id)
     |> assign(:html_content, post.html_content || "")}
  end

  def handle_params(_params, url, socket) do
    post = %Post{user_id: socket.assigns.user.id}

    current_path = URI.parse(url).path

    {:noreply,
     socket
     |> assign(:page_title, "New Post")
     |> assign(:post, post)
     |> assign(:current_path, current_path)
      |> assign(:has_new_notifications, false)

     |> assign(:action, :new)
     |> assign(:user_id, post.user_id)
     |> assign(:html_content, "")}
  end

  @impl true
  def handle_info({BloggingWeb.PostLive.FormComponent, {:saved, _post}}, socket) do
    {:noreply, push_navigate(socket, to: "/posts")}
  end

  def handle_info(%{event: "render_new_notification_badge", payload: %{notification: _notification}}, socket) do
  IO.inspect("Received new notification badge")
  {:noreply, assign(socket, :has_new_notifications, true)}
end

  @impl true
  def handle_event("quill-change", %{"html" => html, "text" => text}, socket) do
     # Update the changeset with the new HTML content

    _changeset =
      Ecto.Changeset.change(socket.assigns.changeset.data, %{html_content: html})
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, html_content: html)}
  end



end
