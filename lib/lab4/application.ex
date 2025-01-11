defmodule Lab4.Application do
  use Application

  @moduledoc """
  Главный модуль приложения lab4. Запускает супервизор.
  """

  def start(_type, _args) do
    children = [
      {Lab4.Supervisor, []} # Запускаем супервизор.
    ]

    opts = [strategy: :one_for_one, name: Lab4.Application]
    Supervisor.start_link(children, opts)
  end
end
