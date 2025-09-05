defmodule Blogging.Notifications.Notifications do
  @moduledoc """
  Context for handling user notifications.
  """

  import Ecto.Query, warn: false
  alias Blogging.Repo

  alias Blogging.Notifications.Notification
  alias Blogging.Accounts.User

  # -------------------------
  # General Notification CRUD
  # -------------------------

  def list_notifications(%User{id: user_id}) do
    Notification
    |> where(user_id: ^user_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def list_unread_notifications(%User{id: user_id}) do
    Notification
    |> where([n], n.user_id == ^user_id and is_nil(n.read_at))
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def list_read_notifications(%User{id: user_id}) do
    Notification
    |> where([n], n.user_id == ^user_id and not is_nil(n.read_at))
    |> order_by(desc: :read_at)
    |> Repo.all()
  end

  def mark_all_as_read(%User{id: user_id}) do
    from(n in Notification,
      where: n.user_id == ^user_id and is_nil(n.read_at)
    )
    |> Repo.update_all(set: [read_at: NaiveDateTime.utc_now()])
  end

  def get_notification!(id), do: Repo.get!(Notification, id)

  def mark_as_read(%Notification{} = notification) do
    notification
    |> Ecto.Changeset.change(read_at: NaiveDateTime.utc_now())
    |> Repo.update()
  end

  def delete_notification(%Notification{} = notification), do: Repo.delete(notification)

  # -------------------------
  # Generic Notification Builder
  # -------------------------

  # defp create_notification(user_id, type, data) when type in Notification.__enum_map__(:type) do
  #   %Notification{}
  #   |> Notification.changeset(%{user_id: user_id, type: type, data: data})
  #   |> Repo.insert()
  # end

  defp create_notification(user_id, type, data) do
    if type in Ecto.Enum.values(Notification, :type) do
      %Notification{}
      |> Notification.changeset(%{user_id: user_id, type: type, data: data})
      |> Repo.insert()
    else
      {:error, :invalid_type}
    end
  end

  # -------------------------
  # Type-Specific Helpers
  # -------------------------

  def notify_comment(user_id, comment_id, post_id) do
    create_notification(user_id, :comment, %{comment_id: comment_id, post_id: post_id})
  end

  def notify_reaction(user_id, reactable_type, reactable_id, emoji) do
    create_notification(user_id, :reaction, %{
      reactable_type: reactable_type,
      reactable_id: reactable_id,
      emoji: emoji
    })
  end

  def notify_mention(user_id, mentioned_by_id, post_id) do
    create_notification(user_id, :mention, %{mentioned_by: mentioned_by_id, post_id: post_id})
  end

  def notify_follow(user_id, follower_id) do
    create_notification(user_id, :follow, %{follower_id: follower_id})
  end

  def notify_subscription(user_id, subscriber_id) do
    create_notification(user_id, :subscription, %{subscriber_id: subscriber_id})
  end

  def notify_clap(user_id, post_id, clapper_id) do
    create_notification(user_id, :clap, %{post_id: post_id, clapper_id: clapper_id})
  end

  def notify_system(user_id, message) do
    create_notification(user_id, :system, %{message: message})
  end
end
