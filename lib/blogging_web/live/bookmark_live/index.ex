defmodule BloggingWeb.BookmarkLive.Index do
  use BloggingWeb, :live_view

  alias Blogging.Contents.Bookmarks.Bookmarks
  alias Blogging.Accounts

  @per_page 10

  @impl true
  @spec mount(any(), nil | maybe_improper_list() | map(), map()) :: {:ok, map()}
  def mount(_params, session, socket) do
    current_user = Accounts.get_user_by_session_token(session["user_token"])

    page = 1
    total_count = Bookmarks.count_user_bookmarks(current_user.id)

    total_pages =
      if total_count == 0 do
        1
      else
        Float.ceil(total_count / @per_page) |> trunc()
      end

    bookmarks = Bookmarks.list_user_bookmarks(current_user.id, page, @per_page)

    IO.inspect(bookmarks, label: "Bookmarks in mount")

    {:ok,
     socket
     |> assign(:user_id, current_user.id)
      |> assign(:current_user, current_user)

     |> assign(:bookmarks, bookmarks)
     |> assign(:loaded_page, page)
     |> assign(:total_pages, total_pages)}
  end

    @impl true
  def handle_params(_unsigned_params, url, socket) do
    current_path = URI.parse(url).path

    {:noreply,
     socket
     |> assign(:current_path, current_path)}
  end


  def handle_event("load-more", _params, socket) do
    page = socket.assigns.loaded_page + 1
    user_id = socket.assigns.user_id

    if page <= socket.assigns.total_pages do
      new_bookmarks = Bookmarks.list_user_bookmarks(user_id, page, @per_page)

      {:noreply,
       socket
       |> assign(:bookmarks, socket.assigns.bookmarks ++ new_bookmarks)
       |> assign(:loaded_page, page)}
    else
      {:noreply, socket}
    end
  end
end
