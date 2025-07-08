defmodule Blogging.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :title, :string, null: false
      add :html_content, :text, null: false # Rendered HTML
      add :tags, {:array, :string}, default: []
      add :view_count, :integer, default: 0
      add :is_published, :boolean, default: false

      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:posts, [:user_id])
    create index(:posts, [:tags], using: "GIN") # Full-text search & filtering by tags
    create index(:posts, [:is_published])
  end
end
