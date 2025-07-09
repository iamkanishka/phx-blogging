defmodule Blogging.Contents.Comments.Comments do
  import Ecto.Query, warn: false
  alias Blogging.Repo
  alias Blogging.Contents.Comments.Comment

  @moduledoc """
  Context module for managing comments and replies on posts.
  """

  import Ecto.Query, warn: false
  alias Blogging.Repo

  alias Blogging.Contents.Comments.Comment

  # ----------------------------------------------------------------------------
  # Public API
  # ----------------------------------------------------------------------------

  @doc """
  Returns all comments for a given post, preloading replies and user.
  """
  def list_comments_by_post(post_id) do
    Comment
    |> where([c], c.post_id == ^post_id and is_nil(c.parent_id))
    |> order_by([c], asc: c.inserted_at)
    |> preload([:user, :replies])
    |> Repo.all()
  end

  @doc """
  Returns all replies for a given comment.
  """
  def list_replies(comment_id) do
    Comment
    |> where([c], c.parent_id == ^comment_id)
    |> order_by([c], asc: c.inserted_at)
    |> preload([:user])
    |> Repo.all()
  end

  @doc """
  Gets a single comment by ID, preloading user and reactions.
  """
  def get_comment!(id) do
    Comment
    |> Repo.get!(id)
    |> Repo.preload([:user, :replies, :reactions])
  end

  @doc """
  Creates a comment or reply. Automatically sets `depth` and `path`.
  """
  def create_comment(attrs \\ %{}) do
    with {:ok, attrs_with_depth} <- enrich_depth(attrs),
         {:ok, changeset} <- build_comment_changeset(%Comment{}, attrs_with_depth) do
      Repo.insert(changeset)
    end
  end

  @doc """
  Updates a comment.
  """
  def update_comment(%Comment{} = comment, attrs) do
    comment
    |> Comment.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a comment and its nested replies.
  """
  def delete_comment(%Comment{} = comment) do
    # Optionally handle recursive deletion of replies
    Repo.delete(comment)
  end

  @doc """
  Returns an Ecto changeset for tracking comment changes.
  """
  def change_comment(%Comment{} = comment, attrs \\ %{}) do
    Comment.changeset(comment, attrs)
  end

  # ----------------------------------------------------------------------------
  # Private Helpers
  # ----------------------------------------------------------------------------

  defp build_comment_changeset(%Comment{} = comment, attrs) do
    {:ok, Comment.changeset(comment, attrs)}
  end

  defp enrich_depth(attrs) do
    case Map.get(attrs, "parent_id") || Map.get(attrs, :parent_id) do
      nil ->
        {:ok, Map.put(attrs, :depth, 0)}

      parent_id ->
        parent = Repo.get(Comment, parent_id)

        cond do
          parent == nil ->
            {:error, "Invalid parent comment"}

          parent.depth >= 2 ->
            {:error, "Maximum nesting depth reached"}

          true ->
            {:ok,
             attrs
             |> Map.put(:depth, parent.depth + 1)
             |> Map.put(:path, build_path(parent))}
        end
    end
  end

  defp build_path(parent) do
    parent.path
    |> to_string()
    |> Kernel.<>(".#{parent.id}")
  end

  # List only top-level comments
  def list_top_level_comments(post_id) do
    Comment
    |> where([c], is_nil(c.parent_id) and c.post_id == ^post_id)
    |> preload([:user])
    |> Repo.all()
  end

  # List all replies for a comment (flat list)
  def list_replies_flat(comment_id) do
    Comment
    |> where(parent_id: ^comment_id)
    |> preload([:user])
    |> Repo.all()
  end

  # Recursive listing (if using `ltree`)
  def list_descendants(comment) do
    descendant_path = "#{comment.path}.#{comment.id}"

    Comment
    |> where([c], fragment("? <@ ?", c.path, ^descendant_path))
    |> Repo.all()
  end

  def preload_all(comment_or_comments) do
    Repo.preload(comment_or_comments, [:user, :replies, :post, :reactions])
  end

  def preload_user(comment), do: Repo.preload(comment, :user)
  def preload_replies(comment), do: Repo.preload(comment, :replies)
  def preload_post(comment), do: Repo.preload(comment, :post)
  def preload_reactions(comment), do: Repo.preload(comment, :reactions)

  # List all comments marked as spam (if you add spam flag)
  def list_flagged_comments do
    Comment
    |> where([c], c.flagged == true)
    |> Repo.all()
  end

  # Soft delete: mark as deleted
  def soft_delete_comment(comment_id) do
    Comment
    |> Repo.get(comment_id)
    |> case do
      nil -> {:error, :not_found}
      comment -> update_comment(comment, %{content: "[deleted]"})
    end
  end

  # Find all comments containing banned words
  def list_comments_with_banned_words(banned_words) do
    pattern = Enum.join(banned_words, "|")

    Comment
    |> where([c], fragment("content ~* ?", ^pattern))
    |> Repo.all()
  end
end
