defmodule SchmerdlePhoenixWeb.GameLive do
  alias SchmerdlePhoenix.{Game, Repo, Word}

  import SchmerdlePhoenixWeb.Helpers

  use SchmerdlePhoenixWeb, :live_view

  # Since the template has the same name as this file,
  # we don't have to include the render() function here.

  def mount(_params, _session, socket) do
    keyboard_rows = [
      ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
      ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
      ["Enter", "z", "x", "c", "v", "b", "n", "m", "Backspace"]
    ]

    {:ok,
     socket
     |> assign(:allowed_guesses, Game.allowed_guesses())
     |> assign(:letters_per_word, Game.letters_per_word())
     |> assign(:keyboard_rows, keyboard_rows)
     |> assign(:game, Game.initial_game_state())}
  end

  def handle_event("keyboard_click", %{"key" => "Enter"}, %{assigns: assigns} = socket) do
    result = Game.submit_guess(assigns.game)

    case result do
      {:ok, game} ->
        socket
        |> assign(:game, game)
        |> noreply()

      {:error, message} ->
        socket
        |> assign(:error, message)
        |> noreply()
    end
  end

  def handle_event("keyboard_click", %{"key" => "Backspace"}, %{assigns: assigns} = socket) do
    socket
    |> assign(:game, Game.remove_letter(assigns.game))
    |> remove_error()
    |> noreply()
  end

  def handle_event("keyboard_click", %{"key" => key}, %{assigns: assigns} = socket) do
    socket
    |> assign(:game, Game.guess_letter(assigns.game, key))
    |> noreply()
  end

  def handle_event("rate_good", _session, %{assigns: assigns} = socket) do
    word = Repo.get!(Word, assigns.game.solution)

    word
    |> Word.changeset(%{rating: word.rating + 1})
    |> Repo.update!()

    socket
    |> assign(:game, Game.initial_game_state())
    |> noreply()
  end

  def handle_event("rate_bad", _session, %{assigns: assigns} = socket) do
    word = Repo.get!(Word, assigns.game.solution)

    word
    |> Word.changeset(%{rating: word.rating - 1})
    |> Repo.update!()

    socket
    |> assign(:game, Game.initial_game_state())
    |> noreply()
  end

  def handle_event("add_word", _session, %{assigns: assigns} = socket) do
    value = Enum.join(assigns.game.current_guess)

    %Word{value: value}
    |> Repo.insert()

    handle_event("keyboard_click", %{"key" => "Enter"}, remove_error(socket))
  end

  defp get_letter(game, row_index, letter_index) do
    cond do
      row_index < game.row_index ->
        word_list = Enum.at(game.board_state, row_index - 1)
        Enum.at(word_list, letter_index - 1)

      row_index == game.row_index and letter_index < length(game.current_guess) + 1 ->
        {:none, Enum.at(game.current_guess, letter_index - 1)}

      true ->
        {:none, ""}
    end
  end

  defp get_letter_class({status, _}) do
    base = "border-2 border-gray-200 rounded-md p-4 w-14 h-14 uppercase"

    case status do
      :none -> base
      :correct -> base <> " " <> "bg-green-600 text-white border-green-600"
      :present -> base <> " " <> "bg-yellow-500 text-white border-yellow-500"
      :absent -> base <> " " <> "bg-gray-600 text-white border-gray-600"
    end
  end

  defp get_key_class(game, key) do
    status = Game.get_letter_status(game, key)
    base = "h-10 rounded-md m-1 flex flex-col justify-center flex-auto"

    case status do
      :none -> base <> " " <> "bg-gray-200"
      :correct -> base <> " " <> "bg-green-600 text-white"
      :present -> base <> " " <> "bg-yellow-500 text-white"
      :absent -> base <> " " <> "bg-gray-600 text-white"
    end
  end

  defp remove_error(socket) do
    socket
    |> assign(:error, nil)
  end
end
