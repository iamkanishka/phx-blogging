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


  def get_single_comment(comment_id, current_user_id) do
  # Subquery to count replies
  replies_count_query =
    from r in Comment,
      where: r.parent_id == parent_as(:comment).id,
      select: count(r.id)

  query =
    from c in Comment,
      as: :comment,
      where: c.id == ^comment_id,
      join: u in assoc(c, :user),
      select: %{
        id: c.id,
        content: c.content,
        inserted_at: c.inserted_at,
        replies: [],
        reply_count: subquery(replies_count_query),
        replies_has_next: false,
        hide_replies: true,
        updated_at: c.updated_at,
        depth: c.depth,
        parent: c.parent_id,
        user: %{
          id: u.id,
          email: u.email,
          username: u.username
        }
      }

  case Blogging.Repo.one(query) do
    nil -> nil
    comment ->
      reaction_counts = get_reaction_counts("comment", comment.id)
      user_reacted = get_user_reaction("comment", comment.id, current_user_id)

      Map.put(comment, :reaction_data, %{
        counts: reaction_counts,
        user_reacted: user_reacted
      })
  end
end


  def get_comments(post_id, current_user_id, limit \\ 5, offset \\ 0) do
    # Subquery to count replies per comment
    replies_count_query =
      from r in Comment,
        where: r.parent_id == parent_as(:comment).id,
        select: count(r.id)

    # Fetch limit + 1 to check if more comments exist
    base_query =
      from c in Comment,
        as: :comment,
        where: c.post_id == ^post_id and is_nil(c.parent_id),
        join: u in assoc(c, :user),
        order_by: [desc: c.inserted_at],
        limit: ^(limit + 1),
        offset: ^offset,
        select: %{
          id: c.id,
          content: c.content,
          inserted_at: c.inserted_at,
          replies: [],
          reply_count: subquery(replies_count_query),
          replies_has_next: false,
          hide_replies: true,
          updated_at: c.updated_at,
          depth: c.depth,
          parent: c.parent_id,
          user: %{
            id: u.id,
            email: u.email,
            username: u.username
          }
        }

    results = Blogging.Repo.all(base_query)

    # Determine if there are more comments
    has_next = length(results) > limit

    # Only take the requested limit
    comments = Enum.take(results, limit)

    # Attach reaction data for each comment
    comments_with_reactions =
      Enum.map(comments, fn comment ->
        reaction_counts = get_reaction_counts("comment", comment.id)
        user_reacted = get_user_reaction("comment", comment.id, current_user_id)

        Map.put(comment, :reaction_data, %{
          counts: reaction_counts,
          user_reacted: user_reacted
        })
      end)

    %{comments: comments_with_reactions, has_next: has_next}
  end

  #   def get_top_comments(post_id, current_user_id, limit \\ 5) do
  #   # limit = Keyword.get(opts, :limit, 5)

  #   base_query =
  #     from c in Comment,
  #       where: c.post_id == ^post_id and is_nil(c.parent_id),
  #       order_by: [desc: c.inserted_at],
  #       limit: ^limit,
  #       preload: [:user]

  #   comments = Blogging.Repo.all(base_query)

  #   Enum.map(comments, fn comment ->
  #     reaction_counts = get_reaction_counts("comment", comment.id)
  #     user_reacted = get_user_reaction("comment", comment.id, current_user_id)

  #     Map.put(comment, :reaction_data, %{
  #       counts: reaction_counts,
  #       user_reacted: user_reacted
  #     })
  #   end)
  # end
  def get_replies(comment_id, current_user_id, limit \\ 3, offset \\ 0) do
    # Subquery to count replies for each reply
    replies_count_query =
      from r2 in Comment,
        where: r2.parent_id == parent_as(:reply).id,
        select: count(r2.id)

    # Fetch limit + 1 to check if more replies exist
    base_query =
      from r in Comment,
        as: :reply,
        where: r.parent_id == ^comment_id,
        join: u in assoc(r, :user),
        order_by: [asc: r.inserted_at],
        limit: ^(limit + 1),
        offset: ^offset,
        select: %{
          id: r.id,
          content: r.content,
          inserted_at: r.inserted_at,
          replies: [],
          reply_count: subquery(replies_count_query),
          replies_has_next: false,
          hide_replies: true,
          updated_at: r.updated_at,
          depth: r.depth,
          parent: r.parent_id,
          user: %{
            id: u.id,
            email: u.email,
            username: u.username
          }
        }

    results = Blogging.Repo.all(base_query)

    # Determine if more replies exist
    has_next = length(results) > limit

    # Take only requested limit
    replies = Enum.take(results, limit)

    # Attach reaction data for each reply
    replies_with_reactions =
      Enum.map(replies, fn reply ->
        reaction_counts = get_reaction_counts("comment", reply.id)
        user_reacted = get_user_reaction("comment", reply.id, current_user_id)

        Map.put(reply, :reaction_data, %{
          counts: reaction_counts,
          user_reacted: user_reacted
        })
      end)

    %{replies: replies_with_reactions, has_next: has_next}
  end

  defp get_reaction_counts(reactable_type, reactable_id) do
    from(r in Blogging.Contents.Reactions.Reaction,
      where: r.reactable_type == ^reactable_type and r.reactable_id == ^reactable_id,
      group_by: r.type,
      select: {r.type, count(r.id)}
    )
    |> Blogging.Repo.all()
    # Returns map like %{"like" => 3, "love" => 2, ...}
    |> Enum.into(%{})
  end

  defp get_user_reaction(reactable_type, reactable_id, user_id) do
    from(r in Blogging.Contents.Reactions.Reaction,
      where:
        r.reactable_type == ^reactable_type and r.reactable_id == ^reactable_id and
          r.user_id == ^user_id,
      select: r.type
    )
    |> Blogging.Repo.one()
  end

  #   # Get top-level comments with replies (limited if needed)
  # def get_top_comments(post_id, opts \\ []) do
  #   limit = Keyword.get(opts, :limit, 5)

  #   Comment
  #   |> where([c], c.post_id == ^post_id and is_nil(c.parent_id))
  #   |> order_by([c], desc: c.inserted_at)
  #   |> limit(^limit)
  #   |> preload([:user, :reactions])
  #   |> Blogging.Repo.all()
  # end

  # def get_replies(comment_id, limit \\ 3) do
  #   Comment
  #   |> where([r], r.parent_id == ^comment_id)
  #   |> order_by([r], asc: r.inserted_at)
  #   |> limit(^limit)
  #   |> preload([:user, :reactions])
  #   |> Blogging.Repo.all()
  # end

  # def count_replies(comment_id) do
  #   Comment
  #   |> where([r], r.parent_id == ^comment_id)
  #   |> select([r], count(r.id))
  #   |> Blogging.Repo.one()
  # end

  # def count_comments(post_id) do
  #   from(c in Comment, where: c.post_id == ^post_id)
  #   |> Blogging.Repo.aggregate(:count, :id)
  # end

  # def count_top_level_comments(post_id) do
  #   from(c in Comment, where: c.post_id == ^post_id and is_nil(c.parent_id))
  #   |> Blogging.Repo.aggregate(:count, :id)
  # end

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
