defmodule SchmerdlePhoenix.Word do
  alias __MODULE__
  alias SchmerdlePhoenix.Repo

  use Ecto.Schema
  import Ecto.Changeset

  require Ecto.Query

  @primary_key {:value, :string, []}

  schema "words" do
    field :rating, :integer, default: 0

    timestamps()
  end

  @doc false
  def changeset(word, attrs) do
    word
    |> cast(attrs, [:value, :rating])
    |> validate_required([:value])
  end

  @spec random(integer()) :: Word
  def random(len) do
    result =
      Repo.query!(
        "select * from words where length(words.value) = $1 and rating >= 0 order by random() limit 1",
        [len]
      )

    case Enum.at(result.rows, 0) do
      nil -> %Word{}
      word -> Repo.load(Word, {result.columns, word})
    end
  end

  def exists(word) do
    result =
      Word
      |> Ecto.Query.where(value: ^word)
      |> Repo.one()

    result != nil
  end
end
