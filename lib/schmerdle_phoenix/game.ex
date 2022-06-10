defmodule SchmerdlePhoenix.Game do
  alias __MODULE__
  alias SchmerdlePhoenix.Word

  import Word, only: [exists: 1]

  @type letter_status :: :correct | :present | :absent | :none

  @allowed_guesses 6
  @letters_per_word 5

  def allowed_guesses, do: @allowed_guesses

  def letters_per_word, do: @letters_per_word

  defstruct [
    :solution,
    board_state: [],
    game_status: :in_progress,
    key_statuses: %{
      correct: MapSet.new(),
      present: MapSet.new(),
      absent: MapSet.new()
    }
  ]

  defguard is_over(game) when game.game_status == :win or game.game_status == :lose
  defguard is_full(guess) when length(guess) == @letters_per_word
  defguard is_not_full(guess) when length(guess) < @letters_per_word

  def initial_game_state, do: %Game{solution: get_random_word()}

  @spec submit_guess(%Game{}, String.t()) :: {:ok, %Game{}} | {:error, String.t()}
  def submit_guess(%Game{} = game, guess)
      when guess |> is_not_full(),
      do: {:ok, game}

  def submit_guess(%Game{} = game, guess) do
    if guess |> exists() do
      {:ok, do_submit_guess(game, guess)}
    else
      {:error, "#{guess} is not valid"}
    end
  end

  defp do_submit_guess(%Game{solution: solution} = game, guess) do
    guess
    |> evaluate(solution)
    |> update_board_state(game)
  end

  @spec get_letter_status(%Game{}, String.t()) :: letter_status
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

  defp evaluate(guess, solution) do
    guess_list = split(guess)
    solution_list = split(solution)

    solution_list
    |> evaluate_correct_letters(guess_list)
    |> evaluate_present_letters()
  end

  defp evaluate_correct_letters(solution_list, current_guess) do
    current_guess
    |> Enum.zip(solution_list)
    |> Enum.reduce({[], []}, fn {guess_letter, correct_letter}, {evaluation, filtered_solution} ->
      if guess_letter == correct_letter do
        {evaluation |> append({:correct, guess_letter}), filtered_solution}
      else
        {evaluation |> append({nil, guess_letter}), filtered_solution |> append(correct_letter)}
      end
    end)
  end

  defp evaluate_present_letters({evaluation, filtered_solution}) do
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

  defp update_board_state(evaluation, game) do
    board_state = append(game.board_state, evaluation)

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
        Map.put(game, :game_status, :win)

      !is_correct and length(game.board_state) == @allowed_guesses ->
        Map.put(game, :game_status, :lose)

      true ->
        Map.put(game, :game_status, :in_progress)
    end
  end

  defp get_letters_by_status(evaluation, status) do
    evaluation
    |> Enum.filter(fn {letter_status, _} -> letter_status == status end)
    |> Enum.map(fn {_, letter} -> letter end)
  end

  #### Helper functions

  defp append(list, element), do: list ++ [element]
  defp split(value), do: String.graphemes(value)
  defp get_random_word, do: Word.random(@letters_per_word).value
end
