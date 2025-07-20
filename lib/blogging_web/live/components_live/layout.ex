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

            <.link href={~p"/notifications"} class={nav_link_classes(@current_path, "/notifications")}>
              Notifications
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

            <.link href={~p"/users/log_out"} class="text-zinc-900 hover:text-zinc-700">
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
    {:ok, assign(socket, assigns)}
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
end
