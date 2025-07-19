defmodule Blogging.Accounts.EmailSubscriptions do
  import Ecto.Query, warn: false
  alias Blogging.Repo

  alias Blogging.Accounts.{User, EmailSubscription, UserFollower}

  @doc """
  Subscribes a user to another user by creating an EmailSubscription.
  """
  def subscribe_user(user_id, subscriber_user_id) do
    %EmailSubscription{}
    |> EmailSubscription.changeset(%{
      user_id: user_id,
      subscriber_user_id: subscriber_user_id
    })
    |> Repo.insert()
  end

  @doc """
  Unsubscribes a user from another user by deleting the EmailSubscription.
  """
  def unsubscribe_user(user_id, subscriber_user_id) do
    from(s in EmailSubscription,
      where: s.user_id == ^user_id and s.subscriber_user_id == ^subscriber_user_id
    )
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      subscription -> Repo.delete(subscription)
    end
  end

  @doc """
  Checks whether a user is subscribed to another user.
  """
  def subscribed?(user_id, subscriber_user_id) do
    from(s in EmailSubscription,
      where: s.user_id == ^user_id and s.subscriber_user_id == ^subscriber_user_id,
      select: count(s.id)
    )
    |> Repo.one()
    |> Kernel.>(0)
  end

  @doc """
  Returns a list of users the given user is following, with subscription status.
  """
  def list_following_with_subscription(user_id) do
    from(uf in UserFollower,
      where: uf.follower_id == ^user_id,
      join: u in User,
      on: u.id == uf.followed_id,
      left_join: s in EmailSubscription,
      on: s.user_id == uf.followed_id and s.subscriber_user_id == ^user_id,
      select: %{
        user: u,
        subscribed: not is_nil(s.id)
      }
    )
    |> Repo.all()
  end

  @doc """
  Returns a list of users who are following the given user, with subscription status.
  """
  def list_followers_with_subscription(user_id) do
    from(uf in UserFollower,
      where: uf.followed_id == ^user_id,
      join: u in User,
      on: u.id == uf.follower_id,
      left_join: s in EmailSubscription,
      on: s.user_id == u.id and s.subscriber_user_id == ^user_id,
      select: %{
        user: u,
        subscribed: not is_nil(s.id)
      }
    )
    |> Repo.all()
  end

  @doc """
  Lists all email subscriptions where a user is the target (i.e., subscribed *to* this user).
  """
  def list_user_subscribers(user_id) do
    from(s in EmailSubscription,
      where: s.user_id == ^user_id,
      join: u in User,
      on: u.id == s.subscriber_user_id,
      select: u
    )
    |> Repo.all()
  end

  @doc """
  Lists all email subscriptions where a user is the subscriber (i.e., user has *subscribed to* these users).
  """
  def list_user_subscriptions(subscriber_user_id) do
    from(s in EmailSubscription,
      where: s.subscriber_user_id == ^subscriber_user_id,
      join: u in User,
      on: u.id == s.user_id,
      select: u
    )
    |> Repo.all()
  end
end
