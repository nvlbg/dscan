defmodule ParserTest do
  use ExUnit.Case

  test "Can parse port" do
    assert {[port: 22], [], []} = \
      Parser.parse_args ~w(--port 22)
  end

  test "Can parse ports" do
    assert {[ports: "22,4369"], [], []} = \
      Parser.parse_args ~w(--ports 22,4369)
  end

  test "Can parse all ports" do
    assert {[all_ports: true], [], []} = \
      Parser.parse_args ~w(--all-ports)
  end

  test "Can parse server" do
    assert {[server: "1.2.3.4"], [], []} = \
      Parser.parse_args ~w(--server 1.2.3.4)
  end

  test "Can parse certificates" do
    assert {[certfile: "a.pem", keyfile: "b.pem",
             cacertfile: "c.pem", key_password: "123456"], [], []} = \
      Parser.parse_args ~w(--certfile a.pem --keyfile b.pem
        --cacertfile c.pem --key-password 123456)
  end
end

