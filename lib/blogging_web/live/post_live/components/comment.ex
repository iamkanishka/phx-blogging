defmodule BloggingWeb.PostLive.Components.Comment do
  use BloggingWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="comment pb-0.5">
      <div class="max-w-4xl mx-auto p-2 space-y-0.5">
        <!-- Header -->
        <div class="flex items-center space-x-3">
          <div class="w-10 h-10 rounded-full bg-gray-300 text-white font-semibold flex items-center justify-center uppercase">
            {String.first(@comment.user.username) |> String.upcase()}
          </div>

          <div>
            <p class="font-semibold text-gray-800">{@comment.user.username}</p>

            <p class="text-xs text-gray-500">{Timex.from_now(@comment.inserted_at)}</p>
          </div>
        </div>

    <!-- Content OR Edit Form -->
        <%= if @edit_mode do %>
          <form phx-submit="save_edit" phx-target={@myself} class="mt-2 space-y-2">
            <textarea name="edited_content" rows="3" class="w-full border rounded-md p-2 text-sm">{@comment.content}</textarea>
            <div class="flex space-x-2">
              <button
                type="submit"
                class="bg-green-500 text-white px-3 py-1 rounded hover:bg-green-600 text-sm"
              >
                Save
              </button>

              <button
                type="button"
                phx-click="cancel_edit"
                phx-target={@myself}
                class="text-gray-500 text-sm"
              >
                Cancel
              </button>
            </div>
          </form>
        <% else %>
          <div class="text-gray-700 text-sm py-2">
            {@comment.content}
          </div>
        <% end %>

    <!-- Footer Actions -->
        <div class="flex items-center justify-start space-x-6 text-gray-500 text-sm">
          <%!-- <button class="flex items-center space-x-1 hover:text-blue-600">
            <span>👏</span>
          </button> --%>

    <!-- Load Replies -->
          <%!-- <div
            phx-click="load_replies"
            phx-target={@myself}
            phx-value-comment-id={@comment.id}
            class="flex items-center space-x-0.5 cursor-pointer"
          >
            <span>{@comment.reply_count} reply</span>
          </div> --%>
          <div
            phx-click={if @comment.reply_count > 0, do: "toggle_replies", else: nil}
            phx-target={@myself}
            phx-value-comment-id={@comment.id}
            class="flex items-center space-x-0.5 cursor-pointer"
          >
            <span>
              <%= cond do %>
                <% @comment.reply_count == 0 -> %>
                  no replies
                <% @comment.reply_count == 1 -> %>
                  {if @comment.hide_replies, do: "1 reply", else: "Hide reply"}
                <% @comment.reply_count > 1 -> %>
                  {if @comment.hide_replies,
                    do: "#{@comment.reply_count} replies",
                    else: "Hide replies"}
              <% end %>
            </span>
          </div>

    <!-- Reply Button -->
          <a
            href="#"
            phx-click="show_reply_form"
            phx-target={@myself}
            class="hover:text-blue-600 focus:outline-none"
          >
            Reply
          </a>

    <!-- Edit Button -->
          <button type="button" phx-click="edit_comment" phx-target={@myself}>
            <.icon name="hero-pencil" class="w-4 h-4" />
          </button>

    <!-- Delete Button -->
          <button
            type="button"
            phx-click="confirm_delete"
            phx-target={@myself}
            class="text-red-500 hover:text-red-700"
          >
            <.icon name="hero-trash" class="w-4 h-4" />
          </button>
        </div>
      </div>

    <!-- ✅ Reply Form -->
      <%= if @show_reply_form do %>
        <div class="my-2">
          <form phx-submit="add_reply" phx-target={@myself} class="ml-6 mt-2 space-y-1">
            <textarea
              name="reply_content"
              rows="2"
              class="w-full border rounded-md p-2 text-sm"
              placeholder="Write your reply..."
            ></textarea>
            <div class="flex space-x-2">
              <button
                type="submit"
                class="bg-blue-500 text-white px-3 py-1 rounded hover:bg-blue-600 text-sm"
              >
                Reply
              </button>

              <button
                type="button"
                phx-click="cancel_reply"
                phx-target={@myself}
                class="text-gray-500 text-sm"
              >
                Cancel
              </button>
            </div>
          </form>
        </div>
      <% end %>

    <!-- Replies Section -->
      <div class="replies ml-5">
        <%= unless @comment.hide_replies do %>
          <div class="border-l-2 border-gray-300 space-y-2 pl-1">
            <%= for reply <- @comment.replies do %>
              <.live_component module={__MODULE__} id={"reply-#{reply.id}"} comment={reply} />
            <% end %>
          </div>
        <% end %>

        <%= if @comment.replies_has_next do %>
          <a
            href="#"
            phx-click="load_replies"
            phx-target={@myself}
            phx-value-comment-id={@comment.id}
            class="text-blue-500 hover:text-blue-700 text-sm"
          >
            See more replies
          </a>
        <% end %>
      </div>

    <!-- ✅ Delete Confirmation -->
      <%= if @confirm_delete do %>
        <div class="ml-6 mt-2 bg-red-100 border border-red-400 p-2 rounded">
          <p class="text-sm text-red-700">Are you sure you want to delete this comment?</p>

          <div class="flex space-x-2 mt-1">
            <button
              phx-click="delete_comment"
              phx-target={@myself}
              class="bg-red-500 text-white px-3 py-1 rounded text-sm hover:bg-red-600"
            >
              Yes, Delete
            </button>

            <button phx-click="cancel_delete" phx-target={@myself} class="text-gray-500 text-sm">
              Cancel
            </button>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {
      :ok,
      socket
      |> assign(assigns)
      |> assign_new(:show_reply_form, fn -> false end)
      |> assign_new(:edit_mode, fn -> false end)
      |> assign_new(:confirm_delete, fn -> false end)
    }
  end

  ## ✅ Reply Events
  @impl true
  def handle_event("load_replies", %{"comment-id" => id}, socket) do
    send(self(), {:load_replies, %{"parent_id" => id}})
    {:noreply, socket}
  end

  def handle_event("save_edit", %{"edited_content" => content}, socket) do
    send(self(), {:edit_comment, %{comment_id: socket.assigns.comment.id, content: content}})
    {:noreply, assign(socket, :edit_mode, false)}
  end

  def handle_event("show_reply_form", _, socket),
    do: {:noreply, assign(socket, :show_reply_form, true)}

  def handle_event("cancel_reply", _, socket),
    do: {:noreply, assign(socket, :show_reply_form, false)}

  def handle_event("add_reply", %{"reply_content" => content}, socket) do
    send(self(), {:add_reply, %{parent_id: socket.assigns.comment.id, content: content}})
    {:noreply, assign(socket, :show_reply_form, false)}
  end

  ## ✅ Edit Events
  def handle_event("edit_comment", _, socket),
    do: {:noreply, assign(socket, :edit_mode, true)}

  def handle_event("cancel_edit", _, socket),
    do: {:noreply, assign(socket, :edit_mode, false)}

  ## ✅ Delete Events
  def handle_event("confirm_delete", _, socket),
    do: {:noreply, assign(socket, :confirm_delete, true)}

  def handle_event("cancel_delete", _, socket),
    do: {:noreply, assign(socket, :confirm_delete, false)}

  def handle_event("delete_comment", _, socket) do
    send(self(), {:delete_comment, %{comment_id: socket.assigns.comment.id}})
    {:noreply, assign(socket, :confirm_delete, false)}
  end

  def handle_event("toggle_replies", %{"comment-id" => id}, socket) do
    comment = socket.assigns.comment

    if comment.id == id do
      if comment.replies == [] do
        # Replies not loaded → trigger load, don't change hide_replies yet
        send(self(), {:load_replies, %{"parent_id" => id}})
        #  updated_comment = %{comment | hide_replies: false}
        # {:noreply, assign(socket, :comment, updated_comment)}
        {:noreply, socket}
      else
        # Replies already loaded → just toggle
        updated_comment = %{comment | hide_replies: !comment.hide_replies}
        {:noreply, assign(socket, :comment, updated_comment)}
      end
    else
      {:noreply, socket}
    end
  end
end
