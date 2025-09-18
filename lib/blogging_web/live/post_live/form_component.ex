defmodule BloggingWeb.PostLive.FormComponent do
  use BloggingWeb, :live_component

  alias Blogging.Contents.Posts.Posts

  @all_topics [
    "Software Engineering",
    "Angular",
    "Nestjs",
    "Elixir",
    "Phoenix",
    "Go",
    "Solidity",
    "Astronomy",
    "Blockchain",
    "Finance",
    "Healtcare"
  ]

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

        <div>
          <h3 class="text-lg font-semibold mb-4">Tags</h3>
          <div class="flex flex-wrap gap-2">
            <%= for topic <- @all_topics do %>
              <% selected = topic in @selected_topics %>
              <span
                phx-click="toggle-topic"
                phx-target={@myself}
                phx-value-topic={topic}
                class={[
                  "text-sm px-3 py-1 rounded-full cursor-pointer",
                  selected && "bg-blue-500 text-white",
                  !selected && "bg-gray-100 text-gray-700 hover:bg-gray-200"
                ]}
              >
                {topic}
              </span>
            <% end %>
          </div>
        </div>

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
            {if @action == :edit, do: "Update Post", else: "Create Post"}
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{post: post} = assigns, socket) do
    changeset = Posts.change_post(post)
   selected_topics =
      case assigns.action do
        :edit -> post.tags
        :new -> []
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       all_topics: @all_topics,
       selected_topics: selected_topics
     )
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"post" => post_params}, socket) do
    post_params = append_tags(post_params, socket)

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
    post_params = append_tags(post_params, socket)

    case socket.assigns.action do
      :edit -> save_post(socket, :edit, post_params)
      :new -> save_post(socket, :new, post_params)
    end
  end

  def handle_event("toggle-topic", %{"topic" => topic}, socket) do
    selected =
      if topic in socket.assigns.selected_topics do
        List.delete(socket.assigns.selected_topics, topic)
      else
        [topic | socket.assigns.selected_topics]
      end

    {:noreply, assign(socket, selected_topics: selected)}
  end

  defp save_post(socket, :edit, post_params) do
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

  defp append_user_id(params, user_id), do: Map.put(params, "user_id", user_id)
  defp append_tags(params, socket), do: Map.put(params, "tags", socket.assigns.selected_topics)
end
