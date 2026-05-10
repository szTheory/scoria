defmodule Scoria.Repo do
  use Ecto.Repo,
    otp_app: :scoria,
    adapter: Ecto.Adapters.Postgres
end
