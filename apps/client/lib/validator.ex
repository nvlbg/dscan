defmodule Validator do
  @ip_port ~r/^((?:\d{1,2}|1\d{2}|2[0-4]\d|25[0-5])\.
                (?:\d{1,2}|1\d{2}|2[0-4]\d|25[0-5])\.
                (?:\d{1,2}|1\d{2}|2[0-4]\d|25[0-5])\.
                (?:\d{1,2}|1\d{2}|2[0-4]\d|25[0-5])):
                (\d{1,5})$/x

  @ip_mask ~r/^((?:\d{1,2}|1\d{2}|2[0-4]\d|25[0-5])\.
                (?:\d{1,2}|1\d{2}|2[0-4]\d|25[0-5])\.
                (?:\d{1,2}|1\d{2}|2[0-4]\d|25[0-5])\.
                (?:\d{1,2}|1\d{2}|2[0-4]\d|25[0-5]))
                (?:\/(\d|[12]\d|3[0-2]))?$/x

  @ports ~r/^\d+(,\d+)*$/

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

    if !File.exists?(certfile) do
      Client.halt(1, "Certificate file #{certfile} does not exist")
    end

    if !File.exists?(keyfile) do
      Client.halt(1, "Key file #{keyfile} does not exist")
    end

    if !File.exists?(cacertfile) do
      Client.halt(1, "CA certificate file #{cacertfile} does not exist")
    end

    # Validate targets
    if List.first(targets) == nil do # no targets given
      Client.halt(1, "No targets given")
    end

    Enum.each(targets, fn target ->
      if !Regex.match?(@ip_mask, target) do
        Client.halt(1, "Invalid target: #{target}")
      end
    end)

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
    Enum.each(invalid, fn {option, _} ->
      IO.puts(:stderr, "Unknown option or invalid value: #{option}")
    end)
    Client.halt(1)
  end

  defp get_ports(port, nil, nil), do: [port]
  defp get_ports(nil, ports, nil) do 
    if !Regex.match?(@ports, ports) do
      Client.halt(1, "Invalid ports given")
    end

    ports
    |> String.split(",")
    |> Enum.map(&String.to_integer/1)
  end
  defp get_ports(nil, nil, true), do: :all
  defp get_ports(_, _, _) do
    Client.halt(1, "More than one type of port scanning given")
  end

  defp parse_ip(server) do
    case Regex.run(@ip_port, server) do
      [_, ip, port] ->
        {ip, port |> String.to_integer}
      _ ->
        Client.halt(1, "Invalid server given: #{server}. Expected format is ip:port")
    end
  end
end

