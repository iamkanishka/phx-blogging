defmodule BloggingWeb.ComponentsLive.PostCard do
  use BloggingWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.link patch={~p"/posts/#{@post.post.id}"}>
        <div class="flex border-b pb-6 px-5">
          <div class="flex-1">
            <p class="text-sm text-gray-500 mb-1">by {@post.post.user.username}</p>

            <h2 class="text-xl font-bold text-black">{@post.post.title}</h2>

            <p class="text-gray-700 mt-1">{@post.post.sub_title}</p>

            <div class="flex justify-between items-center text-sm text-gray-500 mt-2 space-x-4">

             <!-- Reactions -->

              <div class="flex items-center space-x-3 ">
                <!-- Post date -->
                <span>{@post.post.inserted_at |> Timex.format!("%b %d", :strftime)}</span>
                <div class="flex items-center space-x-2" title="Like">
                  <span>👍</span> <span>{@post.reactions["like"]}</span>
                </div>

                <div class="flex items-center space-x-2" title="Love">
                  <span>❤️</span> <span>{@post.reactions["love"]}</span>
                </div>

                <div class="flex items-center space-x-2" title="Wow">
                  <span>😮</span> <span>{@post.reactions["wow"]}</span>
                </div>

                <div class="flex items-center space-x-2" title="Laugh">
                  <span>😂</span> <span>{@post.reactions["laugh"]}</span>
                </div>

                <div class="flex items-center space-x-2" title="Sad">
                  <span>😢</span> <span>{@post.reactions["sad"]}</span>
                </div>

                <div class="flex items-center space-x-2" title="Angry">
                  <span>😡</span> <span>{@post.reactions["angry"]}</span>
                </div>
              </div>

                <!-- Comments and Bookmark -->
              <div class="flex items-center space-x-3 ml-4">
                <div class="flex items-center space-x-0.5" title="Comments">
                  <span><.icon name="hero-chat-bubble-bottom-center-text" /></span> <span> {@post.comments_count}</span>
                </div>

                <div class="flex items-center space-x-0.5" title="Bookmark">
                  <span><.icon name="hero-eye" /></span> <span> {@post.post.view_count} </span>
                </div>

                <div
                  class="flex items-center space-x-2 cursor-pointer hover:text-yellow-500"
                  phx-click="toggle_bookmark"
                  title="Bookmark"
                >
                  <span>
                    <.icon name= "hero-bookmark-solid"  />

                  <!--
                    <.icon name={if @bookmarked?, do: "hero-bookmark-solid", else: "hero-bookmark"} />
                    -->
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </.link>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end
end
