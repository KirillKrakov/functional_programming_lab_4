defmodule Lab4.Broadcaster do
  use GenServer

  @moduledoc """
  Хранит сокеты клиентов и пересылает сообщения всем подключенным.
  """

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:ok, %{sockets: []}}
  end

  def handle_cast({:new_client, user_socket}, state) do
    {:noreply, %{state | sockets: [user_socket | state.sockets]}}
  end

  def handle_cast({:new_message, message}, state) do
    new_sockets =
      Enum.reduce(state.sockets, [], fn socket, acc ->
        case :gen_tcp.send(socket, :erlang.term_to_binary(message)) do
          :ok -> [socket | acc]
          _ -> acc
        end
      end)

    {:noreply, %{state | sockets: new_sockets}}
  end
end
