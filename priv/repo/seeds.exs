# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     SchmerdlePhoenix.Repo.insert!(%SchmerdlePhoenix.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
defmodule Seed do
  @max_pg_parameters 65535

  def load_words_json() do
    with {:ok, body} <- File.read("./words.json"),
         {:ok, json} <- Jason.decode(body) do
      {:ok, json}
    end
  end

  def seed_words() do
    {:ok, data} = load_words_json()

    entries =
      Enum.map(data, fn word ->
        %{
          :value => word,
          :rating => 0,
          :inserted_at => NaiveDateTime.local_now(),
          :updated_at => NaiveDateTime.local_now()
        }
      end)

    for chunk <- Enum.chunk_every(entries, div(@max_pg_parameters, 5)) do
      SchmerdlePhoenix.Repo.insert_all(
        SchmerdlePhoenix.Word,
        chunk,
        on_conflict: :nothing
      )
    end
  end
end

Seed.seed_words()
