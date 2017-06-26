defmodule NetworkTest do
  use ExUnit.Case

  test "Can create network" do
    net = Network.new("192.168.1.1/24")

    assert net.first_ip == << 192, 168, 1, 0 >>
    assert net.last_ip == << 192, 168, 1, 255 >>
    assert net.mask == 24
  end

  test "Can create a single ip network" do
    net = Network.new("8.8.8.8")

    assert net.first_ip == << 8, 8, 8, 8 >>
    assert net.last_ip == << 8, 8, 8, 8 >>
    assert net.mask == 32
  end

  test "Can partition network" do
    net = Network.new("192.168.1.1/24")

    [first, second] = Network.partition(net, 2)
    
    assert first.first_ip == << 192, 168, 1, 0 >>
    assert first.last_ip == << 192, 168, 1, 127 >>
    assert first.mask == 24

    assert second.first_ip == << 192, 168, 1, 128 >>
    assert second.last_ip == << 192, 168, 1, 255 >>
    assert second.mask == 24
  end

  test "Single ip is not partitioned" do
    ip = Network.new("1.2.3.4")

    assert Network.partition(ip, 1) == [ip]
    assert Network.partition(ip, 2) == [ip]
    assert Network.partition(ip, 100) == [ip]
  end

  test "Partitioning works when network is not exact multiple" do
    net = Network.new("1.2.3.4/29")

    [first, second, third] = Network.partition(net, 3)

    assert first.first_ip == << 1, 2, 3, 0 >>
    assert first.last_ip == << 1, 2, 3, 2 >>
    assert first.mask == 29

    assert second.first_ip == << 1, 2, 3, 3 >>
    assert second.last_ip == << 1, 2, 3, 5 >>
    assert second.mask == 29

    assert third.first_ip == << 1, 2, 3, 6 >>
    assert third.last_ip == << 1, 2, 3, 7 >>
    assert third.mask == 29

    [first, second, third, fourth, fifth] = \
      Network.partition(net, 5)

    assert first.first_ip == << 1, 2, 3, 0 >>
    assert first.last_ip == << 1, 2, 3, 1 >>
    assert first.mask == 29

    assert second.first_ip == << 1, 2, 3, 2 >>
    assert second.last_ip == << 1, 2, 3, 3 >>
    assert second.mask == 29

    assert third.first_ip == << 1, 2, 3, 4 >>
    assert third.last_ip == << 1, 2, 3, 5 >>
    assert third.mask == 29

    assert fourth.first_ip == << 1, 2, 3, 6 >>
    assert fourth.last_ip == << 1, 2, 3, 6 >>
    assert fourth.mask == 29

    assert fifth.first_ip == << 1, 2, 3, 7 >>
    assert fifth.last_ip == << 1, 2, 3, 7 >>
    assert fifth.mask == 29
  end

  test "Partitioning into more subnets than available ips" do
    net = Network.new("8.8.8.8/28")

    assert Enum.count(Network.partition(net, 32)) == 16
    assert Enum.count(Network.partition(net, 17)) == 16
    assert Enum.count(Network.partition(net, 16)) == 16
  end

  test "Can stream ips" do
    net = Network.new("1.2.3.4/30")

    [a, b, c, d] = Network.ips(net) |> Enum.to_list

    assert a == << 1, 2, 3, 4 >>
    assert b == << 1, 2, 3, 5 >>
    assert c == << 1, 2, 3, 6 >>
    assert d == << 1, 2, 3, 7 >>
  end

  test "Can stream single ip" do
    ip = Network.new("1.2.3.4")

    assert [<< 1, 2, 3, 4 >>] == Network.ips(ip) |> Enum.to_list
  end

  test "Can get total ips in a network" do
    assert Network.new("1.2.3.4") |> Network.total_ips == 1
    assert Network.new("1.2.3.4/24") |> Network.total_ips == 256

    net = Network.new("1.2.3.4/29")

    [first, second, third] = Network.partition(net, 3)

    assert Network.total_ips(first) == 3
    assert Network.total_ips(second) == 3
    assert Network.total_ips(third) == 2
  end
end

