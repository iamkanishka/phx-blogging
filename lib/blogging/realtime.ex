defmodule Blogging.Realtime do
  @moduledoc """
  Handles real-time functionality including PubSub subscriptions and presence tracking.
  """
  alias Blogging.Presence
  alias Phoenix.PubSub

  @doc """
  Subscribes to a post's topic for real-time updates.
  """
  def subscribe(post_id) do
    PubSub.subscribe(Blogging.PubSub, "post:#{post_id}")
  end

  @doc """
  Broadcasts a new comment to all subscribers of a post.
  """
  def broadcast_comment(post_id, comment) do
    PubSub.broadcast(Blogging.PubSub, "post:#{post_id}", {:new_comment, comment})
  end

  @doc """
  Broadcasts a reaction update to all subscribers of a post.
  """
  def broadcast_reaction(post_id, reaction) do
    PubSub.broadcast(Blogging.PubSub, "post:#{post_id}", {:reaction_update, reaction})
  end

  @doc """
  Tracks user presence on a specific post.
  """
  def track_user_presence(post_id, user_id, user_name) do
    Presence.track(
      self(),
      "post:#{post_id}",
      user_id,
      %{
        user_id: user_id,
        username: user_name,
        online_at: System.system_time(:second),
        post_id: post_id
      }
    )
  end

  @doc """
  Lists all users currently viewing a post.
  """
  def list_post_presence(post_id) do
    Presence.list("post:#{post_id}")
    |> Enum.map(fn {user_id, %{metas: [meta | _]}} ->
      {user_id, meta}
    end)
  end

  @doc """
  Clears the presence tracking for a specific post.
  """
  def clear_presence(post_id) do
    Presence.clear("post:#{post_id}")
  end

  def presence_diff(post_id, user_id) do
    Presence.diff("post:#{post_id}", user_id)
  end

  @doc """
  Unsubscribes from a post's topic.
  """
  def unsubscribe(post_id) do
    PubSub.unsubscribe(Blogging.PubSub, "post:#{post_id}")
  end

  @doc """
  Unsubscribes from all topics related to a user.
  """
  def unsubscribe_all(user_id) do
    PubSub.unsubscribe(Blogging.PubSub, "user:#{user_id}")
    Presence.untrack(self(), "user:#{user_id}")
  end

  @doc """
  Unsubscribes from all topics related to a post.
  """
  def unsubscribe_post(post_id) do
    PubSub.unsubscribe(Blogging.PubSub, "post:#{post_id}")
    Presence.untrack(self(), "post:#{post_id}")
  end


  @doc """
  Unsubscribes from all topics related to a comment.
  """
  def unsubscribe_comment(comment_id) do
    PubSub.unsubscribe(Blogging.PubSub, "comment:#{comment_id}")
    Presence.untrack(self(), "comment:#{comment_id}")
  end

  @doc """
  Unsubscribes from all topics related to a reaction.
  """
  def unsubscribe_reaction(reaction_id) do
    PubSub.unsubscribe(Blogging.PubSub, "reaction:#{reaction_id}")
    Presence.untrack(self(), "reaction:#{reaction_id}")
  end

  @doc """
  Unsubscribes from all topics related to a user.
  """
  def unsubscribe_user(user_id) do
    PubSub.unsubscribe(Blogging.PubSub, "user:#{user_id}")
    Presence.untrack(self(), "user:#{user_id}")
  end


end
