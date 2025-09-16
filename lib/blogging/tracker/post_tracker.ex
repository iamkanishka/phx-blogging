defmodule Blogging.Tracker.PostTracker do
  use GenServer
  alias Blogging.Realtime
  alias Blogging.Contents.Posts.Posts

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: via_tuple(opts[:post_id]))
  end

  @spec via_tuple(any()) :: {:via, Registry, {Blogging.PostRegistry, any()}}
  def via_tuple(post_id), do: {:via, Registry, {Blogging.PostRegistry, post_id}}

  def get_post(post_id) do
    GenServer.call(via_tuple(post_id), :get_post)
  end

  def add_comment(post_id, comment_params) do
    GenServer.call(via_tuple(post_id), {:add_comment, comment_params})
  end



  # Server Callbacks
  @impl true
  def init(opts) do
    post_id = opts[:post_id]
    post = Posts.get_post(post_id)
    {:ok, %{post: post}}
  end

  @impl true
  def handle_call(:get_post, _from, state) do
    {:reply, state.post, state}
  end

  @impl true
  def handle_call({:add_comment, comment_params}, _from, state) do
    case Posts.create_comment(comment_params) do
      {:ok, comment} ->
        Realtime.broadcast_comment(state.post.id, comment)
        updated_post = Posts.get_post(state.post.id)
        {:reply, {:ok, comment}, %{state | post: updated_post}}

      {:error, changeset} ->
        {:reply, {:error, changeset}, state}
    end
  end
end
