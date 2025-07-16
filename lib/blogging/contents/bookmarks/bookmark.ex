defmodule Blogging.Contents.Bookmarks.Bookmark do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "bookmarks" do
    belongs_to :user, Blogging.Accounts.User
    belongs_to :post, Blogging.Contents.Posts.Post

    timestamps()
  end

  def changeset(bookmark, attrs) do
    bookmark
    |> cast(attrs, [:user_id, :post_id])
    |> validate_required([:user_id, :post_id])
    |> unique_constraint([:user_id, :post_id], name: :bookmarks_user_id_post_id_index)
  end
end
