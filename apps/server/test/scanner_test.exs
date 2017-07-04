defmodule ScannerTest do
  use ExUnit.Case

  test "Port 1337 on 1.2.3.4 is opened" do
    host = Network.new("1.2.3.4")
    {:ok, manager} = GenEvent.start_link

    stream = GenEvent.stream(manager, timeout: 1000) |> Stream.take_while(&(&1 != :done))
    Scanner.Service.scan(node(), manager, host, [1337])

    assert Enum.to_list(stream) == [{<< 1, 2, 3, 4 >>, 1337}]
  end

  test "Can scan a network" do
    net = Network.new("1.2.3.4/24")
    {:ok, manager} = GenEvent.start_link

    stream = GenEvent.stream(manager, timeout: 1000) |> Stream.take_while(&(&1 != :done))
    Scanner.Service.scan(node(), manager, net, [1337])

    expected = [{<< 1, 2, 3, 4 >>, 1337},
                {<< 1, 2, 3, 42 >>, 1337}] |> MapSet.new

    assert MapSet.new(stream) == expected
  end

  test "Can scan multiple ports" do
    net = Network.new("1.2.3.4/24")
    {:ok, manager} = GenEvent.start_link

    stream = GenEvent.stream(manager, timeout: 1000) |> Stream.take_while(&(&1 != :done))
    Scanner.Service.scan(node(), manager, net, [22, 80, 4369])

    expected = [{<< 1, 2, 3, 42 >>, 22},
                {<< 1, 2, 3, 42 >>, 80},
                {<< 1, 2, 3, 43 >>, 80},
                {<< 1, 2, 3, 44 >>, 4369}] |> MapSet.new

    assert MapSet.new(stream) == expected
  end
end

