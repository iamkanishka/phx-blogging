defmodule Blogging.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    # Optional: Enable `ltree` extension if using hierarchical path indexing
    # execute("CREATE EXTENSION IF NOT EXISTS ltree")

    create table(:comments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :content, :text, null: false
      add :depth, :integer, null: false, default: 0
      # Optional ltree support:
      # add :path, :ltree

      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false
      add :post_id, references(:posts, on_delete: :delete_all, type: :binary_id), null: false
      add :parent_id, references(:comments, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    create index(:comments, [:user_id])
    create index(:comments, [:post_id])
    create index(:comments, [:parent_id])
    # Optional: for path-based lookup
    # create index(:comments, [:path], using: :gist)
  end
end
