defmodule Blogging.Repo.Migrations.CreateReactions do
  use Ecto.Migration

  def change do
    create table(:reactions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string, null: false
      add :reactable_type, :string, null: false
      add :reactable_id, :binary_id, null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:reactions, [:user_id])
    create index(:reactions, [:reactable_type, :reactable_id])

    # create unique_index(
    #   :reactions,
    #   [:user_id, :reactable_type, :reactable_id],
    #   name: :unique_user_reactable_reaction
    # )
  end
end
