defmodule Validator do
  @moduledoc """
  A module for validating command line options
  """

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

  @doc """
  Validates all passed options according to specification

  Returns {:ok, options} if every option is valid
  Returns {:error, reason} if an option is invalid
  """
  def validate_args({_parsed, _targets, []} = args) do
    with {:ok, ports} <- validate_ports(args),
         {:ok, {server, port}} <- validate_server(args),
         {:ok, {cert, key, cacert, pass}} <- validate_certificates(args),
         {:ok, targets} <- validate_targets(args),
      do: {:ok, %{
        :ports => ports,
        :targets => targets,
        :server_ip => server,
        :server_port => port,
        :certfile => cert,
        :keyfile => key,
        :cacertfile => cacert,
        :key_password => pass
      }}
  end

  def validate_args({_, _, [{option, _} | _]}) do
    {:error, "Invalid option #{option}"}
  end

  @doc """
  Validates the --port --ports and --all-ports options

  Only one of the 3 options should be passed
  """
  def validate_ports({parsed, _targets, []}) do
    port      = parsed |> Keyword.get(:port)
    ports     = parsed |> Keyword.get(:ports)
    all_ports = parsed |> Keyword.get(:all_ports)

    case {port, ports, all_ports} do
      {port, nil, nil} -> {:ok, [port]}
      {nil, ports, nil} ->
        if !Regex.match?(@ports, ports) do
          {:error, "Invalid ports given"}
        else
          ports = ports
          |> String.split(",")
          |> Enum.map(&String.to_integer/1)

          {:ok, ports}
        end
      {nil, nil, true} -> {:ok, :all}
      {_, _, nil} -> {:error, "Both --port and --ports given"}
      {_, nil, _} -> {:error, "Both --port and --all-ports given"}
      {nil, _, _} -> {:error, "Both --ports and --all-ports given"}
      _ -> {:error, "Each of --port --ports and --all-ports given"}
    end
  end

  @doc """
  Validates the --server option which should be in the format ip:port

  If no --server option is passed it defaults to 127.0.0.1:5000
  """
  def validate_server({parsed, _targets, []}) do
    server = parsed |> Keyword.get(:server, "127.0.0.1:5000")
    case Regex.run(@ip_port, server) do
      [_, ip, port] ->
        {:ok, {ip, String.to_integer(port)}}
      _ ->
        {:error, "Invalid server given: #{server}. Expected format is ip:port"}
    end
  end

  @doc """
  Checks if passed --certfile --keyfile and --cacertfile exist

  If an option is not passed, they default to cert.pem, key.pem
  and cacert.pem respectively
  """
  def validate_certificates({parsed, _targets, []}) do
    certfile     = Keyword.get(parsed, :certfile,     "cert.pem")
    keyfile      = Keyword.get(parsed, :keyfile,      "key.pem")
    cacertfile   = Keyword.get(parsed, :cacertfile,   "cacert.pem")
    key_password = Keyword.get(parsed, :key_password, "")

    case Enum.map([certfile, keyfile, cacertfile], &File.exists?/1) do
      [false, _, _] ->
        {:error, "Certificate file #{certfile} does not exist"}
      [true, false, _] ->
        {:error, "Key file #{keyfile} does not exist"}
      [true, true, false] ->
        {:error, "CA certificate file #{cacertfile} does not exist"}
      _ ->
        {:ok, {certfile, keyfile, cacertfile, key_password}}
    end
  end

  @doc """
  Validates that at least one target is passed and that
  targets are of required format ip or ip/mask
  """
  def validate_targets({_parsed, [], []}), do: {:error, "No targets given"}
  def validate_targets({_parsed, targets, []}) do
    case Enum.find(targets, &(!Regex.match?(@ip_mask, &1))) do
      nil -> {:ok, targets}
      invalid -> {:error, "Invalid target: #{invalid}"}
    end
  end
end

