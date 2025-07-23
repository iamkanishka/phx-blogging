defmodule BloggingWeb.PostLive.Components.Reaction do
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
  @spec update(maybe_improper_list() | map(), any()) :: {:ok, any()}
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
          reactable_type: "post",
          reactable_id: socket.assigns.post_id,
          user_id: user.id
        }

        # IO.inspect(attrs, label: "Reaction Attributes")

        case Reactions.toggle_reaction(attrs) do
          {:ok, _reaction} ->
            # Broadcast the reaction to all subscribers
            topic = "post:reactions:#{socket.assigns.post_id}"
            BloggingWeb.Endpoint.broadcast(topic, "new_reaction", %{})
            {:noreply, socket}

          {:error, changeset} ->
            # IO.inspect(changeset, label: "Reaction Error")
            {:noreply, put_flash(socket, :error, "Could not add reaction")}
        end
    end
  end
end
