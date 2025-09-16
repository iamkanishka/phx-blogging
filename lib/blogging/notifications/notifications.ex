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

    message = build_message(type, data)

  changeset =
      %Notification{}
      |> Notification.changeset(%{
        user_id: user_id,
        type: type,
        data: data,
        message: message
      })

      case Repo.insert(changeset) do
      {:ok, notification} ->
        broadcast_new_notification(notification)
        {:ok, notification}

      {:error, changeset} ->
        {:error, changeset}

      other ->
        {:error, other}
    end
  end

  defp broadcast_new_notification(notification) do
    BloggingWeb.Endpoint.broadcast(
      "notifications:#{notification.user_id}",
      "new_notification",
      %{notification: notification}
    )
  end

  defp build_message(:comment, data) do
    "#{data.name} commented on your post"
  end

  defp build_message(:reply, data) do
    "#{data.name} replied to a comment on your post"
  end

  defp build_message(:reaction, data) do
    "#{data.name} reacted with #{data.emoji}"
  end

  defp build_message(:follow, data) do

    "#{data.name} followed you"
  end

  defp build_message(:subscription, data) do
     "#{data.name} subscribed to get email notifications for your stories"
  end

  defp build_message(:system, msg) do
    msg
  end

  # -------------------------
  # Type-Specific Helpers
  # -------------------------

  def notify_comment(user_id, commentor_id, post_id, commenter_name) do
  create_notification(user_id, :comment, %{
    notifier_id: commentor_id,
    post_id: post_id,
    name: commenter_name
  })
end

def notify_reply(user_id, commentor_id, post_id, commenter_name) do
  create_notification(user_id, :reply, %{
    notifier_id: commentor_id,
    post_id: post_id,
    name: commenter_name
  })
end

def notify_post_reaction(user_id, reactable_type, reactable_id, reactor_id, emoji, reactor_name) do
  create_notification(user_id, :reaction, %{
    reactable_type: reactable_type,
    reactable_id: reactable_id,
    emoji: emoji,
    notifier_id: reactor_id,
    name: reactor_name
  })
end

def notify_follow(user_id, follower_id, follower_name) do
  create_notification(user_id, :follow, %{
    notifier_id: follower_id,
    name: follower_name
  })
end

def notify_subscription(user_id, subscriber_id, subscriber_name) do
  create_notification(user_id, :subscription, %{
    notifier_id: subscriber_id,
    name: subscriber_name
  })
end

@spec notify_system(any(), any()) :: {:error, any()} | {:ok, any()}
def notify_system(user_id, message) do
  create_notification(user_id, :system, %{
    notifier_id: nil,
    message: message
  })
end


  defp format_timestamp(naive_dt) do
    # e.g. "2 days ago"
    Timex.format!(naive_dt, "{relative}", :relative)
  end

  def some_function() do
    message = build_message(:comment, %{"name" => "Kanishka"})
    IO.puts(message)
  end
end
