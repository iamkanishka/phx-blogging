defmodule BloggingWeb.FollowingFollwers.Index do
  use BloggingWeb, :live_view

  alias Blogging.Accounts.UserFollowers
  alias Blogging.Accounts

  @impl true
  def mount(_params, session, socket) do
    current_user = Accounts.get_user_by_session_token(session["user_token"])

    following = UserFollowers.list_following_with_subscription(current_user.id)

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(following: following)}
  end
end
