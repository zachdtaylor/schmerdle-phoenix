defmodule SchmerdlePhoenix.Game do
  @allowed_guesses 6
  @letters_per_word 5

  def allowed_guesses do
    @allowed_guesses
  end

  def letters_per_word do
    @letters_per_word
  end

  def initial_game_state do
    %{
      board_state: [nil] |> List.duplicate(@allowed_guesses) |> List.flatten(),
      game_status: "in_progress",
      row_index: 1,
      solution: "cheek",
      current_guess: [],
      key_statuses: %{
        correct: MapSet.new(),
        present: MapSet.new(),
        absent: MapSet.new()
      }
    }
  end

  def guess_letter(game, letter) do
    cond do
      game.game_status == "win" or game.game_status == "lose" ->
        game

      length(game.current_guess) == @letters_per_word ->
        game

      true ->
        Map.put(game, :current_guess, game.current_guess ++ [letter])
    end
  end

  def remove_letter(game) do
    {_, current_guess} = List.pop_at(game.current_guess, -1)
    game |> Map.put(:current_guess, current_guess)
  end

  def submit_guess(game) when length(game.current_guess) < @letters_per_word do
    game
  end

  def submit_guess(game) do
    solution_list = String.graphemes(game.solution)

    evaluation =
      game.current_guess
      |> evaluate_correct(solution_list)
      |> evaluate_present()

    game
    |> update_board_state(evaluation)
    |> Map.put(:row_index, game.row_index + 1)
    |> Map.put(:current_guess, [])
  end

  def get_letter_status(game, letter) do
    cond do
      MapSet.member?(game.key_statuses.correct, letter) ->
        :correct

      MapSet.member?(game.key_statuses.present, letter) ->
        :present

      MapSet.member?(game.key_statuses.absent, letter) ->
        :absent

      true ->
        :none
    end
  end

  defp evaluate_correct(current_guess, solution_list) do
    evaluation =
      current_guess
      |> Enum.with_index()
      |> Enum.map(fn {letter, idx} ->
        if letter == Enum.at(solution_list, idx) do
          {:correct, letter}
        else
          {nil, letter}
        end
      end)

    filtered_solution =
      solution_list
      |> Enum.with_index()
      |> Enum.filter(fn {_, idx} ->
        case Enum.at(evaluation, idx) do
          {:correct, _} -> false
          _ -> true
        end
      end)
      |> Enum.map(fn {letter, _} -> letter end)

    {evaluation, filtered_solution}
  end

  defp evaluate_present({evaluation, filtered_solution}) do
    evaluation
    |> Enum.map(fn {eval, letter} ->
      if eval != :correct do
        if Enum.member?(filtered_solution, letter) do
          {:present, letter}
        else
          {:absent, letter}
        end
      else
        {eval, letter}
      end
    end)
  end

  defp update_board_state(game, evaluation) do
    board_state = List.replace_at(game.board_state, game.row_index - 1, evaluation)

    correct =
      MapSet.union(
        game.key_statuses.correct,
        MapSet.new(get_letters_by_status(evaluation, :correct))
      )

    present =
      MapSet.union(
        game.key_statuses.present,
        MapSet.new(get_letters_by_status(evaluation, :present))
      )

    absent =
      MapSet.union(
        game.key_statuses.absent,
        MapSet.new(get_letters_by_status(evaluation, :absent))
      )

    game
    |> Map.put(:board_state, board_state)
    |> Map.put(:key_statuses, %{correct: correct, present: present, absent: absent})
    |> set_game_status(evaluation)
  end

  defp set_game_status(game, evaluation) do
    is_correct = Enum.all?(evaluation, fn {status, _} -> status == :correct end)

    cond do
      is_correct ->
        Map.put(game, :game_status, "win")

      !is_correct and game.row_index == @allowed_guesses - 1 ->
        Map.put(game, :game_status, "lose")

      true ->
        Map.put(game, :game_status, "in_progress")
    end
  end

  defp get_letters_by_status(evaluation, status) do
    evaluation
    |> Enum.filter(fn {letter_status, _} -> letter_status == status end)
    |> Enum.map(fn {_, letter} -> letter end)
  end
end
