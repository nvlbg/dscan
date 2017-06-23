defmodule ClientTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  setup context do
    if certs = context[:certs] do
      Enum.map(certs, &File.touch!/1)
      on_exit fn -> Enum.map(certs, &File.rm!/1) end
    end

    :ok
  end

  test "Invalid options are detected" do
    assert run(~w(--invalid), 1) == \
      "Unknown option or invalid value: --invalid\n"
  end

  test "Giving non-numeric port fails" do
    assert run(~w(--port 21a), 1) == \
      "Unknown option or invalid value: --port\n"
  end

  test "Giving multiple ports with non-numeric ones fails" do
    assert run(~w(--ports 1,2,3,4a), 1) == \
      "Invalid ports given\n"
  end

  test "Giving more than one port options fails" do
    assert run(~w(--port 80 --all-ports), 1) == \
      "More than one type of port scanning given\n"
    assert run(~w(--ports 80,443 --all-ports), 1) == \
      "More than one type of port scanning given\n"
    assert run(~w(--port 80 --ports 22,80), 1) == \
      "More than one type of port scanning given\n"
    assert run(~w(--port 80 --ports 22,80 --all-ports), 1) == \
      "More than one type of port scanning given\n"
  end

  test "Giving invalid server fails" do
    assert run(~w(--port 22 --server 192.168.1.1), 1) == \
      "Invalid server given: 192.168.1.1. Expected format is ip:port\n"
    assert run(~w(--port 22 --server 300.168.1.1:1234), 1) == \
      "Invalid server given: 300.168.1.1:1234. Expected format is ip:port\n"
  end

  @tag certs: ["testcert.pem", "testkey.pem", "testcacert.pem"]
  test "Missing ssl files should stop execution" do
    assert run(~w(--port 22 --certfile missingcert.pem), 1) == \
      "Certificate file missingcert.pem does not exist\n"
    assert run(~w(--port 22 --certfile testcert.pem
                  --keyfile missingkey.pem), 1) == \
      "Key file missingkey.pem does not exist\n"
    assert run(~w(--port 22 --certfile testcert.pem
                  --keyfile testkey.pem
                  --cacertfile missingcacert.pem), 1) == \
      "CA certificate file missingcacert.pem does not exist\n"
  end

  @tag certs: ["testcert.pem", "testkey.pem", "testcacert.pem"]
  test "Not passing targets fails" do
    assert run(~w(--port 22 --certfile testcert.pem
                  --keyfile testkey.pem
                  --cacertfile testcacert.pem), 1) == \
      "No targets given\n"
  end

  @tag certs: ["testcert.pem", "testkey.pem", "testcacert.pem"]
  test "Giving invalid target/targets fails" do
    assert run(~w(--port 22 --certfile testcert.pem
                  --keyfile testkey.pem
                  --cacertfile testcacert.pem
                  100.200.300.400), 1) == \
      "Invalid target: 100.200.300.400\n"
    assert run(~w(--port 22 --certfile testcert.pem
                  --keyfile testkey.pem
                  --cacertfile testcacert.pem
                  target), 1) == \
      "Invalid target: target\n"
    assert run(~w(--port 22 --certfile testcert.pem
                  --keyfile testkey.pem
                  --cacertfile testcacert.pem
                  8.8.8.8/24 9.9.9.9/33), 1) == \
      "Invalid target: 9.9.9.9/33\n"
  end

  defp run(args, expected_code) do
    capture_io(:stderr, fn ->
      {pid, ref} = spawn_monitor(Client, :main, [args])

      assert_receive {:DOWN, ^ref, :process, ^pid, ^expected_code}
    end)
  end
end

