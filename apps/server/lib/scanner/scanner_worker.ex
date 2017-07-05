defmodule Scanner.Worker do
  @moduledoc """
  This module provides functionality to scan networks
  """

  @scan_client Application.get_env(:server, :scan_client)

  @doc """
  Starts a scan for the IP addresses in `network`

  `manager` is an event manager through which found targets will be notified to the caller
  `network` is a Network struct representing the IP addresses which will be scanned
  `ports` is a list of ports to be scanned
  `timeout` is the maximum time to wait before considering a target port closed
  """
  def start(manager, network, ports, timeout) do
    task_timeout = if timeout == :infinity do
      :infinity
    else
      timeout + 1000
    end

    Task.Supervisor.async_stream(
      :scan_supervisor,
      cartesian_product(Network.ips(network), ports),
      fn {ip, port} ->
        if @scan_client.scan_ip(ip, port, timeout) == :open do
          GenEvent.notify(manager, {ip, port})
        end
      end,
      [max_concurrency: 256, timeout: task_timeout]
    )
    |> Stream.run

    GenEvent.notify(manager, :done)
  end

  defp cartesian_product(left, right) do
    left
    |> Stream.map(&(Stream.cycle([&1]) |> Stream.zip(right)))
    |> Stream.concat
  end
end

