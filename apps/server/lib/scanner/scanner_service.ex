defmodule Scanner.Service do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{}}
  end

  def handle_info({_ref, _result}, tasks) do
    {:noreply, tasks}
  end

  def handle_info({:DOWN, ref, :process, _pid, _status}, tasks) do
    {:noreply, Map.delete(tasks, ref)}
  end

  def handle_call({:scan, manager, network, ports, timeout}, _from, tasks) do
    task = Task.Supervisor.async_nolink(
      :scan_supervisor,
      Scanner.Worker,
      :start,
      [manager, network, ports, timeout]
    )

    {:reply, task.ref, Map.put(tasks, task.ref, task)}
  end

  def handle_call({:stop, ref}, _from, tasks) do
    case Map.fetch(tasks, ref) do
      {:ok, task} ->
        Task.shutdown(task)
        {:reply, :ok, Map.delete(tasks, ref)}
      :error ->
        {:reply, :ok, tasks}
    end
  end

  def scan(node, manager, network, ports, timeout \\ :infinity) do
    GenServer.call({__MODULE__, node}, {:scan, manager, network, ports, timeout})
  end

  def stop(node, ref) do
    GenServer.call({__MODULE__, node}, {:stop, ref})
  end
end

