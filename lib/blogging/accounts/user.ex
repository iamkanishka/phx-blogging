defmodule Blogging.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id
  schema "users" do
    field :email, :string
    field :username, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :current_password, :string, virtual: true, redact: true
    field :confirmed_at, :utc_datetime
    field :bio, :string
    field :intrests, {:array, :string}

    has_many :following_relationships, Blogging.Accounts.UserFollower, foreign_key: :follower_id
    has_many :follower_relationships, Blogging.Accounts.UserFollower, foreign_key: :followed_id

    has_many :bookmarks, Blogging.Contents.Bookmarks.Bookmark
    has_many :bookmark_posts, through: [:bookmarks, :post]

    has_many :following, through: [:following_relationships, :followed]
    has_many :followers, through: [:follower_relationships, :follower]

    has_many :subscribers_relationships, Blogging.Accounts.EmailSubscription,
      foreign_key: :user_id

    has_many :subscriber_users, through: [:subscribers_relationships, :subscriber]

    has_many :subscriptions_relationships, Blogging.Accounts.EmailSubscription,
      foreign_key: :subscriber_user_id

    has_many :subscribed_to_users, through: [:subscriptions_relationships, :user]

    timestamps(type: :utc_datetime)
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.

    * `:validate_email` - Validates the uniqueness of the email, in case
      you don't want to validate the uniqueness of the email (like when
      using this changeset for validations on a LiveView form before
      submitting the form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password, :username, :bio, :intrests])
    |> validate_email(opts)
    |> validate_password(opts)
    |> validate_intrests(opts)
    |> validate_username(opts)
    |> validate_bio(opts)
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    # Examples of additional password validation:
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp validate_intrests(changeset, _opts) do
    changeset
    |> validate_required([:intrests])
    |> validate_length(:intrests, max: 10)

    # |> validate_change(:intrests, fn :intrests, intrests ->
    #   Enum.flat_map(intrests, fn intrest ->
    #     if String.match?(intrest, ~r/^[a-z0-9_-]+$/) do
    #       []
    #     else
    #       [intrests: "contains invalid characters (only a-z, 0-9, _, - allowed)"]
    #     end
    #   end)
    # end)
  end

  defp validate_bio(changeset, _opts) do
    changeset
    |> validate_required([:bio])
    |> validate_length(:bio, max: 300)
  end

  defp validate_username(changeset, _opts) do
    changeset
    |> validate_required([:username])
    |> validate_format(:username, ~r/^[a-zA-Z0-9_\.]+$/,
      message: "only letters, numbers, underscores, and dots allowed"
    )
    |> validate_length(:username, min: 3, max: 30)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Pbkdf2.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, Blogging.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for bio.
  """
  def bio_changeset(user, attrs) do
    user
    |> cast(attrs, [:bio])
    |> validate_required([:bio])
  end

  @doc """
  A user changeset for username.
  """

  def username_changeset(user, attrs) do
    user
    |> cast(attrs, [:username])
    |> validate_required([:username])
  end

  @doc """
  A user changeset for intrests.
  """
  def intrests_changeset(user, attrs) do
    user
    |> cast(attrs, [:intrests])
    |> validate_required([:intrests])
    |> validate_length(:intrests, max: 10)
    |> validate_intrests_format()
  end

  defp validate_intrests_format(changeset) do
    validate_change(changeset, :intrests, fn :intrests, intrests ->
      Enum.flat_map(intrests, fn tag ->
        if String.match?(tag, ~r/^[a-z0-9_-]+$/) do
          []
        else
          [tag: "contains invalid characters (only a-z, 0-9, _, - allowed)"]
        end
      end)
    end)
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Pbkdf2.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%Blogging.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Pbkdf2.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Pbkdf2.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    changeset = cast(changeset, %{current_password: password}, [:current_password])

    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end




  @doc """
Returns an `%Ecto.Changeset{}` for updating the user's profile.

## Examples

    iex> change_user_profile(user)
    %Ecto.Changeset{data: %User{}}
"""
def change_user_profile(%Blogging.Accounts.User{} = user, attrs \\ %{}) do
  Blogging.Accounts.User.profile_changeset(user, attrs)
end

@doc """
Updates the user's profile (username, bio, intrests).

## Examples

    iex> update_user_profile(user, %{username: "newname", bio: "hello"})
    {:ok, %Blogging.Accounts.User{}}

    iex> update_user_profile(user, %{username: nil})
    {:error, %Ecto.Changeset{}}
"""
def update_user_profile(%Blogging.Accounts.User{} = user, attrs) do
  user
  |> Blogging.Accounts.User.profile_changeset(attrs)
  |> Blogging.Repo.update()
end


# Inside Blogging.Accounts.User
def profile_changeset(user, attrs) do
  user
  |> cast(attrs, [:username, :bio])
  |> validate_required([:username, :bio])
  |> validate_length(:username, min: 3, max: 50)
  |> validate_length(:bio, max: 500)
  # |> validate_change(:intrests, fn :intrests, value ->
  #   if is_list(value) and Enum.all?(value, &is_binary/1), do: [], else: [intrests: "must be a list of strings"]
  # end)
  # |> unique_constraint(:username)
end




end
