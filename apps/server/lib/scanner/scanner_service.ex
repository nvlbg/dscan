defmodule Scanner.Service do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    {:ok, nil}
  end

  def handle_info({_ref, _result}, _state) do
    {:noreply, nil}
  end

  def handle_info({:DOWN, _ref, :process, _pid, _status}, _state) do
    {:noreply, nil}
  end

  def handle_call({:scan, manager, network, ports, timeout}, _from, _state) do
    Task.Supervisor.async_nolink(
      :scan_supervisor,
      Scanner.Worker,
      :start,
      [manager, network, ports, timeout]
    )

    {:reply, nil, nil}
  end

  def scan(manager, network, ports, timeout \\ :infinity) do
    GenServer.call(__MODULE__, {:scan, manager, network, ports, timeout})
  end
end

