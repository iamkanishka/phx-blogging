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
  def user_reacted?(user_id, reactable_type, reactable_id) do
    from(r in __MODULE__,
      where:
        r.user_id == ^user_id and
          r.reactable_type == ^reactable_type and
          r.reactable_id == ^reactable_id,
      select: count(r.id) > 0
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

  def toggle_reaction(attrs) do
    %Reaction{}
    |> Reaction.changeset(attrs)
    |> Repo.insert(
      on_conflict: :nothing,
      conflict_target: [:user_id, :reactable_type, :reactable_id]
    )
  end
end
