defmodule Server.TaskAcceptor do
  require Logger

  def accept() do
    port = System.get_env() |> Map.get("port", 5000)

    certfile = System.get_env() |> Map.get("certfile", "cert.pem") |> to_charlist
    keyfile = System.get_env() |> Map.get("keyfile", "key.pem") |> to_charlist
    cacertfile = System.get_env() |> Map.get("cacertfile", "cacert.pem") |> to_charlist
    key_password = System.get_env() |> Map.get("key_password", "") |> to_charlist

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
    {:ok, pid} = Task.Supervisor.start_child(Server.TaskSupervisor,
                                             fn -> serve(client) end)
    :ok = :ssl.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    :ok = :ssl.ssl_accept(socket)
    serve_loop(socket)
  end

  defp serve_loop(socket) do
    case :ssl.recv(socket, 0) do
      {:ok, line} ->
        Logger.info "Recieved line: #{line}"
        socket |> serve_request(line |> Poison.decode!)
        serve_loop(socket)
      {:error, :closed} ->
        Logger.info "Connection closed"
        :ssl.close(socket)
    end
  end

  defp serve_request(socket, %{"targets" => targets, "ports" => ports}) do
    :ssl.send(socket, "ok")
  end

  defp serve_request(socket, req) do
    Logger.error "Unknown command: #{req}"
    :ssl.send(socket, "unknown_command")
    :ssl.close(socket)
  end
end

