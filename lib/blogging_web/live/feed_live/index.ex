defmodule BloggingWeb.FeedLive.Index do
  use BloggingWeb, :live_view
  import BloggingWeb.Helpers, only: [truncate: 2]
  alias Blogging.Accounts
  alias Blogging.Contents.Feeds.Feeds

  @impl true
  def mount(_params, session, socket) do
    current_user = Accounts.get_user_by_session_token(session["user_token"])

    {:ok,
     socket
     |> assign_new(:current_user, fn -> current_user end)
     |> assign(:page_title, "Feed Blogging")
     |> assign(:active_tab, "For you")
     |> assign(:posts, [])
     |> assign(:pagination, nil)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    current_user = socket.assigns.current_user

    page =
      case params do
        %{"feed" => "following"} ->
          Feeds.list_network_posts(current_user, params)

        %{"tag" => tag} ->
          Feeds.list_by_tag(String.capitalize(tag), current_user, params)

        _ ->
          Feeds.list_relevant_posts(current_user, %{
            "page" => Map.get(params, "page", "1"),
            "page_size" => Map.get(params, "page_size", "10")
          })
      end

    new_tab =
      cond do
        params["feed"] == "following" -> "Following"
        params["tag"] -> String.capitalize(params["tag"])
        true -> "For you"
      end

    {:noreply,
     assign(socket,
       active_tab: new_tab,
       posts: page.entries,
       pagination: page
     )}
  end

  @impl true
  def handle_event(
        "load-more",
        _params,
        %{assigns: %{pagination: pagination, current_user: user, active_tab: tab}} = socket
      ) do
    next_page = pagination.page_number + 1

    next_page_data =
      case tab do
        "Following" ->
          Feeds.list_network_posts(user, %{"page" => next_page})

        "For you" ->
          Feeds.list_relevant_posts(user, %{"page" => next_page})

        tag ->
          Feeds.list_by_tag(tag, user, %{"page" => next_page})
      end

    {:noreply,
     socket
     |> assign(:pagination, next_page_data)
     |> update(:posts, &(&1 ++ next_page_data.entries))}
  end

  #   @impl true
  # def handle_event("load-more", _params, socket) do
  #   %{pagination: pagination, current_user: user, active_tab: tab} = socket.assigns
  #   next_page = pagination.page_number + 1

  #   next_page_data =
  #     case tab do
  #       "Following" -> Feeds.list_network_posts(user, %{"page" => next_page})
  #       "For you" -> Feeds.list_relevant_posts(user, %{"page" => next_page})
  #       tag -> Feeds.list_by_tag(tag, user, %{"page" => next_page})
  #     end

  #   {:noreply,
  #    socket
  #    |> assign(:pagination, next_page_data)
  #    |> update(:posts, &(&1 ++ next_page_data.entries))}
  # end
end
