defmodule Lab4.Supervisor do
  use Supervisor

  @moduledoc """
  Супервизор приложения lab4. Запускает сервер, broadcaster и main.
  """

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      %{
        id: Lab4.Broadcaster,
        start: {Lab4.Broadcaster, :start_link, []},
        restart: :permanent,
        shutdown: 2000,
        type: :worker
      },
      %{
        id: Lab4.Server,
        start: {Lab4.Server, :start_link, [String.to_integer(System.get_env("PORT", "2025"))]},
        restart: :permanent,
        shutdown: 2000,
        type: :worker
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
