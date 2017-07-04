defmodule ServerTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  setup_all do
    certs = ["cert.pem", "key.pem", "cacert.pem"]
    Enum.map(certs, &File.cp("test/support/#{&1}", &1))
    on_exit fn -> Enum.map(certs, &File.rm!/1) end

    :ok
  end

  test "Connections with proper certificate should proceed" do
    output = capture_log(fn ->
      {:ok, pid} = Task.start(
        Server.TaskAcceptor, :accept, [1337, 'elixir'])

      options = [
        :binary,
        certfile: 'cert.pem',
        keyfile: 'key.pem',
        cacertfile: 'cacert.pem',
        password: 'elixir',
        active: false
      ]

      assert {:ok, socket} = :ssl.connect('127.0.0.1', 1337, options)

      assert :ok == :ssl.close(socket)

      Process.exit(pid, :kill)
    end)

    assert output =~ "Accepting connections on port 1337"
    assert output =~ "Received a connection..."
    assert output =~ "Connection closed"
  end

  test "Setting up with wrong key password should crash" do
    output = capture_log(fn ->
      {:ok, pid} = Task.start(
        Server.TaskAcceptor, :accept, [1337, 'wrongpass'])

      options = [
        :binary,
        certfile: 'cert.pem',
        keyfile: 'key.pem',
        cacertfile: 'cacert.pem',
        password: 'elixir',
        active: false
      ]

      assert {:error, :closed} = :ssl.connect('127.0.0.1', 1337, options)

      ref = Process.monitor(pid)
      assert_receive {:DOWN, ^ref, _, _, _}

      Process.exit(pid, :kill)
    end)

    refute output =~ "Could not ssl accept"
  end

  test "Receiving a connection with wrong key password should fail" do
    output = capture_log(fn ->
      {:ok, pid} = Task.start(
        Server.TaskAcceptor, :accept, [1337, 'elixir'])

      options = [
        :binary,
        certfile: 'cert.pem',
        keyfile: 'key.pem',
        cacertfile: 'cacert.pem',
        password: 'wrongpass',
        active: false
      ]

      assert {:error, _} = :ssl.connect('127.0.0.1', 1337, options)

      ref = Process.monitor(pid)
      refute_receive {:DOWN, ^ref, _, _, _}

      Process.exit(pid, :kill)
    end)

    assert output =~ "Could not ssl accept"
  end
end

