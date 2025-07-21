defmodule BloggingWeb.ComponentsLive.SidebarProfile do
  use BloggingWeb, :live_component

alias Blogging.Accounts.UserFollowers


  def render(assigns) do
    ~H"""
    <aside class="w-96 border-l px-6 py-6 hidden lg:block">
      <div class="w-24 h-24 rounded-full bg-gray-300 text-white text-5xl font-semibold flex items-center justify-center uppercase">
        {String.first(@current_user.username) |> String.upcase()}
      </div>

      <h2 class="text-xl font-bold mt-4">{@current_user.username}</h2>


      <div class="flex space-x-3 mt-2">
        <p class="text-sm text-gray-500"><strong>{@followers_count} followers</strong></p>

        <.link patch={~p"/following"}>
          <p class="text-sm text-gray-500"><strong>{@following_count} following</strong></p>
        </.link>
      </div>

      <p class="mt-3 text-gray-700 text-sm">{@current_user.bio}</p>

      <.link patch={~p"/profile/settings"}>
        <p class="mt-4 inline-block text-green-600 text-xs hover:underline">Edit profile</p>
      </.link>
    </aside>
    """
  end

  def update(assigns, socket) do
    following_count = UserFollowers.count_following(assigns.current_user.id)
    followers_count = UserFollowers.count_followers(assigns.current_user.id)

    {:ok,
     socket
     |> assign(:following_count, following_count)
     |> assign(:followers_count, followers_count)
     |> assign(assigns)}
  end
end
