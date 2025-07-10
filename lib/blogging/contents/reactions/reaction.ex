defmodule Blogging.Contents.Reactions.Reaction do
  use Ecto.Schema
  import Ecto.Changeset

  alias Blogging.Repo
  alias Blogging.Contents.Posts.Post
  alias Blogging.Contents.Comments.Comment



  @reaction_types ~w(like love wow laugh sad angry)

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id
  schema "reactions" do
    field :type, :string
    field :reactable_type, :string
    field :reactable_id, :binary_id

    belongs_to :user, Blogging.Accounts.User

    timestamps()
  end

  def changeset(reaction, attrs) do
    reaction
    |> cast(attrs, [:type, :reactable_type, :reactable_id, :user_id])
    |> validate_required([:type, :reactable_type, :reactable_id, :user_id])
    |> validate_inclusion(:type, @reaction_types)
    |> validate_inclusion(:reactable_type, ["post", "comment"])
    |> unique_constraint([:user_id, :reactable_type, :reactable_id],
      name: :unique_user_reactable_reaction
    )
    |> validate_reactable_exists()
  end

  defp validate_reactable_exists(changeset) do
    case {get_field(changeset, :reactable_type), get_field(changeset, :reactable_id)} do
      {"post", id} when is_integer(id) ->
        if Repo.get(Post, id),
          do: changeset,
          else: add_error(changeset, :reactable_id, "post does not exist")

      {"comment", id} when is_integer(id) ->
        if Repo.get(Comment, id),
          do: changeset,
          else: add_error(changeset, :reactable_id, "comment does not exist")

      _ ->
        changeset
    end
  end
end
