defmodule Blogging.Contents.Reactions.Reactions do
  import Ecto.Query, warn: false
  alias Blogging.Repo
  alias Blogging.Contents.Reactions.Reaction
  alias Blogging.Contents.Posts.Post
  alias Blogging.Contents.Comments.Comment

  @doc """
  Loads the associated reactable (post or comment) dynamically.
  """
  def get_reactable(reactable_type: "post", reactable_id: id) do
    Repo.get(Post, id)
  end

  def get_reactable(reactable_type: "comment", reactable_id: id) do
    Repo.get(Comment, id)
  end

  def get_reactable(_), do: nil

  @reaction_types ~w(like love wow laugh sad angry)

  def count_reactions_and_user_reaction(reactable_type, reactable_id, user_id) do
    import Ecto.Query

    # Count all reactions for given reactable
    counts_query =
      from(r in Blogging.Contents.Reactions.Reaction,
        where: r.reactable_type == ^reactable_type and r.reactable_id == ^reactable_id,
        group_by: r.type,
        select: {r.type, count(r.id)}
      )

    # Get all reactions of user for given reactable
    user_reactions_query =
      from(r in Blogging.Contents.Reactions.Reaction,
        where:
          r.reactable_type == ^reactable_type and
            r.reactable_id == ^reactable_id and
            r.user_id == ^user_id,
        select: r.type
      )

    counts = Blogging.Repo.all(counts_query) |> Enum.into(%{})
    user_reacted_types = Blogging.Repo.all(user_reactions_query) |> MapSet.new()

    user_reacted =
      Enum.into(@reaction_types, %{}, fn type ->
        {type, MapSet.member?(user_reacted_types, type)}
      end)

    %{counts: counts, user_reacted: user_reacted}
  end

  @doc """
  Returns the total reaction counts grouped by type for a given reactable.
  """
  def reaction_counts(reactable_type, reactable_id) do
    from(r in __MODULE__,
      where: r.reactable_type == ^reactable_type and r.reactable_id == ^reactable_id,
      group_by: r.type,
      select: {r.type, count(r.id)}
    )
    |> Repo.all()
    |> Enum.into(%{})
  end

  @doc """
  Checks whether a user already reacted to a reactable.
  """
  def user_reacted?(user_id, reactable_type, reactable_id, reaction_type) do
    Reaction
    |> where(
      [r],
      r.user_id == ^user_id and
        r.reactable_type == ^reactable_type and
        r.reactable_id == ^reactable_id and
        r.type == ^reaction_type
    )
    |> Repo.one()
  end

  def upsert_reaction(attrs) do
    %Reaction{}
    |> Reaction.changeset(attrs)
    |> Repo.insert(
      on_conflict: [set: [type: attrs.type]],
      conflict_target: [:user_id, :reactable_type, :reactable_id]
    )
  end

  def toggle_reaction(%{} = attrs) do
    user_id = Map.get(attrs, "user_id") || Map.get(attrs, :user_id)
    reactable_type = Map.get(attrs, "reactable_type") || Map.get(attrs, :reactable_type)
    reactable_id = Map.get(attrs, "reactable_id") || Map.get(attrs, :reactable_id)
    reaction_type = Map.get(attrs, "type") || Map.get(attrs, :type)

    existing_reaction = user_reacted?(user_id, reactable_type, reactable_id, reaction_type)

    case existing_reaction do
      nil ->
        %Reaction{}
        |> Reaction.changeset(%{
          user_id: user_id,
          reactable_type: reactable_type,
          reactable_id: reactable_id,
          type: reaction_type
        })
        |> Repo.insert()

      reaction ->
        Repo.delete(reaction)
    end
  end

  @doc """
  Returns the list of reactions.
  """
  def list_reactions do
    Repo.all(Reaction)
  end

  @doc """
  Gets a single reaction by ID.
  """
  def get_reaction!(id), do: Repo.get!(Reaction, id)

  @doc """
  Gets a reaction for a specific user and reactable.
  """
  def get_user_reaction(user_id, reactable_type, reactable_id) do
    Repo.get_by(Reaction,
      user_id: user_id,
      reactable_type: reactable_type,
      reactable_id: reactable_id
    )
  end

  @doc """
  Creates a reaction (or replaces it if it exists).
  """
  def create_reaction(attrs \\ %{}) do
    %Reaction{}
    |> Reaction.changeset(attrs)
    |> Repo.insert(
      # on_conflict: :replace_all,
      # conflict_target: [:user_id, :reactable_type, :reactable_id]
    )
  end

  @doc """
  Updates a reaction.
  """
  def update_reaction(%Reaction{} = reaction, attrs) do
    reaction
    |> Reaction.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a reaction.
  """
  def delete_reaction(%Reaction{} = reaction) do
    Repo.delete(reaction)
  end

  @doc """
  Returns a changeset for tracking reaction changes.
  """
  def change_reaction(%Reaction{} = reaction, attrs \\ %{}) do
    Reaction.changeset(reaction, attrs)
  end

  @doc """
  Returns counts of each reaction type for a post or comment.
  """
  def count_reactions(reactable_type, reactable_id) do
    Reaction
    |> where([r], r.reactable_type == ^reactable_type and r.reactable_id == ^reactable_id)
    |> group_by([r], r.type)
    |> select([r], {r.type, count(r.id)})
    |> Repo.all()
    |> Enum.into(%{})
  end

  @doc """
  Deletes all reactions for a given reactable (e.g., when deleting a post).
  """
  def delete_reactions_for(reactable_type, reactable_id) do
    Reaction
    |> where([r], r.reactable_type == ^reactable_type and r.reactable_id == ^reactable_id)
    |> Repo.delete_all()
  end

 def populate_data(user_id, post_id) do
  Repo.transaction(fn ->
    {:ok, comment} =
      %Comment{}
      |> Comment.changeset(%{content: "First comment", user_id: user_id, post_id: post_id})
      |> Repo.insert()

    {:ok, reply} =
      %Comment{}
      |> Comment.changeset(%{
        content: "Reply to first",
        user_id: user_id,
        post_id: post_id,
        parent_id: comment.id,
        depth: 1
      })
      |> Repo.insert()

    {:ok, _reply2} =
      %Comment{}
      |> Comment.changeset(%{
        content: "Reply to reply",
        user_id: user_id,
        post_id: post_id,
        parent_id: reply.id,
        depth: 2
      })
      |> Repo.insert()
  end)
end


end
