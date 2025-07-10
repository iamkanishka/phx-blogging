defmodule BloggingWeb.PostLive.CreateEdit do
  alias Blogging.Accounts
  alias Blogging.Contents.Posts.Post
  alias Blogging.Contents.Posts.Posts

  use BloggingWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    user = Accounts.get_user_by_session_token(session["user_token"])
    changeset = Posts.change_post(%Post{user_id: user.id})

    {:ok,
     socket
     |> assign(:page_title, "New Post")
     |> assign(:action, :new)
     |> assign(:user_id, user.id)
     |> assign(:post, %Post{user_id: user.id})
     |> assign(:changeset, changeset)
     |> assign(:html_content, "")}
  end

  @impl true
  def handle_event("quill-change", %{"html" => html, "text" => text}, socket) do
    IO.inspect(html, label: "Quill HTML content")
    # Update the changeset with the new HTML content
    IO.inspect(text, label: "Quill Editor")

    changeset =
      Ecto.Changeset.change(socket.assigns.changeset.data, %{html_content: html})
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, html_content: html)}
  end
end
