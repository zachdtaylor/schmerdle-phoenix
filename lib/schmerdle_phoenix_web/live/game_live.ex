defmodule SchmerdlePhoenixWeb.GameLive do
  alias SchmerdlePhoenix.{Game, Repo, Word}

  import SchmerdlePhoenixWeb.Helpers

  use SchmerdlePhoenixWeb, :live_view

  def render(assigns) do
    ~H"""
    <div phx-window-keyup="keyboard_click" class="h-[calc(100vh-10rem)] flex flex-col justify-between">
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
      <%= if @game.game_status == :lose do %>
      <div>
        <p class="text-center">Oof 😬</p>
        <p class="text-center">
          The word was
          <span class="text-green-600"><%= @game.solution %></span>
        </p>
      </div>
      <% end %>
      <%= if @game.game_status == :win or @game.game_status == :lose do %>
      <div class="pb-4">
        <p class="text-center">Rate the word</p>
        <div class="text-center">
          <button phx-click="rate_good" class="px-4 py-2 rounded-md text-white bg-green-600">
            Good
          </button>
          <button phx-click="rate_bad" class="px-4 py-2 rounded-md text-white bg-red-600">
            Bad
          </button>
        </div>
      </div>
      <% end %>
      <%= if assigns[:error] do %>
      <div class="pb-4">
        <p class="text-center pb-4"><%= @error %></p>
        <div class="text-center">
          <button phx-click="add_word" class="px-4 py-2 rounded-md text-white bg-purple-600">
            Add
          </button>
        </div>
      </div>
      <% end %>
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
