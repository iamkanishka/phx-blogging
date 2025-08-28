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
            @reactions.user_reacted[type] &&  "underline font-semibold text-blue-600"
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
  @spec handle_event(<<_::40>>, map(), any()) :: {:noreply, any()}
  # def handle_event("react", %{"type" => type}, socket) do
  #   case socket.assigns.current_user do
  #     nil ->
  #       {:noreply, put_flash(socket, :error, "You must be logged in to react")}

  #     user ->
  #       attrs = %{
  #         type: type,
  #         reactable_type: socket.assigns.reactable_type,
  #         reactable_id: socket.assigns.reactable_id,
  #         user_id: user.id
  #       }

  #       # IO.inspect(attrs, label: "Reaction Attributes")

  #       case Reactions.toggle_reaction(attrs) do
  #         {:ok, _reaction} ->
  #           # Broadcast the reaction to all subscribers
  #           topic = "post:reactions:#{socket.assigns.reactable_id}"
  #           BloggingWeb.Endpoint.broadcast(topic, "new_reaction", %{})
  #           {:noreply, socket}

  #         {:error, _changeset} ->
  #           # IO.inspect(changeset, label: "Reaction Error")
  #           {:noreply, put_flash(socket, :error, "Could not add reaction")}
  #       end
  #   end
  # end

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
          topic =
            case socket.assigns.reactable_type do
              "post" ->
                "post:reactions:#{socket.assigns.reactable_id}"

              "comment" ->
                "post:comments:reactions:#{socket.assigns.post_id}"
            end

          event =
            case socket.assigns.reactable_type do
              "post" -> "new_reaction"
              "comment" -> "add_reaction"
            end

          BloggingWeb.Endpoint.broadcast(topic, event, %{
            id: attrs.reactable_id,
            type: attrs.type,
            user_id: user.id
          })

          {:noreply, socket}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Could not add reaction")}
      end
  end
end


end
