defmodule ScannerTest do
  use ExUnit.Case

  test "Port 1337 on 1.2.3.4 is opened" do
    host = Network.new("1.2.3.4")
    {:ok, manager} = GenEvent.start_link

    stream = GenEvent.stream(manager, timeout: 1000) |> Stream.take_while(&(&1 != :done))
    Scanner.Service.scan(manager, host, [1337])

    assert Enum.to_list(stream) == [{<< 1, 2, 3, 4 >>, 1337}]
  end

  test "Can scan a network" do
    net = Network.new("1.2.3.4/24")
    {:ok, manager} = GenEvent.start_link

    stream = GenEvent.stream(manager, timeout: 1000) |> Stream.take_while(&(&1 != :done))
    Scanner.Service.scan(manager, net, [1337])

    assert Enum.to_list(stream) == [{<< 1, 2, 3, 4 >>, 1337},
                                    {<< 1, 2, 3, 42 >>, 1337}]
  end
end

