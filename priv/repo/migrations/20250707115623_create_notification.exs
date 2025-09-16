defmodule Blogging.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string, null: false
      add :data, :map, null: false
      add :read_at, :naive_datetime
      add :message, :string

      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:notifications, [:user_id])
    create index(:notifications, [:type])
  end
end
