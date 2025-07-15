defmodule Blogging.Contents.Wishlists.Wishlists do
  import Ecto.Query, warn: false
  alias Blogging.Repo

  alias Blogging.Contents.Wishlists.Wishlist

  # list recent  wishlist by ID
  def list_recent_wishlists(user_id) do
    from(w in Blogging.Contents.Wishlists.Wishlist,
      where: w.user_id == ^user_id,
      order_by: [desc: w.inserted_at],
      preload: [post: :user],
      limit: 5
    )
    |> Repo.all()
  end

  # List all wishlisted posts by a specific user

  def paginate_user_wishlists(user_id, page \\ 1, page_size \\ 10) do
    query =
      from(w in Wishlist,
        where: w.user_id == ^user_id
      )

    total_count = Repo.aggregate(query, :count, :id)
    total_pages = Integer.ceil_div(total_count, page_size)

    wishlists =
      query
      |> order_by([w], desc: w.inserted_at)
      |> preload(:post)
      |> offset(^((page - 1) * page_size))
      |> limit(^page_size)
      |> Repo.all()

    %{
      entries: wishlists,
      total_count: total_count,
      total_pages: total_pages,
      page: page,
      page_size: page_size
    }
  end

  # Create a wishlist entry
  @spec create_wishlist(
          :invalid
          | %{optional(:__struct__) => none(), optional(atom() | binary()) => any()}
        ) :: any()
  def create_wishlist(attrs \\ %{}) do
    %Wishlist{}
    |> Wishlist.changeset(attrs)
    |> Repo.insert()
  end

  # Delete wishlist by user and post directly
  def delete_wishlist_by_user_and_post(user_id, post_id) do
    from(w in Wishlist, where: w.user_id == ^user_id and w.post_id == ^post_id)
    |> Repo.delete_all()
  end

  # Change wishlist changeset (optional)
  def change_wishlist(%Wishlist{} = wishlist, attrs \\ %{}) do
    Wishlist.changeset(wishlist, attrs)
  end
end
