defmodule Blogging.Contents.Posts.Posts do
  import Ecto.Query, warn: false
  alias Blogging.Repo
  alias Blogging.Contents.Posts.Post
  alias Blogging.Contents.Comments.Comment
  alias Blogging.Contents.Reactions.Reaction

  # Post functions
  def list_posts, do: Repo.all(Post) |> Repo.preload([:user, :comments, :reactions])

  def get_post(id),
    do: Repo.get(Post, id) |> Repo.preload([:user, comments: :user, reactions: :user])

  def create_post(attrs \\ %{}) do
    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
  end

  # Comment functions
  def create_comment(attrs \\ %{}) do
    %Comment{}
    |> Comment.changeset(attrs)
    |> Repo.insert()
  end

  # Reaction functions
  def add_reaction(attrs \\ %{}) do
    %Reaction{}
    |> Reaction.changeset(attrs)
    |> Repo.insert()
  end

  def remove_reaction(user_id, post_id) do
    Repo.get_by(Reaction, user_id: user_id, post_id: post_id)
    |> Repo.delete()
  end

  def toggle_reaction(user_id, post_id, type) do
    case Repo.get_by(Reaction, user_id: user_id, post_id: post_id) do
      nil -> add_reaction(%{user_id: user_id, post_id: post_id, type: type})
      _reaction -> remove_reaction(user_id, post_id)
    end
  end

  @doc """
  Returns a list of posts with pagination.

  ## Examples

      iex> list_paginated_posts(page: 1, per_page: 10)
      %Scrivener.Page{entries: [%Post{}, ...], ...}

  """

  # def list_paginated_posts(params \\ []) do
  #   Post
  #   |> order_by(desc: :published_at)
  #   |> Repo.paginate(params)
  # end

  @doc """
  Gets a single post by slug or ID.

  Returns nil if not found.

  ## Examples

      iex> get_post_by_slug_or_id("my-post")
      %Post{}

      iex> get_post_by_slug_or_id(123)
      %Post{}

      iex> get_post_by_slug_or_id("invalid")
      nil

  """
  def get_post_by_slug_or_id(slug_or_id) do
    case Integer.parse(slug_or_id) do
      {id, ""} -> Repo.get(Post, id)
      _ -> Repo.get_by(Post, slug: slug_or_id)
    end
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
  def change_post(attrs \\ %{}) do
    %Post{}
    |> Post.changeset(attrs)
  end

  @doc """
  Increments the view count for a post.
  """
  def increment_view_count(%Post{} = post) do
    {1, [updated_post]} =
      Post
      |> where(id: ^post.id)
      |> Repo.update_all(inc: [view_count: 1], returning: true)

    updated_post
  end
end
