# defmodule Blogging.Accounts.UserFollowers do
#   import Ecto.Query, warn: false
#   alias Blogging.Repo

#   alias Blogging.Accounts.{User, UserFollower}

#   # Follow a user
#   def follow_user(follower_id, followed_id) when follower_id != followed_id do
#     %UserFollower{}
#     |> UserFollower.changeset(%{follower_id: follower_id, followed_id: followed_id})
#     |> Repo.insert(on_conflict: :nothing)
#   end

#   # Unfollow a user
#   def unfollow_user(follower_id, followed_id) do
#     from(uf in UserFollower,
#       where: uf.follower_id == ^follower_id and uf.followed_id == ^followed_id
#     )
#     |> Repo.delete_all()
#   end

#   # Check if one user follows another
#   def following?(%User{id: follower_id}, %User{id: followed_id}) do
#     from(uf in UserFollower,
#       where: uf.follower_id == ^follower_id and uf.followed_id == ^followed_id,
#       select: count(uf.id)
#     )
#     |> Repo.one() > 0
#   end

#   # Get list of users a given user is following
#   def list_following(%User{id: user_id}) do
#     from(u in User,
#       join: uf in UserFollower,
#       on: uf.followed_id == u.id,
#       where: uf.follower_id == ^user_id
#     )
#     |> Repo.all()
#   end

#   def list_following(user_id) do
#   from(f in Blogging.Accounts.UserFollow,
#     where: f.follower_id == ^user_id,
#     join: u in assoc(f, :following),
#     preload: [following: u]
#   )
#   |> Blogging.Repo.all()
#   |> Enum.map(& &1.following)
# end

#   # Get list of followers for a given user
#   def list_followers(%User{id: user_id}) do
#     from(u in User,
#       join: uf in UserFollower,
#       on: uf.follower_id == u.id,
#       where: uf.followed_id == ^user_id
#     )
#     |> Repo.all()
#   end
# end

# # # follow
# # Accounts.follow_user(current_user, other_user)

# # # unfollow
# # Accounts.unfollow_user(current_user, other_user)

# # # check
# # Accounts.following?(current_user, other_user)

# # # get all followers
# # Accounts.list_followers(current_user)

# # # get all followed users
# # Accounts.list_following(current_user)

defmodule Blogging.Accounts.UserFollowers do
  @moduledoc """
  The Accounts context handles user authentication, relationships (like following), and profile-related functionality.
  """

  import Ecto.Query, warn: false
  alias Blogging.Accounts.EmailSubscription
  alias Blogging.Repo

  alias Blogging.Accounts.{User, UserFollower}

  # ----------------------------------------------------------------------------
  # FOLLOW / UNFOLLOW
  # ----------------------------------------------------------------------------

  @doc """
  Creates a follow relationship between two users.

  Returns `{:ok, %UserFollower{}}` on success,
  or `{:error, changeset}` on failure (e.g. duplicate).
  """
  def follow_user(follower_id, followed_id) do
    %UserFollower{}
    |> UserFollower.changeset(%{follower_id: follower_id, followed_id: followed_id})
    |> Repo.insert(on_conflict: :nothing)
  end

  @doc """
  Deletes the follow relationship between two users.

  Returns the number of rows deleted (0 or 1).
  """
  def unfollow_user(follower_id, followed_id) do
    from(uf in UserFollower,
      where: uf.follower_id == ^follower_id and uf.followed_id == ^followed_id
    )
    |> Repo.delete_all()
  end

  # ----------------------------------------------------------------------------
  # LIST FOLLOWING & FOLLOWERS
  # ----------------------------------------------------------------------------

  @doc """
  Returns a list of users the given user is following,
  with a flag indicating whether each followed user has an email subscription.
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
        is_subscribed: not is_nil(s.id),
        is_following: true
      }
    )
    |> Repo.all()
  end

  @doc """
  Returns a list of users who are following the given user,
  with a flag indicating whether the given user has an email subscription to each follower.
  """
def list_followers_with_subscription(user_id, current_user_id) do
  from(uf in UserFollower,
    where: uf.followed_id == ^user_id,
    join: u in User, on: u.id == uf.follower_id,
    left_join: s in EmailSubscription,
      on: s.user_id == u.id and s.subscriber_user_id == ^user_id,
    # Check if current_user is following the follower (u.id)
    left_join: f in UserFollower,
      on: f.follower_id == ^current_user_id and f.followed_id == u.id,
    select: %{
      user: u,
      is_subscribed: not is_nil(s.id),
      is_following: not is_nil(f.id)
    }
  )
  |> Repo.all()
end


  # ----------------------------------------------------------------------------
  # CHECK FOLLOWING STATUS
  # ----------------------------------------------------------------------------

  @doc """
  Returns `true` if `follower_id` is following `followed_id`, otherwise `false`.
  """
  # def following?(follower_id, followed_id) do
  #   from(uf in UserFollower,
  #     where: uf.follower_id == ^follower_id and uf.followed_id == ^followed_id,
  #     select: count(uf.id) > 0
  #   )
  #   |> Repo.one()
  # end

    # Check if one user follows another
  def following?(%User{id: follower_id}, %User{id: followed_id}) do
    from(uf in UserFollower,
      where: uf.follower_id == ^follower_id and uf.followed_id == ^followed_id,
      select: count(uf.id)
    )
    |> Repo.one() > 0
  end

  # ----------------------------------------------------------------------------
  # COUNT FOLLOWERS & FOLLOWING
  # ----------------------------------------------------------------------------

  @doc """
  Returns the number of users this user is following.
  """
  def count_following(user_id) do
    from(uf in UserFollower,
      where: uf.follower_id == ^user_id,
      select: count(uf.id)
    )
    |> Repo.one()
  end

  @doc """
  Returns the number of users following this user.
  """
  def count_followers(user_id) do
    from(uf in UserFollower,
      where: uf.followed_id == ^user_id,
      select: count(uf.id)
    )
    |> Repo.one()
  end
end
