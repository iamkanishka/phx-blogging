defmodule BloggingWeb.PostLive.Components.Reaction do
  alias Blogging.Notifications.Notifications
  use BloggingWeb, :live_component
  alias Blogging.Contents.Reactions.Reactions

  @reaction_types %{
    "like" => "👍",
    "love" => "❤️",
    "wow" => "😮",
    "laugh" => "😂",
    "sad" => "😢",
    "angry" => "😡"
  }

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex items-center space-x-2">
      <%= for {type, emoji} <- @reaction_types do %>
        <button
          phx-click="react"
          phx-target={@myself}
          phx-value-type={type}
          class={[
            "flex items-center space-x-0.5 p-1 rounded",
            @reactions.user_reacted[type] && "underline font-semibold text-blue-600"
          ]}
          title={type}
        >
          <span>{emoji}</span> <span class="text-sm">{@reactions.counts[type] || 0}</span>
        </button>
      <% end %>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:reaction_types, @reaction_types)}
  end

  @impl true
  def handle_event("react", %{"type" => type}, socket) do
    case socket.assigns.current_user do
      nil ->
        {:noreply, put_flash(socket, :error, "You must be logged in to react")}

      user ->
        attrs = %{
          type: type,
          reactable_type: socket.assigns.reactable_type,
          reactable_id: socket.assigns.reactable_id,
          user_id: user.id
        }

        case Reactions.toggle_reaction(attrs) do
          {:ok, _reaction} ->
            # Fetch updated reaction_data ONCE
            {topic, event} =
              case attrs.reactable_type do
                "post" ->
                  {"post:reactions:#{attrs.reactable_id}", "new_reaction"}

                "comment" ->
                  {"post:comments:reactions:#{socket.assigns.post_id}", "add_reaction"}
              end

            BloggingWeb.Endpoint.broadcast(topic, event, %{
              id: attrs.reactable_id,
              type: attrs.reactable_type
            })

            if socket.assigns.post_user.id != socket.assigns.current_user.id do
              Notifications.notify_post_reaction(
                socket.assigns.post_user.id,
                attrs.reactable_type,
                attrs.reactable_id,
                socket.assigns.current_user.id,
                @reaction_types[attrs.type],
                socket.assigns.current_user.username
              )
            end

            {:noreply, socket}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Could not add reaction")}
        end
    end
  end
end
