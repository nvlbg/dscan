defmodule TestHandler do
  use GenEvent

  def handle_event({ip, port}, {:working, found}) do
    {:ok, {:working, [{ip, port} | found]}}
  end

  def handle_event(:done, {:working, found}) do
    {:ok, {:done, found}}
  end

  def handle_call(:get, {:done, found}) do
    {:ok, Enum.reverse(found), {:done, found}}
  end
end

defmodule ScannerTest do
  use ExUnit.Case

  test "Port 1337 on 1.2.3.4 is opened" do
    host = Network.new("1.2.3.4")
    {:ok, manager} = GenEvent.start_link

    # TODO: why is getting a stream not working?
    # stream = GenEvent.stream(manager, timeout: 1000) |> Stream.take_while(&(&1 != :done))
    GenEvent.add_handler(manager, TestHandler, {:working, []})
    Scanner.Service.scan(manager, host, [1337])

    # give the scanner/handler time to scan
    Process.sleep(10)

    opened = GenEvent.call(manager, TestHandler, :get)

    assert opened == [{<< 1, 2, 3, 4 >>, 1337}]
  end

  test "Can scan a network" do
    net = Network.new("1.2.3.4/24")
    {:ok, manager} = GenEvent.start_link

    GenEvent.add_handler(manager, TestHandler, {:working, []})

    Scanner.Service.scan(manager, net, [1337])

    # give the scanner/handler time to scan
    Process.sleep(10)

    opened = GenEvent.call(manager, TestHandler, :get)

    assert opened == [{<< 1, 2, 3, 4 >>, 1337},
                      {<< 1, 2, 3, 42 >>, 1337}]
  end
end

