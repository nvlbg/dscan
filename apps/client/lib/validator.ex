defmodule Validator do
  def validate_args({parsed, targets, []}) do
    # Validate only one type of port scanning is requested
    port = parsed |> Keyword.get(:port)
    ports = parsed |> Keyword.get(:ports)
    all_ports = parsed |> Keyword.get(:all_ports)
    
    ports = get_ports(port, ports, all_ports)

    # Validate server
    server = parsed |> Keyword.get(:server, "127.0.0.1:5000")
    {server_ip, server_port} = parse_ip(server)

    # Get ssl files
    certfile = Keyword.get(parsed, :certfile, "cert.pem")
    keyfile = Keyword.get(parsed, :keyfile, "key.pem")
    cacertfile = Keyword.get(parsed, :cacertfile, "cacert.pem")
    key_password = Keyword.get(parsed, :key_password, "")

    # Validate targets
    # TODO

    %{:ports => ports,
      :targets => targets,
      :server_ip => server_ip,
      :server_port => server_port,
      :certfile => certfile,
      :keyfile => keyfile,
      :cacertfile => cacertfile,
      :key_password => key_password}
  end

  def validate_args({_, _, invalid}) do
    print_invalid_args(invalid)
  end

  defp print_invalid_args([{option, _} | tail]) do
    IO.puts(:stderr, "Unknown option or invalid value: #{option}")
    print_invalid_args(tail)
  end
  defp print_invalid_args([]), do: Client.halt(1)

  defp get_ports(port, nil, nil), do: [port]
  defp get_ports(nil, ports, nil) do 
    ports
    |> String.split(",")
    |> Enum.map(&String.to_integer/1)
  end
  defp get_ports(nil, nil, true), do: :all
  defp get_ports(_, _, _) do
    IO.puts(:stderr, "More than one type of port scanning given")
    Client.halt(1)
  end

  defp parse_ip(server) do
    case String.split(server, ":") do
      [ip, port] ->
        {ip, String.to_integer(port)}
      _ ->
        IO.puts(:stderr, "Invalid server given: #{server}. Expected format is ip:port")
        Client.halt(1)
    end
  end
end

