defmodule SchmerdlePhoenixWeb.GameLive do
  alias SchmerdlePhoenix.Game

  import SchmerdlePhoenixWeb.Helpers

  use SchmerdlePhoenixWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="h-[calc(100vh-10rem)] flex flex-col justify-between">
      <div id="guesses" class="flex justify-center">
        <div class="mb-8">
          <%= for row_index <- 1..@allowed_guesses do %>
          <div class="flex my-2 gap-2 text-center text-xl font-bold justify-center">
            <%= for letter_index <- 1..@letters_per_word do %>
            <div class={get_letter_class(get_letter(@game, row_index, letter_index))}>
              <%= elem(get_letter(@game, row_index, letter_index), 1) %>
            </div>
            <% end %>
          </div>
          <% end %>
        </div>
      </div>
      <div id="keyboard" class="flex justify-center">
        <div class="flex-grow max-w-2xl">
          <%= for row <- @keyboard_rows do %>
          <div class="flex justify-center">
            <%= for key <- row do %>
            <button phx-click="keyboard_click" phx-value-key={key} class={get_key_class(@game, key)}>
              <span class="w-full text-center"><%= key %></span>
            </button>
            <% end %>
          </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    keyboard_rows = [
      ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
      ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
      ["enter", "z", "x", "c", "v", "b", "n", "m", "back"]
    ]

    {:ok,
     socket
     |> assign(:allowed_guesses, Game.allowed_guesses())
     |> assign(:letters_per_word, Game.letters_per_word())
     |> assign(:keyboard_rows, keyboard_rows)
     |> assign(:game, Game.initial_game_state())}
  end

  def handle_event("keyboard_click", %{"key" => "enter"}, %{assigns: assigns} = socket) do
    game = Game.submit_guess(assigns.game)
    IO.inspect(game)

    socket
    |> assign(:game, game)
    |> noreply()
  end

  def handle_event("keyboard_click", %{"key" => "back"}, %{assigns: assigns} = socket) do
    socket
    |> assign(:game, Game.remove_letter(assigns.game))
    |> noreply()
  end

  def handle_event("keyboard_click", %{"key" => key}, %{assigns: assigns} = socket) do
    socket
    |> assign(:game, Game.guess_letter(assigns.game, key))
    |> noreply()
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
    base = "h-10 bg-gray-200 rounded-md m-1 flex flex-col justify-center flex-auto"

    case status do
      :none -> base
      :correct -> base <> " " <> "bg-green-600 text-white"
      :present -> base <> " " <> "bg-yellow-500 text-white"
      :absent -> base <> " " <> "bg-gray-600 text-white"
    end
  end
end
