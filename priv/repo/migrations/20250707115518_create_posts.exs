defmodule Blogging.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :sub_title, :string, null: false
      add :html_content, :text, null: false
      add :tags, {:array, :string}, default: []
      add :view_count, :integer, default: 0
      add :is_published, :boolean, default: false

      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false

      timestamps()
    end

    create index(:posts, [:user_id])
    # Full-text search & filtering by tags
    create index(:posts, [:tags], using: "GIN")
    create index(:posts, [:is_published])
  end
end
