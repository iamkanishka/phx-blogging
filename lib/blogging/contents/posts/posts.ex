defmodule Blogging.Contents.Posts.Posts do
  import Ecto.Query, warn: false
  alias Blogging.Repo
  alias Blogging.Contents.Posts.Post

  # Post functions
  @spec list_posts() :: nil | [%{optional(atom()) => any()}] | %{optional(atom()) => any()}
  def list_posts, do: Repo.all(Post) |> Repo.preload([:user, :comments, :reactions])

  def get_post(id),
    do: Repo.get(Post, id) |> Repo.preload([:user, comments: :user, reactions: :user])

  def create_post(attrs \\ %{}) do
    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a post.

  ## Examples

      iex> delete_post(post)
      {:ok, %Post{}}

      iex> delete_post(post)
      {:error, %Ecto.Changeset{}}

  """
  def delete_post(%Post{} = post) do
    Repo.delete(post)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking post changes.

  ## Examples

      iex> change_post(post)
      %Ecto.Changeset{data: %Post{}}

  """
  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end

  @doc """
  Updates a post.

  ## Examples

      iex> update_post(post, %{field: new_value})
      {:ok, %Post{}}

      iex> update_post(post, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_post(%Post{} = post, attrs) do
    post
    |> Post.changeset(attrs)
    |> Repo.update()
  end

  @reaction_types ["like", "love", "wow", "laugh", "sad", "angry"]
  @doc """
  Lists all posts created by a specific user with comment count and detailed reaction counts per type.
  Supports optional pagination via `:page` and `:page_size` in `opts`.
  """
  def list_posts_by_user(user_id, opts \\ []) do
   page = Keyword.get(opts, :page, 1)
    page_size = Keyword.get(opts, :page_size, 10)
    offset = (page - 1) * page_size

    # Subquery for comment counts
    comments_count_query =
      from c in Blogging.Contents.Comments.Comment,
        select: %{post_id: c.post_id, count: count(c.id)},
        group_by: c.post_id

    # Subqueries for each reaction type
    reaction_queries =
      for type <- @reaction_types, into: %{} do
        {type,
         from(r in Blogging.Contents.Reactions.Reaction,
           where: r.reactable_type == "post" and r.type == ^type,
           select: %{post_id: r.reactable_id, count: count(r.id)},
           group_by: r.reactable_id
         )}
      end

    # Base query with joins
    base_query =
      fn published_only ->
        from p in Post,
          where: p.user_id == ^user_id,
          where: ^published_only == false or p.is_published == true,
          preload: [:user],
          order_by: [desc: p.inserted_at],
          left_join: cc in subquery(comments_count_query),
          on: cc.post_id == p.id,
          left_join: like_r in subquery(reaction_queries["like"]),
          on: like_r.post_id == p.id,
          left_join: love_r in subquery(reaction_queries["love"]),
          on: love_r.post_id == p.id,
          left_join: wow_r in subquery(reaction_queries["wow"]),
          on: wow_r.post_id == p.id,
          left_join: laugh_r in subquery(reaction_queries["laugh"]),
          on: laugh_r.post_id == p.id,
          left_join: sad_r in subquery(reaction_queries["sad"]),
          on: sad_r.post_id == p.id,
          left_join: angry_r in subquery(reaction_queries["angry"]),
          on: angry_r.post_id == p.id
      end

    # Apply select and pagination
    select_query =
      fn published_only ->
        from [p, cc, like_r, love_r, wow_r, laugh_r, sad_r, angry_r] in base_query.(
               published_only
             ),
             select: %{
               post: p,
               comments_count: coalesce(cc.count, 0),
               reactions: %{
                 "like" => coalesce(like_r.count, 0),
                 "love" => coalesce(love_r.count, 0),
                 "wow" => coalesce(wow_r.count, 0),
                 "laugh" => coalesce(laugh_r.count, 0),
                 "sad" => coalesce(sad_r.count, 0),
                 "angry" => coalesce(angry_r.count, 0)
               }
             },
             limit: ^page_size,
             offset: ^offset
      end

    final_query = select_query.(published_only?(opts))

    Repo.all(final_query)
  end

  defp published_only?(opts), do: Keyword.get(opts, :published_only, false)
end
