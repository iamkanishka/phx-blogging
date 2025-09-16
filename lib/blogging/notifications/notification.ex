defmodule Blogging.Notifications.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  @types [:comment, :reaction, :reply,  :mention, :follow, :system, :subscription]

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id

  schema "notifications" do
    field :type, Ecto.Enum, values: @types
    field :data, :map
    field :read_at, :naive_datetime
    field :message, :string

    belongs_to :user, Blogging.Accounts.User

    timestamps()
  end

  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:type, :data, :message,  :user_id, :read_at])
    |> validate_required([:type, :message, :data, :user_id])
  end
end
