defmodule Server.Application do
  @moduledoc """
  The server application is responsible for getting requests
  from the client application and perform the actual scanning of
  the targets. If it is connected to other servers, it will distribute
  the work among all of them
  """
  use Application

  def start(_type, _args) do
    # Connect to peers in the cluster
    if File.exists?("nodes.txt") do
      File.stream!("nodes.txt")
      |> Stream.map(&String.trim/1)
      |> Stream.filter(&(&1 != ""))
      |> Stream.map(&String.to_atom/1)
      |> Stream.each(&Node.ping/1)
      |> Stream.run
    end

    import Supervisor.Spec, warn: false

    port         = System.get_env() |> Map.get("PORT", "5000") |> String.to_integer
    key_password = System.get_env() |> Map.get("KEY_PASSWORD", "") |> to_charlist

    children = [
      supervisor(Task.Supervisor, [[name: :request_supervisor]], [id: :request_supervisor]),
      worker(Task, [Server.TaskAcceptor, :accept, [port, key_password]]),
      supervisor(Task.Supervisor, [[name: :scan_supervisor]], [id: :scan_supervisor]),
      worker(Scanner.Service, [])
    ]

    opts = [strategy: :one_for_one, name: Server.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

