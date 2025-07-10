defmodule Blogging.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    # Enable ltree extension if path field is used

    create table(:comments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :content, :text, null: false
      add :depth, :integer, default: 0, null: false

      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false
      add :post_id, references(:posts, on_delete: :delete_all, type: :binary_id), null: false
      add :parent_id, references(:comments, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    create index(:comments, [:user_id])
    create index(:comments, [:post_id])
    create index(:comments, [:parent_id])
    # For efficient ltree queries
    # create index(:comments, [:path], using: :gist)
  end

  def down do
    drop table(:comments)
  end
end
