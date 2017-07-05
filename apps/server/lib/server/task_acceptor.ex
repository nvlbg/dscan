defmodule Server.TaskAcceptor do
  @moduledoc """
  A module for accepting incoming client connections
  """

  require Logger

  @doc """
  Starts listening for incoming connectons

  This expects the following ssl certificate files to exist:

  cert.pem   - the public certificate of the server
  key.pem    - the private key of the server
  cacert.pem - the public certificate of the CA

  `port` is the tcp port on which to listen
  `key_password` is the password for the ssl certificate of the server
  """
  def accept(port, key_password)
    when is_integer(port) and is_list(key_password) do
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
    Logger.info "Received a connection..."
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

