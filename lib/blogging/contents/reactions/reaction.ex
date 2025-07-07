
defmodule Blogging.Contents.Reactions.Reaction do
  use Ecto.Schema
  import Ecto.Changeset

  @reaction_types ["like", "love", "wow", "laugh", "sad", "angry"]

  schema "reactions" do
    field :type, :string
    # "post" or "comment"
    field :reactable_type, :string
    field :reactable_id, :integer

    belongs_to :user, Blogging.Accounts.User

    timestamps()
  end

  def changeset(reaction, attrs) do
    reaction
    |> cast(attrs, [:type, :reactable_type, :reactable_id, :user_id])
    |> validate_required([:type, :reactable_type, :reactable_id, :user_id])
    |> validate_inclusion(:type, @reaction_types)
    |> validate_inclusion(:reactable_type, ["post", "comment"])
    |> unique_constraint([:user_id, :reactable_type, :reactable_id])
    |> validate_reactable_exists()
  end

  defp validate_reactable_exists(changeset) do
    case {get_field(changeset, :reactable_type), get_field(changeset, :reactable_id)} do
      {"post", id} when is_integer(id) ->
        if Blogging.Repo.get(Blogging.Content.Post, id) do
          changeset
        else
          add_error(changeset, :reactable_id, "post does not exist")
        end

      {"comment", id} when is_integer(id) ->
        if Blogging.Repo.get(Blogging.Content.Comment, id) do
          changeset
        else
          add_error(changeset, :reactable_id, "comment does not exist")
        end

      _ ->
        changeset
    end
  end
end
