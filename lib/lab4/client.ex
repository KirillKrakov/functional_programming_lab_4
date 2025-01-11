defmodule Lab4.Client do
  use GenServer
  require Logger

  @moduledoc """
  Логика клиента: подключение к серверу, отправка и получение сообщений.
  """

  def start_link(%{host: host, port: port, nickname: nickname}) do
    GenServer.start_link(__MODULE__, %{host: host, port: port, nickname: nickname})
  end

  def init(state) do
    # Логируем процесс подключения
    Logger.info("Connecting to server at #{state.host}:#{state.port} as #{state.nickname}")

    # Попытка подключения к серверу
    case :gen_tcp.connect(String.to_charlist(state.host), state.port, [:binary, {:active, true}, {:packet, 2}]) do
      {:ok, socket} ->
        # Если соединение успешно, отправляем сообщение "connect"
        :gen_tcp.send(socket, :erlang.term_to_binary({:connect, state.nickname}))
        {:ok, Map.put(state, :socket, socket)}

      {:error, reason} ->
        # Логируем неудачное подключение и останавливаем процесс
        Logger.error("Failed to connect to server: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  # Отправка сообщений
  def handle_call({:send_message, text}, _from, state) do
    timestamp = :os.system_time(:seconds)

    # Отправка сообщения серверу
    msg = {:new_message, %{text: text, nickname: state.nickname, unixtime: timestamp}}
    :gen_tcp.send(state.socket, :erlang.term_to_binary(msg))

    {:reply, :ok, state}
  end

  # Получение данных от сокета
  def handle_info({:tcp, _socket, raw_message}, state) do
  # Декодируем сообщение
  message = :erlang.binary_to_term(raw_message)

  case message do
    %{text: text, nickname: nickname, unixtime: _unixtime} ->
      IO.puts("[#{Time.utc_now()}] <#{nickname}>: #{text}")

    other ->
      Logger.warning("Received unexpected message: #{inspect(other)}")
  end

  {:noreply, state}
end


  def handle_info({:tcp_closed, _socket}, state) do
    Logger.warning("Disconnected from server")
    {:stop, :normal, state}
  end
end
