defmodule BloggingWeb.ComponentsLive.Layout do
  use BloggingWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <header class="sticky top-0 z-50 bg-white px-4 sm:px-6 lg:px-8">
        <div class="flex items-center justify-between border-b border-zinc-100 py-3 text-sm">
          <div class="flex items-center gap-4 font-semibold leading-6 text-zinc-900">
            <.link href={~p"/"} class={nav_link_classes(@current_path, "/")}>
              Feed
            </.link>

            <.link href={~p"/posts"} class={nav_link_classes(@current_path, "/posts")}>
              Posts
            </.link>

            <.link
              phx-click="clear_notifications"
              phx-target={@myself}
              class={nav_link_classes(@current_path, "/notifications")}
            >
              <span class="relative">
                Notifications
                <%= if @has_new_notifications do %>
                  <span class="absolute -top-1 -right-2 block h-2 w-2 rounded-full bg-red-500"></span>
                <% end %>
              </span>
            </.link>

            <.link href={~p"/bookmarks"} class={nav_link_classes(@current_path, "/bookmarks")}>
              Bookmarks
            </.link>

            <.link href={~p"/profile"} class={nav_link_classes(@current_path, "/profile")}>
              Profile
            </.link>
          </div>

          <div class="flex items-center gap-4">
            <.link href={~p"/profile"}>
              {@user_name}
            </.link>

            <.link href={~p"/profile/settings"}>
              <.icon name="hero-cog-6-tooth" class="h-6 w-6 text-zinc-900 hover:text-zinc-700" />
            </.link>

            <.link href={~p"/users/logout"} method="delete" class="text-zinc-900 hover:text-zinc-700">
              Logout
            </.link>
          </div>
        </div>
      </header>

      <main class="px-4 sm:px-6 lg:px-8">
        <div class="mx-auto">
          <.flash_group flash={@flash} /> {render_slot(@inner_block)}
        </div>
      </main>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
      socket
      |> assign(assigns)
      |> assign(:has_new_notifications, false)


  }
  end

  defp nav_link_classes(current_path, path) do
    is_active =
      cond do
        path == "/" -> current_path == "/"
        true -> String.starts_with?(current_path, path)
      end

    [
      "text-lg leading-6 font-semibold",
      if is_active do
        "text-zinc-900 underline underline-offset-4 decoration-2"
      else
        "text-zinc-900 hover:text-zinc-700"
      end
    ]
  end

  @impl true
  def handle_info({:new_notification, _notification}, socket) do
    {:noreply, assign(socket, :has_new_notifications, true)}
  end

  @impl true
  def handle_event("clear_notifications", _params, socket) do
    {:noreply,
     socket
     |> assign(:has_new_notifications, false)
     |> push_navigate(to: ~p"/notifications")}
  end
end
