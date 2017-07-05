defmodule Scanner.TcpScanner do
  @moduledoc """
  A module for scanning TCP ports
  """

  @doc """
  Checks if `ip` has `port` opened.

  `ip` is a 32-bit binary or a char list representing the target
  `port` is a 16-bit integer
  `timeout` is the time to wait before considering the port closed
  """
  def scan_ip(ip, port, timeout \\ :infinity)

  def scan_ip(ip, port, timeout) when is_binary(ip) do
    scan_ip(ip_to_charlist(ip), port, timeout)
  end

  def scan_ip(ip, port, timeout) when is_list(ip) and is_integer(port) do
    case :gen_tcp.connect(ip, port, [], timeout) do
      {:ok, socket} ->
        :gen_tcp.close(socket)
        :open
      _ ->
        :closed
    end
  end

  defp ip_to_charlist(<< a, b, c, d >>) do
    "#{a}.#{b}.#{c}.#{d}" |> to_charlist
  end
end

