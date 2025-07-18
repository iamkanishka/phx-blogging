defmodule Blogging.Repo.Migrations.CreateEmailSubscription do

  use Ecto.Migration

  def change do
    create table(:user_email_subscriptions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)
      add :subscriber_user_id, references(:users, type: :binary_id, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:user_email_subscriptions, [:user_id, :subscriber_user_id])
  end
end
