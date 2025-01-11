defmodule Lab4.Server do
  use GenServer
  require Logger

  @moduledoc """
  Логика сервера: управление клиентскими соединениями, история чата (через mnesia).
  """

  def start_link(port) do
    GenServer.start_link(__MODULE__, port, name: __MODULE__)
  end

  def init(port) do
    Logger.info("Server starting on port #{port}")
    {:ok, listen_socket} =
      :gen_tcp.listen(port, [:binary, {:packet, 2}, {:active, false}, {:reuseaddr, true}])

    spawn(fn -> accept_connections(listen_socket) end)

    # Инициализация базы данных (mnesia)
    :mnesia.create_schema([node()])
    :mnesia.start()
    :mnesia.create_table(:message, [
      {:attributes, [:unixtime, :nickname, :text]},
      {:type, :ordered_set},
      {:disc_copies, [node()]}
    ])

    {:ok, %{listen_socket: listen_socket}}
  end

  defp accept_connections(listen_socket) do
    {:ok, socket} = :gen_tcp.accept(listen_socket)
    Logger.info("New client connected")
    spawn(fn -> handle_connection(socket) end)
    accept_connections(listen_socket)
  end

  defp handle_connection(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, raw_msg} ->
        message = :erlang.binary_to_term(raw_msg)
        case message do
          %{text: text, nickname: nickname, unixtime: _unixtime} ->
            IO.puts("[#{Time.utc_now()}] <#{nickname}>: #{text}")

          other ->
            Logger.warning("Received unexpected message: #{inspect(other)}")
        end

        # Обрабатываем и сохраняем сообщение, отправленное клиентом
        response = process_message(socket, message)

        # Возвращаем ответ на сокет клиента
        :gen_tcp.send(socket, :erlang.term_to_binary(response))

        # Продолжаем обработку соединения
        handle_connection(socket)

      {:error, :closed} ->
        Logger.info("Client disconnected")

      {:error, :econnaborted} ->
        Logger.error("Connection aborted by the client")

      {:error, reason} ->
        Logger.error("Unexpected error during TCP communication: #{inspect(reason)}")
    end
  end

  defp process_message(socket, {:connect, nickname}) do
    GenServer.cast(Lab4.Broadcaster, {:new_client, socket})
    {:ok, "Welcome, #{nickname}!"}
  end

  defp process_message(_socket, {:new_message, %{text: text, nickname: nickname, unixtime: unixtime}}) do
    # Сохраняем сообщение в mnesia
    :mnesia.transaction(fn ->
      :mnesia.write({:message, unixtime, nickname, text})
    end)

    # Рассылаем сообщение всем клиентам
    GenServer.cast(Lab4.Broadcaster, {:new_message, %{unixtime: unixtime, nickname: nickname, text: text}})

    :ok
  end

  defp process_message(_socket, {:get_chat_history}) do
    :mnesia.transaction(fn ->
      :mnesia.select(
        :message,
        [{{:message, :"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}]
      )
    end)
    |> case do
      {:atomic, history} -> history
      {:aborted, _reason} -> []
    end
  end

  defp process_message(_socket, other) do
    Logger.warning("Received unknown message: #{inspect(other)}")
    :error
  end
end
