defmodule Scanner.Worker do
  @scan_client Application.get_env(:server, :scan_client)

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

