defmodule Scanner.Service do
  @moduledoc """
  This module provides an interface for starting scan requests
  """

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

  @doc """
  Starts a scan request

  `node` is the node on which the scanning should happen
  `manager` is an event manager through which found targets will be notified to the caller
  `network` is a Network struct representing the IP addresses which will be scanned
  `ports` is a list of ports to be scanned
  `timeout` is the maximum time to wait before considering a target port closed

  Returns a reference which can be used for stopping a scan in progress
  """
  def scan(node, manager, network, ports, timeout \\ :infinity) do
    GenServer.call({__MODULE__, node}, {:scan, manager, network, ports, timeout})
  end

  @doc """
  Stops a scan in progress

  `node` is the node on which the scanning is happening
  `ref` is a reference obtained by `scan/5`
  """
  def stop(node, ref) do
    GenServer.call({__MODULE__, node}, {:stop, ref})
  end
end

