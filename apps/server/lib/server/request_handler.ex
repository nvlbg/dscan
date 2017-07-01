defmodule ProgressHandler do
  use GenEvent

  def handle_event({ip, port}, {_targets_left, _socket} = state) do
    IO.inspect {ip, port}
    {:ok, state}
  end

  def handle_event(:done, {1, socket}) do
    :ssl.send(socket, "done")
    :ssl.close(socket)
    GenEvent.stop(self())
    :remove_handler
  end

  def handle_event(:done, {targets_left, socket}) do
    {:ok, {targets_left - 1, socket}}
  end
end

defmodule Server.RequestHandler do
  require Logger

  def serve(socket) do
    case :ssl.ssl_accept(socket) do
      :ok ->
        serve_loop(socket)
      {:error, reason} ->
        Logger.error "Could not ssl accept: #{reason}"
        :ssl.close(socket)
    end
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
    total_nodes   = Enum.count(Node.list()) + 1
    total_targets = Enum.count(targets) * total_nodes
    {:ok, pid} = GenEvent.start_link
    GenEvent.add_handler(pid, ProgressHandler, {total_targets, socket})

    Enum.each(targets, fn target ->
      Network.new(target)
      |> Network.partition(total_nodes)
      |> Enum.zip([node() | Node.list()])
      |> Enum.each(fn {net, node} ->
        Scanner.Service.scan(node, pid, net, ports, 5000)
      end)
    end)
  end

  defp serve_request(socket, req) do
    Logger.error "Unknown command: #{req}"
    :ssl.send(socket, "unknown_command")
    :ssl.close(socket)
  end
end

