defmodule Scanner.TestScanner do
  def scan_ip(ip, port, timeout \\ :infinity)

  def scan_ip(<< 1, 2, 3, 4 >>, 1337, _), do: :open
  def scan_ip(<< 1, 2, 3, 42 >>, 1337, _), do: :open

  def scan_ip(<< 1, 2, 3, 42 >> , 22, _), do: :open
  def scan_ip(<< 1, 2, 3, 42 >> , 80, _), do: :open
  def scan_ip(<< 1, 2, 3, 43 >> , 80, _), do: :open
  def scan_ip(<< 1, 2, 3, 44 >> , 4369, _), do: :open

  def scan_ip(_ip, _port, _timeout), do: :closed
end

