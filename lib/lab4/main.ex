defmodule Lab4.Main do
  @moduledoc """
  CLI для взаимодействия с клиентом.
  """

  def run do
    IO.puts("Введите хост сервера:")
    host = IO.gets("> ") |> String.trim()

    IO.puts("Введите порт сервера:")
    port =
      IO.gets("> ")
      |> String.trim()
      |> String.to_integer()

    IO.puts("Введите свой никнейм:")
    nickname = IO.gets("> ") |> String.trim()

    {:ok, pid} = Lab4.Client.start_link(%{host: host, port: port, nickname: nickname})

    IO.puts("Подключение успешно. Теперь вы можете общаться!\n")
    input_loop(pid)
  end

  defp input_loop(pid) do
    case IO.gets("> ") |> String.trim() do
      "send:" <> text ->
        GenServer.call(pid, {:send_message, String.trim(text)})

      _ ->
        IO.puts("Неизвестная команда.")
    end

    input_loop(pid)
  end
end
