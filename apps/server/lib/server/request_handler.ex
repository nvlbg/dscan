defmodule ProgressHandler do
  use GenEvent

  def handle_event({ip, port}, {_targets_left, socket} = state) do
    :ssl.send(socket, ip <> << port::size(16) >>)
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
        serve_loop({socket, []})
      {:error, reason} ->
        Logger.error "Could not ssl accept: #{reason}"
        :ssl.close(socket)
    end
  end

  defp serve_loop({socket, tasks}) do
    case :ssl.recv(socket, 0) do
      {:ok, line} ->
        Logger.info "Recieved line: #{line}"
        new_tasks = socket |> serve_request(line |> Poison.decode!)
        serve_loop({socket, [new_tasks | tasks]})
      {:error, :closed} ->
        Logger.info "Connection closed"
        :ssl.close(socket)

        # Stop scans for this connection
        tasks
        |> Stream.concat
        |> Stream.each(fn {node, ref} -> Scanner.Service.stop(node, ref) end)
        |> Stream.run
    end
  end

  defp serve_request(socket, %{"targets" => targets, "ports" => ports}) do
    ports = if ports == "all", do: 1..65535, else: ports

    nodes = [node() | Node.list()]
    total_nodes   = Enum.count(nodes)

    scans = targets
    |> Enum.map(&Network.new/1)
    |> Enum.map(&Network.partition(&1, total_nodes))
    |> Enum.map(&Enum.zip(&1, nodes))
    |> Enum.concat

    total_scans = Enum.count(scans)

    {:ok, manager} = GenEvent.start_link
    GenEvent.add_handler(manager, ProgressHandler, {total_scans, socket})

    scans
    |> Enum.map(fn {net, node} ->
      {node, Scanner.Service.scan(node, manager, net, ports, 5000)}
    end)
  end

  defp serve_request(socket, req) do
    Logger.error "Unknown command: #{req}"
    :ssl.send(socket, "unknown_command")
    :ssl.close(socket)
    []
  end
end

