defmodule Blogging.PostsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Blogging.Posts` context.
  """

  @doc """
  Generate a post.
  """
  def post_fixture(attrs \\ %{}) do
    {:ok, post} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Blogging.Posts.create_post()

    post
  end
end
