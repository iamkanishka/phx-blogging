
defmodule Blogging.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :username, :string
    field :password_hash, :string
    field :password, :string, virtual: true
    field :interests, {:array, :string}

    has_many :posts, Blogging.Content.Post
    has_many :comments, Blogging.Contents.Comment
    has_many :reactions, Blogging.Contents.Reaction
    has_many :notifications, Blogging.Notifications.Notification

    many_to_many :followers, Blogging.Accounts.User,
      join_through: "user_followers",
      join_keys: [followed_id: :id, follower_id: :id]

    many_to_many :following, Blogging.Accounts.User,
      join_through: "user_followers",
      join_keys: [follower_id: :id, followed_id: :id]

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :username, :interests])
    |> validate_required([:email, :username])
    |> unique_constraint(:email)
    |> unique_constraint(:username)
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:username, min: 3, max: 20)
  end

  def registration_changeset(user, attrs) do
    user
    |> changeset(attrs)
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 100)
    |> put_password_hash()
  end

  defp put_password_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        put_change(changeset, :password_hash, Argon2.hash_pwd_salt(password))

      _ ->
        changeset
    end
  end
end
