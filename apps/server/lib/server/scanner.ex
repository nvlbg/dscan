defmodule Server.Scanner do
  def scan(ip, port, timeout \\ :infinity)
  def scan(ip, port, timeout) when is_binary(ip) do
    scan(ip |> to_charlist, port, timeout)
  end

  def scan(ip, port, timeout) when is_binary(port) do
    scan(ip, port |> String.to_integer, timeout)
  end

  def scan(ip, port, timeout) when is_list(ip) and is_integer(port) do
    case :gen_tcp.connect(ip, port, [], timeout) do
      {:ok, socket} ->
        :gen_tcp.close(socket)
        :open
      _ ->
        :closed
    end
  end
end

