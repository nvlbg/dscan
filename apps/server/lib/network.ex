defmodule Network do
  @moduledoc """
  A struct representing a set of IP addresses
  """

  defstruct [:first_ip, :last_ip, :mask]

  @ip_mask ~r/^((?:\d{1,2}|1\d{2}|2[0-4]\d|25[0-5])\.
                (?:\d{1,2}|1\d{2}|2[0-4]\d|25[0-5])\.
                (?:\d{1,2}|1\d{2}|2[0-4]\d|25[0-5])\.
                (?:\d{1,2}|1\d{2}|2[0-4]\d|25[0-5]))
                (?:\/(\d|[12]\d|3[0-2]))?$/x

  @doc """
  Creates a new Network

  `network` is a string in the format a.b.c.d or a.b.c.d/mask

  ## Examples

    iex> Network.new("8.8.8.8")
    %Network{first_ip: <<8, 8, 8, 8>>, last_ip: <<8, 8, 8, 8>>, mask: 32}

    iex> Network.new("192.168.0.0/24")
    %Network{first_ip: <<192, 168, 0, 0>>, last_ip: <<192, 168, 0, 255>>,
      mask: 24}
  """
  def new(network) do
    case Regex.run(@ip_mask, network) do
      [_, ip] ->
        ip_binary = ip_to_binary(ip)
        %Network{first_ip: ip_binary, last_ip: ip_binary, mask: 32}
      [_, ip, mask] ->
        mask = mask |> String.to_integer
        {first, last} = ip_to_binary(ip, mask)
        %Network{first_ip: first, last_ip: last, mask: mask}
    end
  end

  defp ip_to_binary(ip) do
    ip
    |> String.split(".")
    |> Enum.map(&String.to_integer/1)
    |> Enum.reduce(<<>>, fn octet, acc -> acc <> << octet >> end)
  end

  defp ip_to_binary(ip, mask) do
    host = 32 - mask
    << net::size(mask), _::size(host) >> = ip_to_binary(ip)
    first_ip = << net::size(mask),  0::size(host) >>
    last_ip  = << net::size(mask), -1::size(host) >>
    {first_ip, last_ip}
  end

  @doc """
  Splits the network into n networks if possible

  ## Examples

    iex> net = Network.new("192.168.0.0/24")
    iex> Network.partition(net, 2)
    [%Network{first_ip: <<192, 168, 0, 0>>, last_ip: <<192, 168, 0, 127>>,
      mask: 24},
     %Network{first_ip: <<192, 168, 0, 128>>, last_ip: <<192, 168, 0, 255>>,
      mask: 24}]

    iex> net = Network.new("8.8.8.8")
    iex> Network.partition(net, 1000)
    [%Network{first_ip: <<8, 8, 8, 8>>, last_ip: <<8, 8, 8, 8>>, mask: 32}]
  """
  def partition(%Network{first_ip: first, last_ip: last, mask: mask}, n) do
    host = 32 - mask
    << net::size(mask),  lower::size(host) >> = first
    << ^net::size(mask), upper::size(host) >> = last

    n = min(n, upper - lower + 1)

    interval = div(upper - lower + 1, n)
    remaining = rem(upper - lower + 1, n)

    subnetworks = if remaining > 0 do
      0..remaining-1
      |> Stream.map(fn x ->
        first_ip = << net::size(mask), (lower + x * (interval + 1))::size(host) >>
        last_ip  = << net::size(mask), (lower + (x + 1) * (interval + 1) - 1)::size(host) >>
        %Network{first_ip: first_ip, last_ip: last_ip, mask: mask}
      end)
      |> Enum.into([])
    else
      []
    end

    remaining..n-1
    |> Stream.map(fn x ->
      first_ip = << net::size(mask),
                    (lower + remaining * (interval + 1) + (x - remaining) * interval)::size(host) >>
      last_ip  = << net::size(mask),
                    (lower + remaining * (interval + 1) + (x + 1 - remaining) * interval - 1)::size(host) >>
      %Network{first_ip: first_ip, last_ip: last_ip, mask: mask}
    end)
    |> Enum.into(subnetworks)
  end

  @doc """
  Creates a stream of the IP addresses in the network. Each ip is represented as a binary.

  ## Examples

    iex> net = Network.new("192.168.0.0/24")
    iex> Network.ips(net) |> Stream.take(4) |> Enum.to_list
    [<<192, 168, 0, 0>>, <<192, 168, 0, 1>>, <<192, 168, 0, 2>>, <<192, 168, 0, 3>>]
  """
  def ips(%Network{first_ip: first, last_ip: last, mask: mask}) do
    host = 32 - mask
    << net::size(mask),  lower::size(host) >> = first
    << ^net::size(mask), upper::size(host) >> = last

    lower..upper
    |> Stream.map(&<< net::size(mask), &1::size(host) >>)
  end

  @doc """
  Returns the number of ips in the network

  ## Examples

    iex> Network.total_ips(Network.new("1.2.3.4"))
    1

    iex> Network.total_ips(Network.new("192.168.0.0/16"))
    65536
  """
  def total_ips(%Network{first_ip: first, last_ip: last, mask: mask}) do
    host = 32 - mask
    << net::size(mask),  lower::size(host) >> = first
    << ^net::size(mask), upper::size(host) >> = last

    upper - lower + 1
  end
end

