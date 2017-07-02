defmodule Processor do
  def send_request(args) do
    server_ip = args |> Map.get(:server_ip)
    server_port = args |> Map.get(:server_port)

    certfile = args |> Map.get(:certfile)
    keyfile = args |> Map.get(:keyfile)
    cacertfile = args |> Map.get(:cacertfile)
    key_password = args |> Map.get(:key_password)

    targets = args |> Map.get(:targets)
    ports = args |> Map.get(:ports)

    conn = :ssl.connect(
      server_ip |> to_charlist,
      server_port,
      [
        :binary,
        certfile: certfile |> to_charlist,
        keyfile: keyfile |> to_charlist,
        cacertfile: cacertfile |> to_charlist,
        password: key_password |> to_charlist,
        active: false
      ]
    )

    case conn do
      {:ok, socket} ->
        msg = Poison.encode!(%{"targets" => targets, "ports" => ports})
        :ok = :ssl.send(socket, msg)
        recv_loop(socket)
      {:error, reason} ->
        Client.halt(1, "Could not connect to server: #{reason}")
    end
  end

  defp recv_loop(socket) do
    case :ssl.recv(socket, 0) do
      {:ok, << ip::size(32), port::size(16) >>} ->
        IO.puts "Open port found: #{ip_to_str(<< ip::size(32) >>)}:#{port}"
        recv_loop(socket)
      {:ok, "done"} ->
        IO.puts "Scan finished"
        :ssl.close(socket)
      {:error, reason} ->
        IO.puts(:stderr, "Connection closed unexpectedly: #{reason}")
        :ssl.close(socket)
    end
  end

  defp ip_to_str(<< a, b, c, d >>), do: "#{a}.#{b}.#{c}.#{d}"
end

