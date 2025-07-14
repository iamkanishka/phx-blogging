defmodule BloggingWeb.PostLive.FormComponent do
  use BloggingWeb, :live_component

  alias Blogging.Contents.Posts.Posts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto py-10">
      <.simple_form
        for={@form}
        id="post-form"
        phx-submit="save"
        phx-change="validate"
        class="space-y-6"
        phx-target={@myself}
      >
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:sub_title]} type="text" label="Sub title" />
        <.input field={@form[:tags]} type="text" label="Tags (comma separated)" />

        <div>
          <label class="block text-sm font-medium mb-1">Content</label>
          <div id="create_post" phx-update="ignore">
            <div
              id="quill-editor"
              phx-hook="quillhook"
              data-content={@html_content}
              class="bg-white h-64 p-2 border rounded overflow-y-auto"
            >
            </div>
          </div>
        </div>

        <!-- Hidden field to persist quill content on submit -->
        <input type="hidden" name="post[html_content]" id="quill_html_content" value={@html_content} />

        <:actions>
          <.button type="submit">
            <%= if @action == :edit, do: "Update Post", else: "Create Post" %>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{post: post} = assigns, socket) do
    changeset = Posts.change_post(post)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"post" => post_params}, socket) do
    post_params = normalize_tags(post_params)

    changeset =
      socket.assigns.post
      |> Posts.change_post(post_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("quill-change", %{"html" => html, "text" => _text}, socket) do
    # Keep html_content updated in socket state for rendering and saving
    {:noreply, assign(socket, html_content: html)}
  end

  @impl true
  def handle_event("save", %{"post" => post_params}, socket) do
    case socket.assigns.action do
      :edit -> save_post(socket, :edit, post_params)
      :new -> save_post(socket, :new, post_params)
    end
  end

  defp save_post(socket, :edit, post_params) do
    post_params = normalize_tags(post_params)

    case Posts.update_post(socket.assigns.post, post_params) do
      {:ok, post} ->
        notify_parent({:saved, post})

        {:noreply,
         socket
         |> put_flash(:info, "Post updated successfully")
         |> push_navigate(to: "/posts")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_post(socket, :new, post_params) do
    post_params = normalize_tags(post_params)
    post_params = append_user_id(post_params, socket.assigns.user_id)

    case Posts.create_post(post_params) do
      {:ok, post} ->
        notify_parent({:saved, post})

        {:noreply,
         socket
         |> put_flash(:info, "Post created successfully")
         |> push_navigate(to: "/posts")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    socket
    |> assign(:form, to_form(changeset))
    |> assign(:changeset, changeset)
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp normalize_tags(%{"tags" => tags_string} = params) when is_binary(tags_string) do
    tags =
      tags_string
      |> String.split(",", trim: true)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    Map.put(params, "tags", tags)
  end

  defp append_user_id(params, user_id), do: Map.put(params, "user_id", user_id)
  defp normalize_tags(params), do: params
end
