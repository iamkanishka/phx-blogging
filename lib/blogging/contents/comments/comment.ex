defmodule Blogging.Contents.Comments.Comment do
  use Ecto.Schema
  import Ecto.Changeset
  alias Blogging.Contents.Comments.Comment

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @foreign_key_type :binary_id
  schema "comments" do
    field :content, :string
    field :depth, :integer, default: 0
    # Optional if you later add path-based traversal
    field :path, :string

    belongs_to :user, Blogging.Accounts.User
    belongs_to :post, Blogging.Contents.Posts.Post
    belongs_to :parent, Comment

    has_many :replies, Comment, foreign_key: :parent_id

    has_many :reactions, Blogging.Contents.Reactions.Reaction,
      foreign_key: :reactable_id,
      where: [reactable_type: "comment"]

    timestamps()
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:content, :user_id, :post_id, :parent_id])
    |> validate_required([:content, :user_id, :post_id])
    |> validate_length(:content, max: 1000)
    |> foreign_key_constraint(:user_id, name: "comments_user_id_fkey")
    |> foreign_key_constraint(:post_id, name: "comments_post_id_fkey")
    |> foreign_key_constraint(:parent_id, name: "comments_parent_id_fkey")
    |> validate_and_set_depth()
   |> set_path()
  end

  defp validate_and_set_depth(changeset) do
    parent_id = get_change(changeset, :parent_id)

    if is_nil(parent_id) do
      put_change(changeset, :depth, 0)
    else
      case Blogging.Repo.get(Comment, parent_id) do
        nil ->
          add_error(changeset, :parent_id, "Parent comment not found")

        %Comment{depth: parent_depth} when parent_depth >= 2 ->
          add_error(changeset, :depth, "Maximum nesting (2 levels) reached")

        %Comment{depth: parent_depth} ->
          put_change(changeset, :depth, parent_depth + 1)
      end
    end
  end



  defp set_path(changeset) do
    case get_change(changeset, :parent_id) do
      nil ->
        # Root comment: path is its own ID
        case changeset.data.id || get_field(changeset, :id) do
          # ID not available yet
          nil -> changeset
          id -> put_change(changeset, :path, to_string(id))
        end

      parent_id ->
        case Blogging.Repo.get(Comment, parent_id) do
          nil ->
            changeset

          %Comment{path: parent_path} ->
            case get_field(changeset, :id) do
              nil -> changeset
              id -> put_change(changeset, :path, "#{parent_path}.#{id}")
            end
        end
    end
  end

  # Optional ltree path field if you decide to support ancestry navigation
  # defp set_path(changeset) do
  #   case get_change(changeset, :parent_id) do
  #     nil -> put_change(changeset, :path, "")
  #     parent_id ->
  #       case Blogging.Repo.get(Comment, parent_id) do
  #         nil -> changeset
  #         %Comment{path: parent_path} ->
  #           new_path = parent_path <> "." <> to_string(parent_id)
  #           put_change(changeset, :path, new_path)
  #       end
  #   end
  # end
end
