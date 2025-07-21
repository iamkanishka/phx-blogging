defmodule BloggingWeb.ComponentsLive.SidebarBookmarksTopics do
  use BloggingWeb, :live_component
  alias Blogging.Contents.Bookmarks.Bookmarks

  @impl true
  def render(assigns) do
    ~H"""
    <aside class="w-96 border-l px-6 py-6 hidden lg:block">
      <div class="space-y-8">
        <div>
          <h3 class="text-lg font-semibold mb-4">Your Recent Bookmark</h3>

          <ul class="space-y-4">
            <%= for bookmark <- @bookmarks do %>
              <li>
                <p class="font-medium text-gray-800">
                  {bookmark.post.title}
                </p>

                <p class="text-xs text-gray-400 mt-1">
                  ✨ {bookmark.inserted_at |> Timex.format!("%b %d", :strftime)}
                </p>
              </li>
            <% end %>
          </ul>
        </div>

        <div>
          <h3 class="text-lg font-semibold mb-4">Recommended topics</h3>

          <div class="flex flex-wrap gap-2">
            <%= for topic <- ["Software Engineering", "Flutter", "Typescript", "Product Management"] do %>
              <span class="bg-gray-100 text-sm text-gray-700 px-3 py-1 rounded-full hover:bg-gray-200 cursor-pointer">
                {topic}
              </span>
            <% end %>
          </div>
        </div>
      </div>
    </aside>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:bookmarks, [])
     |> assign_bookmark(assigns[:current_user_id])}
  end

  defp assign_bookmark(socket, user_id) do
    bookmarks = Bookmarks.list_recent_bookmarks(user_id)

    assign(socket, :bookmarks, bookmarks)
  end
end
