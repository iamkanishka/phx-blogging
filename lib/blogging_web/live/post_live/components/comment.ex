defmodule BloggingWeb.PostLive.Components.Comment do
  use BloggingWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="comment  p-1">
      <div class="flex items-center justify-between">
        <strong class="text-md font-semibold">{@comment.user.username}</strong>
        <span class="text-gray-500 text-sm">{Timex.from_now(@comment.inserted_at)}</span>
      </div>

      <p class="mt-1 text-gray-700">{@comment.content}</p>
      <%!--
      <div class="mt-2 text-gray-500 text-sm">
        Depth: {@comment.depth},
         Path: {@comment.path}
      </div>
      --%>

      <%!-- <%= if length(@comment.replies) > 0 or @comment.total_replies > 0 do %> --%>
        <div class="replies mt-2 pl-2 border-l-2 border-gray-300 space-y-2">
          <%= for reply <- @comment.replies do %>
            <.live_component module={__MODULE__} id={"reply-#{reply.id}"} comment={reply} />
          <% end %>

          <%!-- <%= if length(@comment.replies) < @comment.total_replies do %> --%>
            <a
              href="#"
              phx-click="load-more-replies"
              phx-target={@myself}
              phx-value-comment-id={@comment.id}
              class="text-blue-500 hover:text-blue-700 text-sm"
            >
              See more replies
            </a>
          <%!-- <% end %> --%>
        </div>
      <%!-- <% end %> --%>
    </div>
    """
  end

  @impl true

  def update(assigns, socket) do
    IO.inspect(assigns.comment)
    {:ok,
     socket
     |> assign(assigns)
    #  |> assign(:comment, assigns.comment)
    #  |> assign(:replies, assigns.comment.replies || [])
    #  |> assign(:total_replies, assigns.comment.total_replies || 0)
    }
  end

  @impl true
  def handle_event("load-more-replies", %{"comment-id" => comment_id}, socket) do
    send(self(), {:load_more_replies, String.to_integer(comment_id)})
    {:noreply, socket}
  end
end
