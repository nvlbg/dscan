defmodule Server.Scanner do
  use GenServer

  @scan_client Application.get_env(:server, :scan_client)

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{}}
  end

  def handle_info({_ref, {ref, pid, ip, port, status}}, state) do
    if status == :open do
      GenEvent.notify(pid, {ip, port})
    end

    tasks_left = Map.get(state, ref) - 1

    if tasks_left > 0 do
      {:noreply, Map.put(state, ref, tasks_left)}
    else
      GenEvent.notify(pid, :done)
      {:noreply, Map.delete(state, ref)}
    end
  end

  def handle_info({:DOWN, _ref, :process, _pid, _status}, state) do
    {:noreply, state}
  end

  def handle_call({:scan, manager, network, ports, timeout}, {_pid, ref}, state) do
    network
    |> Network.ips()
    |> Stream.each(fn ip ->
      for port <- ports do
        Task.Supervisor.async_nolink(
          Server.ScanSupervisor,
          fn ->
            {ref, manager, ip, port, @scan_client.scan_ip(ip, port, timeout)}
          end
        )
      end
    end)
    |> Stream.run

    total_tasks = Network.total_ips(network) * Enum.count(ports)

    {:reply, nil, Map.put(state, ref, total_tasks)}
  end

  def scan(manager, network, ports, timeout \\ :infinity) do
    GenServer.call(__MODULE__, {:scan, manager, network, ports, timeout})
  end
end

