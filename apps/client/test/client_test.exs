defmodule ClientTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "Invalid options are detected" do
    assert capture_io(:stderr, fn ->
      {pid, ref} = spawn_monitor(Client, :main, [~w(--invalid)])

      assert_receive {:DOWN, ^ref, :process, ^pid, 1}
    end) == "Unknown option or invalid value: --invalid\n"
  end

  test "Giving non-numeric port fails" do
    assert capture_io(:stderr, fn ->
      {pid, ref} = spawn_monitor(Client, :main, [~w(--port 21a)])

      assert_receive {:DOWN, ^ref, :process, ^pid, 1}
    end) == "Unknown option or invalid value: --port\n"
  end
end

