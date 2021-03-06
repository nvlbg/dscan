defmodule Processor do
  @moduledoc """
  This module is the link between the client and the server

  It is responsible for sending a request from the client to
  the server and displaying the results the server responds with
  """

  @doc """
  Sends a request to the server and displays found targets
  
  `args` are the parsed and validated cli options
  """
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
        {:error, "Could not connect to server: #{reason}"}
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
        :ok
      {:ok, msg} ->
        IO.puts "Unknown response from server: #{msg}"
        :ssl.close(socket)
        :ok
      {:error, reason} ->
        :ssl.close(socket)
        {:error, "Connection closed unexpectedly: #{reason}"}
    end
  end

  defp ip_to_str(<< a, b, c, d >>), do: "#{a}.#{b}.#{c}.#{d}"
end

