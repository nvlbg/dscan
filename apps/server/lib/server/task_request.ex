defmodule Server.TaskRequest do
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
    scans = for target <- targets, port <- ports do
      {target, port, Task.Supervisor.async_nolink(Server.TaskSupervisor, Server.Scanner, :scan, [target, port, 100])}
    end
    scans |> Enum.map(fn {ip, port, task} -> {ip, port, Task.await(task)} end) |> Enum.filter(fn {_, _, status} -> status == :open end) |> IO.inspect
    :ssl.send(socket, "ok")
  end

  defp serve_request(socket, req) do
    Logger.error "Unknown command: #{req}"
    :ssl.send(socket, "unknown_command")
    :ssl.close(socket)
  end
end

