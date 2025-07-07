defmodule Blogging.Repo do
  use Ecto.Repo,
    otp_app: :blogging,
    adapter: Ecto.Adapters.Postgres
end
