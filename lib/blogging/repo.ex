defmodule Blogging.Repo do
  use Ecto.Repo,
    otp_app: :blogging,
    adapter: Ecto.Adapters.Postgres

  @migration_primary_key [type: :binary_id]
  @migration_foreign_key [type: :binary_id]
end
