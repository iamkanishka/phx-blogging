defmodule BloggingWeb.FeedLive.Index do
  alias Blogging.Accounts
  alias Blogging.Contents.Feeds.Feeds
  use BloggingWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    current_user = Accounts.get_user_by_session_token(session["user_token"])

    {:ok,
     socket
     |> assign(:page_title, "Feed Blogging")
     |> assign(:active_tab, "For you")

     |> assign(:current_user, current_user)}
  end


  @impl true
def handle_params(params, _url, socket) do
  current_user = socket.assigns.current_user

  cond do
    params["feed"] == "following" ->
      page = Feeds.list_network_posts(current_user, params)
      {:noreply,
       assign(socket,
         active_tab: "Following",
         posts: page.entries,
         pagination: page
       )}

    params["tag"] ->
      tag = String.capitalize(params["tag"])
      page = Feeds.list_by_tag(tag, current_user, params)
      {:noreply,
       assign(socket,
         active_tab: tag,
         posts: page.entries,
         pagination: page
       )}

    true ->
      page =
        Feeds.list_relevant_posts(current_user, %{
          "page" => Map.get(params, "page", "1"),
          "page_size" => Map.get(params, "page_size", "10")
        })

      {:noreply,
       assign(socket,
         active_tab: "For you",
         posts: page.entries,
         pagination: page
       )}
  end
end



  # @impl true
  # def handle_params(params, _url, socket) do
  #   #     page = Map.get(params, "page", "1") |> String.to_integer()
  #   # page_size = Map.get(params, "page_size", "10") |> String.to_integer()
  #   #  %{"page" => "1", "page_size" => "10"}

  #   page =
  #     Feeds.list_relevant_posts(socket.assigns.current_user, %{
  #       "page" => "1",
  #       "page_size" => "10"
  #     })

  #   page = Feeds.list_network_posts(socket.assigns.current_user, params)

  #   {:noreply,
  #    socket
  #    |> assign(posts: page.entries)
  #    |> assign(pagination: page)}

  #   IO.inspect(page.entries)

  #   {:noreply,
  #    socket
  #    |> assign(posts: page.entries)
  #    |> assign(:pagination, page)}
  # end


#   @impl true
# def handle_params(params, _url, socket) do
#   current_user = socket.assigns.current_user
#   feed = Map.get(params, "feed", "following")

#   {page, active_tab} =
#     case feed do
#       "following" ->
#         {
#           Feeds.list_network_posts(current_user, params),
#           "Following"
#         }

#       _ ->
#         {
#           Feeds.list_relevant_posts(current_user, %{
#             "page" => Map.get(params, "page", "1"),
#             "page_size" => Map.get(params, "page_size", "10")
#           }),
#           "For you"
#         }
#     end

#   {:noreply,
#    socket
#    |> assign(:posts, page.entries)
#    |> assign(:pagination, page)
#    |> assign(:active_tab, active_tab)}
# end


end
