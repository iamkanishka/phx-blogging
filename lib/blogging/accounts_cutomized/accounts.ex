defmodule Blogging.AccountsCutomized.Accounts do
  import Ecto.Query, warn: false
  alias Blogging.Repo
  alias Blogging.Accounts.User

  def get_user(id), do: Repo.get(User, id)
  def get_user_by_email(email), do: Repo.get_by(User, email: email)

  def update_last_seen(user) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    user |> Ecto.Changeset.change(last_seen_at: now) |> Repo.update()
  end
end
