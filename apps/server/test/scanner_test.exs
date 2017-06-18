defmodule ScannerTest do
  use ExUnit.Case

  test "Port 5000 is opened" do
    assert Server.Scanner.scan('localhost', 5000) == :open
  end

  test "Port 1337 is closed" do
    assert Server.Scanner.scan('localhost', 1337) == :closed
  end

  test "Unreachable ip has closed port" do
    assert Server.Scanner.scan('whatdomain?!?', 123, 100) == :closed
  end
end

