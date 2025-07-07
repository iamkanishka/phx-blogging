defmodule Blogging.Notifications.Notifications do
  import Ecto.Query, warn: false
  alias Blogging.Repo
  alias Blogging.Notifications.Notification

  def create_notification(attrs \\ %{}) do
    %Notification{}
    |> Notification.changeset(attrs)
    |> Repo.insert()
  end

  def mark_as_read(notification) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    notification |> Ecto.Changeset.change(read_at: now) |> Repo.update()
  end

  def get_unread_notifications(user_id) do
    Notification
    |> where([n], n.user_id == ^user_id and is_nil(n.read_at))
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end
end
