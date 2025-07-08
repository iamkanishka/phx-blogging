defmodule BloggingWeb.MyPostLive.Create do
  alias Blogging.Contents.Posts.Post
  alias Blogging.Contents.Posts.Posts

  use BloggingWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    changeset = Posts.change_post(%Post{})

    {:ok,
     socket
     |> assign(:page_title, "New Post")
     |> assign(:action, :new)
     |> assign(:post, %Post{})
     |> assign(:changeset, changeset)
     |> assign(:html_content, "")}
  end

  @impl true
  def handle_event("validate", %{"post" => post_params}, socket) do
    IO.inspect(post_params, label: "Validating post params")

    changeset =
      socket.assigns.post
      |> Posts.change_post(post_params)
      |> Map.put(:action, :validate)

    {:noreply, socket}
  end

  @impl true
  def handle_event("save", %{"post" => post_params}, socket) do
    save_post(socket, socket.assigns.action, post_params)
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

  defp save_post(socket, :edit, post_params) do
    case Posts.update_post(socket.assigns.post, post_params) do
      {:ok, _post} ->
        {:noreply,
         socket
         |> put_flash(:info, "Post updated successfully")
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_post(socket, :new, post_params) do
    case Posts.create_post(post_params) do
      {:ok, _post} ->
        {:noreply,
         socket
         |> put_flash(:info, "Post created successfully")
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
