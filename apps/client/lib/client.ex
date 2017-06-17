defmodule Client do
  def main(argv) do
    argv
    |> parse_args
    |> Validator.validate_args
    |> process
  end

  defp parse_args(argv) do
    OptionParser.parse(argv, strict: [
      port: :integer,
      ports: :string,
      all_ports: :boolean,
      server: :string,
      certfile: :string,
      keyfile: :string,
      cacertfile: :string,
      key_password: :string
    ])
  end

  defp process(args) do
    server_ip = args |> Map.get(:server_ip)
    server_port = args |> Map.get(:server_port)

    certfile = args |> Map.get(:certfile)
    keyfile = args |> Map.get(:keyfile)
    cacertfile = args |> Map.get(:cacertfile)
    key_password = args |> Map.get(:key_password)

    targets = args |> Map.get(:targets)
    ports = args |> Map.get(:ports)

    case :ssl.start() do
      {:error, reason} ->
        IO.puts(:stderr, "Could not start ssl module: #{reason}")
        halt(1)
      _ -> :noop
    end

    conn = :ssl.connect(
      server_ip |> to_charlist,
      server_port,
      [
        :binary,
        certfile: certfile |> to_charlist,
        keyfile: keyfile |> to_charlist,
        cacertfile: cacertfile |> to_charlist,
        password: key_password |> to_charlist,
        active: false
      ]
    )

    case conn do
      {:ok, socket} ->
        msg = Poison.encode!(%{"targets" => targets, "ports" => ports})
        :ok = :ssl.send(socket, msg)
        {:ok, data} = :ssl.recv(socket, 0)
        IO.puts "Recieved line: #{data}"
    :ok = :ssl.close(socket)
      {:error, reason} ->
        IO.puts(:stderr, "Could not connect to server: #{reason}")
        halt(1)
    end
  end

  def halt(code), do: Process.exit(self(), code)
end

