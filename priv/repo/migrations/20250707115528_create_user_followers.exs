defmodule Blogging.Repo.Migrations.CreateUserFollowers do
  use Ecto.Migration

  def change do
    create table(:user_followers, primary_key: false) do
      add :follower_id, references(:users, on_delete: :delete_all), null: false
      add :followed_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:user_followers, [:follower_id, :followed_id])
    create index(:user_followers, [:followed_id])
  end
end
