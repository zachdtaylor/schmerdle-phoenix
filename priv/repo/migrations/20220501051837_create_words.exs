defmodule SchmerdlePhoenix.Repo.Migrations.CreateWords do
  use Ecto.Migration

  def change do
    create table(:words, primary_key: false) do
      add :value, :string, primary_key: true
      add :rating, :integer, default: 0

      timestamps()
    end
  end
end
