defmodule Server.TaskAcceptor do
  require Logger

  def accept() do
    port         = Application.fetch_env!(:server, :port)
    key_password = Application.fetch_env!(:server, :key_password) |> to_charlist

    {:ok, socket} = :ssl.listen(port, [
      :binary,
      certfile:   'cert.pem',
      keyfile:    'key.pem',
      cacertfile: 'cacert.pem',
      password:   key_password,
      active:     false,
      reuseaddr:  true
    ])
    Logger.info "Accepting connections on port #{port}"
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :ssl.transport_accept(socket)
    Logger.info "Recieved a connection..."
    {:ok, pid} = Task.Supervisor.start_child(
      :request_supervisor,
      Server.RequestHandler,
      :serve,
      [client]
    )
    :ok = :ssl.controlling_process(client, pid)
    loop_acceptor(socket)
  end
end

