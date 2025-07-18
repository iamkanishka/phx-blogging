defmodule Blogging.Accounts.EmailSubscription do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id
  schema "user_subscriptions" do
    belongs_to :user, Blogging.Accounts.User, foreign_key: :user_id
    belongs_to :subscriber, Blogging.Accounts.User, foreign_key: :subscriber_user_id

    timestamps()
  end

  @doc false
  def changeset(user_subscription, attrs) do
    user_subscription
    |> cast(attrs, [:user_id, :subscriber_user_id])
    |> validate_required([:user_id, :subscriber_user_id])
    |> unique_constraint([:user_id, :subscriber_user_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:subscriber_user_id)
  end
end
