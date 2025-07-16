defmodule Blogging.Contents.Posts.Post do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id

  schema "posts" do
    field :title, :string
    field :sub_title, :string
    field :html_content, :string
    field :tags, {:array, :string}
    field :view_count, :integer, default: 0
    field :is_published, :boolean, default: false

    has_many :bookmarks, Blogging.Contents.Bookmarks.Bookmark
    has_many :bookmarked_by_users, through: [:bookmarks, :user]

    belongs_to :user, Blogging.Accounts.User
    has_many :comments, Blogging.Contents.Comments.Comment

    has_many :reactions, Blogging.Contents.Reactions.Reaction,
      foreign_key: :reactable_id,
      where: [reactable_type: "post"]

    timestamps()
  end

  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :sub_title, :html_content, :tags, :user_id])
    |> validate_required([:title, :sub_title, :html_content, :user_id])
    |> validate_length(:title, max: 100)
    |> validate_length(:tags, max: 5)
  end
end
