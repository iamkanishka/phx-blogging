defmodule Blogging.Accounts.UserFollowers do
  import Ecto.Query, warn: false
  alias Blogging.Repo

  alias Blogging.Accounts.{User, UserFollower}

  # Follow a user
  def follow_user(%User{id: follower_id}, %User{id: followed_id}) when follower_id != followed_id do
    %UserFollower{}
    |> UserFollower.changeset(%{follower_id: follower_id, followed_id: followed_id})
    |> Repo.insert(on_conflict: :nothing)
  end

  # Unfollow a user
  def unfollow_user(%User{id: follower_id}, %User{id: followed_id}) do
    from(uf in UserFollower,
      where: uf.follower_id == ^follower_id and uf.followed_id == ^followed_id
    )
    |> Repo.delete_all()
  end

  # Check if one user follows another
  def following?(%User{id: follower_id}, %User{id: followed_id}) do
    from(uf in UserFollower,
      where: uf.follower_id == ^follower_id and uf.followed_id == ^followed_id,
      select: count(uf.id)
    )
    |> Repo.one() > 0
  end

  # Get list of users a given user is following
  def list_following(%User{id: user_id}) do
    from(u in User,
      join: uf in UserFollower, on: uf.followed_id == u.id,
      where: uf.follower_id == ^user_id
    )
    |> Repo.all()
  end

  # Get list of followers for a given user
  def list_followers(%User{id: user_id}) do
    from(u in User,
      join: uf in UserFollower, on: uf.follower_id == u.id,
      where: uf.followed_id == ^user_id
    )
    |> Repo.all()
  end
end



# # follow
# Accounts.follow_user(current_user, other_user)

# # unfollow
# Accounts.unfollow_user(current_user, other_user)

# # check
# Accounts.following?(current_user, other_user)

# # get all followers
# Accounts.list_followers(current_user)

# # get all followed users
# Accounts.list_following(current_user)
