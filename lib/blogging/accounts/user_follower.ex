defmodule Blogging.Accounts.UserFollower do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id
  schema "user_followers" do
    belongs_to :follower, Blogging.Accounts.User, foreign_key: :follower_id
    belongs_to :followed, Blogging.Accounts.User, foreign_key: :followed_id

    timestamps()
  end

  @doc false
  def changeset(user_follower, attrs) do
    user_follower
    |> cast(attrs, [:follower_id, :followed_id])
    |> validate_required([:follower_id, :followed_id])
    |> unique_constraint([:follower_id, :followed_id])
    |> foreign_key_constraint(:follower_id)
    |> foreign_key_constraint(:followed_id)
  end
end
