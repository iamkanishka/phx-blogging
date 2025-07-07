defmodule Blogging.Tracker.PostSupervisor do
  use DynamicSupervisor

  alias Blogging.Tracker.PostTracker

  def start_link(arg) do
    DynamicSupervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(post_id) do
    spec = {PostTracker, post_id: post_id}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def find_or_create_post_tracker(post_id) do
    case Registry.lookup(Blog.PostRegistry, post_id) do
      [{pid, _}] -> {:ok, pid}
      [] -> start_child(post_id)
    end
  end
end
