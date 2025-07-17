defmodule Blogging.Contents.Bookmarks.Bookmarks do
  import Ecto.Query, warn: false
  alias Blogging.Repo

  alias Blogging.Contents.Bookmarks.Bookmark
  alias Blogging.Contents.Comments.Comment
  alias Blogging.Contents.Reactions.Reaction


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

  @reaction_types ~w(like love wow laugh sad angry)

  def list_user_bookmarks(user_id, page \\ 1, per_page \\ 10) do
    offset = (page - 1) * per_page

    # Subquery: comment count per post
    comment_counts_query =
      from c in Comment,
        group_by: c.post_id,
        select: %{post_id: c.post_id, comment_count: count(c.id)}

    # Subquery: reaction counts per post and type
    reaction_counts_query =
      from r in Reaction,
        where: r.reactable_type == "post",
        group_by: [r.reactable_id, r.type],
        select: %{
          post_id: r.reactable_id,
          type: r.type,
          count: count(r.id)
        }

    # Subquery: aggregate reactions per post
    reaction_agg_query =
      from r in subquery(reaction_counts_query),
        group_by: r.post_id,
        select: %{
          post_id: r.post_id,
          reactions: fragment("jsonb_object_agg(?, ?)", r.type, r.count)
        }

    # Main query: Bookmarked posts enriched with counts
    query =
      from b in Bookmark,
        where: b.user_id == ^user_id,
        join: p in assoc(b, :post),
        left_join: cc in subquery(comment_counts_query),
        on: cc.post_id == p.id,
        left_join: rc in subquery(reaction_agg_query),
        on: rc.post_id == p.id,
        order_by: [desc: b.inserted_at],
        limit: ^per_page,
        offset: ^offset,
        select: %{
          bookmark_id: b.id,
          inserted_at: b.inserted_at,
          post: %{
            id: p.id,
            title: p.title,
            sub_title: p.sub_title,
            comment_count: coalesce(cc.comment_count, 0),
            reactions: coalesce(rc.reactions, fragment("'{}'::jsonb"))
          }
        }

    Repo.all(query)
  end





  def count_user_bookmarks(user_id) do
    Bookmark
    |> where([b], b.user_id == ^user_id)
    |> select([b], count(b.id))
    |> Repo.one()
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
