defmodule Server.Application do
  use Application

  def start(_type, _args) do
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

