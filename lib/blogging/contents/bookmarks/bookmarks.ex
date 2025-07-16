defmodule Blogging.Contents.Bookmarks.Bookmarks do
  import Ecto.Query, warn: false
  alias Blogging.Repo

  alias Blogging.Contents.Bookmarks.Bookmark

  # list recent  bookmark by ID
  def list_recent_bookmarks(user_id) do
    from(w in Blogging.Contents.Bookmarks.Bookmark,
      where: w.user_id == ^user_id,
      order_by: [desc: w.inserted_at],
      preload: [post: :user],
      limit: 5
    )
    |> Repo.all()
  end

  # Get bookmark by user and post
  def get_bookmark_by_user_and_post(user_id, post_id) do
    Repo.get_by(Bookmark, user_id: user_id, post_id: post_id)
  end

  # List all bookmarked posts by a specific user

  def paginate_user_bookmarks(user_id, page \\ 1, page_size \\ 10) do
    query =
      from(w in Bookmark,
        where: w.user_id == ^user_id
      )

    total_count = Repo.aggregate(query, :count, :id)
    total_pages = Integer.ceil_div(total_count, page_size)

    bookmarks =
      query
      |> order_by([w], desc: w.inserted_at)
      |> preload(:post)
      |> offset(^((page - 1) * page_size))
      |> limit(^page_size)
      |> Repo.all()

    %{
      entries: bookmarks,
      total_count: total_count,
      total_pages: total_pages,
      page: page,
      page_size: page_size
    }
  end

  # Create a bookmark entry

  def create_bookmark(attrs \\ %{}) do
    %Bookmark{}
    |> Bookmark.changeset(attrs)
    |> Repo.insert()
  end

  # Delete bookmark by user and post directly
  def delete_bookmark_by_user_and_post(user_id, post_id) do
    from(w in Bookmark, where: w.user_id == ^user_id and w.post_id == ^post_id)
    |> Repo.delete_all()
  end

  # Change bookmark changeset (optional)
  def change_bookmark(%Bookmark{} = bookmark, attrs \\ %{}) do
    Bookmark.changeset(bookmark, attrs)
  end
end
