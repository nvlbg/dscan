defmodule Server.TaskAcceptor do
  require Logger

  def accept() do
    port = System.get_env() |> Map.get("port", 5000)

    certfile     = System.get_env() |> Map.get("certfile", "cert.pem")     |> to_charlist
    keyfile      = System.get_env() |> Map.get("keyfile", "key.pem")       |> to_charlist
    cacertfile   = System.get_env() |> Map.get("cacertfile", "cacert.pem") |> to_charlist
    key_password = System.get_env() |> Map.get("key_password", "")         |> to_charlist

    :ssl.start()
    {:ok, socket} = :ssl.listen(port, [
      :binary,
      certfile: certfile,
      keyfile: keyfile,
      cacertfile: cacertfile,
      password: key_password,
      active: false,
      reuseaddr: true
    ])
    Logger.info "Accepting connections on port #{port}"
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :ssl.transport_accept(socket)
    Logger.info "Recieved a connection..."
    {:ok, pid} = Task.Supervisor.start_child(
      Server.RequestSupervisor,
      Server.RequestHandler,
      :serve,
      [client]
    )
    :ok = :ssl.controlling_process(client, pid)
    loop_acceptor(socket)
  end
end

