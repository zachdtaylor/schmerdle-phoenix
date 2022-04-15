defmodule SchmerdlePhoenix.Repo do
  use Ecto.Repo,
    otp_app: :schmerdle_phoenix,
    adapter: Ecto.Adapters.Postgres
end
