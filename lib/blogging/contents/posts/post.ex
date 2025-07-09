defmodule Blogging.Contents.Posts.Post do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id

  schema "posts" do
    field :title, :string
    # Stores Quill's delta format as JSON
    field :html_content, :string
    field :tags, {:array, :string}
    field :view_count, :integer, default: 0
    field :is_published, :boolean, default: false

    belongs_to :user, Blogging.Accounts.User
    has_many :comments, Blogging.Content.Comment
    has_many :reactions, Blogging.Content.Reaction

    timestamps()
  end

  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :html_content, :tags, :user_id])
    |> validate_required([:title, :html_content, :user_id])
    |> validate_length(:title, max: 100)
    |> validate_length(:tags, max: 5)
  end
end
