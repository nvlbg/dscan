defmodule Server.Application do
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

    children = [
      supervisor(Task.Supervisor, [[name: :request_supervisor]], [id: :request_supervisor]),
      worker(Task, [Server.TaskAcceptor, :accept, []]),
      supervisor(Task.Supervisor, [[name: :scan_supervisor]], [id: :scan_supervisor]),
      worker(Scanner.Service, [])
    ]

    opts = [strategy: :one_for_one, name: Server.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

