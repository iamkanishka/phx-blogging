defmodule Blogging.Contents.Feeds.Feeds do
  import Ecto.Query, warn: false
  alias Blogging.Contents.Posts.Post
  alias Blogging.Accounts.UserFollower
  alias Blogging.Repo

  import Ecto.Query

  def list_relevant_posts(current_user, params \\ %{}) do
    intrests = current_user.intrests || []
    user_id = current_user.id

    page = Map.get(params, "page", "1") |> String.to_integer()
    page_size = Map.get(params, "page_size", "10") |> String.to_integer()
    offset = (page - 1) * page_size

    base_query =
      from p in Post,
        where: p.user_id != ^user_id and fragment("? && ?", p.tags, ^intrests),
        order_by: [desc: p.inserted_at]

    posts =
      base_query
      |> offset(^offset)
      |> limit(^page_size)
      |> preload([:user, :comments, :reactions])
      |> Repo.all()

    total_count =
      base_query
      |> exclude(:order_by)
      |> select([p], count(p.id))
      |> Repo.one()

    %{
      entries: posts,
      page_number: page,
      page_size: page_size,
      total_entries: total_count,
      total_pages: ceil(total_count / page_size)
    }
  end

  def list_network_posts(current_user, params \\ %{}) do
    current_user_id = current_user.id

    page = Map.get(params, "page", "1") |> String.to_integer()
    page_size = Map.get(params, "page_size", "10") |> String.to_integer()
    offset = (page - 1) * page_size

    # Users the current user is following
    following_ids_query =
      from uf in UserFollower,
        where: uf.follower_id == ^current_user_id,
        select: uf.followed_id

    # Users who follow the current user
    followers_ids_query =
      from uf in UserFollower,
        where: uf.followed_id == ^current_user_id,
        select: uf.follower_id

    base_query =
      from p in Post,
        where:
          p.user_id != ^current_user_id or
            p.user_id in subquery(following_ids_query) or
            p.user_id in subquery(followers_ids_query),
        order_by: [desc: p.inserted_at]

    posts =
      base_query
      |> offset(^offset)
      |> limit(^page_size)
      |> preload([:user, :comments, :reactions])
      |> Repo.all()

    total_count =
      base_query
      |> exclude(:order_by)
      |> select([p], count(p.id))
      |> Repo.one()

    %{
      entries: posts,
      page_number: page,
      page_size: page_size,
      total_entries: total_count,
      total_pages: ceil(total_count / page_size)
    }
  end

  def list_by_tag(tag, current_user, params \\ %{}) do
    current_user_id = current_user.id

    page = Map.get(params, "page", "1") |> String.to_integer()
    page_size = Map.get(params, "page_size", "10") |> String.to_integer()
    offset = (page - 1) * page_size

    base_query =
      from p in Post,
        where: p.user_id != ^current_user_id and fragment("? @> ?", p.tags, ^[tag]),
        order_by: [desc: p.inserted_at]

    posts =
      base_query
      |> offset(^offset)
      |> limit(^page_size)
      |> preload([:user, :comments, :reactions])
      |> Repo.all()

    total_count =
      base_query
      |> exclude(:order_by)
      |> select([p], count(p.id))
      |> Repo.one()

    %{
      entries: posts,
      page_number: page,
      page_size: page_size,
      total_entries: total_count,
      total_pages: ceil(total_count / page_size)
    }
  end
end
