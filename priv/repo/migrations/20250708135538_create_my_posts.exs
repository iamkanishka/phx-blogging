defmodule Blogging.Repo.Migrations.CreateMyPosts do
  use Ecto.Migration

  def change do
    create table(:my_posts) do
      add :name, :string
      add :age, :integer

      timestamps(type: :utc_datetime)
    end
  end
end
