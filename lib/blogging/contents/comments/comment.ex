defmodule Blogging.Contents.Comments.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id
  schema "comments" do
    field :content, :string
    field :depth, :integer, default: 0

    belongs_to :user, Blogging.Accounts.User
    belongs_to :post, Blogging.Contents.Posts.Post
    belongs_to :parent, Blogging.Contents.Comments.Comment

    has_many :replies, Blogging.Contents.Comments.Comment, foreign_key: :parent_id
    has_many :reactions, Blogging.Contents.Reactions.Reaction

    timestamps()
  end

  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:content, :user_id, :post_id, :parent_id, :depth])
    |> validate_required([:content, :user_id, :post_id])
    |> validate_length(:content, max: 1000)
    |> validate_depth()
    |> set_path()
  end

  defp validate_depth(changeset) do
    case get_field(changeset, :parent_id) do
      nil ->
        changeset

      _parent_id ->
        parent_depth = get_field(changeset, :depth) || 0

        if parent_depth >= 2 do
          add_error(changeset, :parent_id, "Maximum comment depth reached")
        else
          put_change(changeset, :depth, parent_depth + 1)
        end
    end
  end

  defp set_path(changeset) do
    case get_field(changeset, :parent_id) do
      nil ->
        changeset

      parent_id ->
        parent_path = get_field(changeset, :path) || ""
        put_change(changeset, :path, "#{parent_path}.#{parent_id}")
    end
  end
end
