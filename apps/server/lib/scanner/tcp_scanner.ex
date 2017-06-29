defmodule Scanner.TcpScanner do
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

