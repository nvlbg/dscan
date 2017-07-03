defmodule ValidatorTest do
  use ExUnit.Case

  setup context do
    if files = context[:touch] do
      Enum.map(files, &File.touch!/1)
      on_exit fn -> Enum.map(files, &File.rm!/1) end
    end

    :ok
  end

  describe "&Validator.validate_ports/1" do
    test "--port option works" do
      args = Parser.parse_args ~w(--port 22)
      assert {:ok, [22]} == Validator.validate_ports(args)

      args = Parser.parse_args ~w(--port 1337)
      assert {:ok, [1337]} == Validator.validate_ports(args)
    end
    
    test "--ports option works" do
      args = Parser.parse_args ~w(--ports 22,80,1337)
      assert {:ok, [22, 80, 1337]} == Validator.validate_ports(args)

      args = Parser.parse_args ~w(--ports 443)
      assert {:ok, [443]} == Validator.validate_ports(args)

      args = Parser.parse_args ~w(--ports 443,80a)
      assert {:error, "Invalid ports given"} == Validator.validate_ports(args)
    end

    test "--all-ports option works" do
      args = Parser.parse_args ~w(--all-ports)
      assert {:ok, :all} == Validator.validate_ports(args)
    end

    test "both --port and --ports should return error" do
      args = Parser.parse_args ~w(--port 22 --ports 80,443)
      assert {:error, "Both --port and --ports given"} == \
        Validator.validate_ports(args)
    end

    test "both --port and --all-ports should return error" do
      args = Parser.parse_args ~w(--port 22 --all-ports)
      assert {:error, "Both --port and --all-ports given"} == \
        Validator.validate_ports(args)
    end

    test "both --ports and --all-ports should return error" do
      args = Parser.parse_args ~w(--ports 80,443 --all-ports)
      assert {:error, "Both --ports and --all-ports given"} == \
        Validator.validate_ports(args)
    end

    test "all --port --ports and --all-ports should return error" do
      args = Parser.parse_args ~w(--port 22 --ports 80,443 --all-ports)
      assert {:error, "Each of --port --ports and --all-ports given"} == \
        Validator.validate_ports(args)
    end
  end

  describe "&Validator.validate_server/1" do
    test "Server defaults to 127.0.0.1:5000" do
      args = Parser.parse_args ~w()
      assert {:ok, {"127.0.0.1", 5000}} == Validator.validate_server(args)
    end

    test "Valid servers should be ok" do
      args = Parser.parse_args ~w(--server 192.168.1.100:1337)
      assert {:ok, {"192.168.1.100", 1337}} == Validator.validate_server(args)

      args = Parser.parse_args ~w(--server 42.42.42.42:42)
      assert {:ok, {"42.42.42.42", 42}} == Validator.validate_server(args)
    end

    test "Invalid servers should return error" do
      args = Parser.parse_args ~w(--server 256.10.1.100:1337)
      assert {:error, "Invalid server given: 256.10.1.100:1337. Expected format is ip:port"} == \
        Validator.validate_server(args)

      args = Parser.parse_args ~w(--server wrongwrongwrong)
      assert {:error, "Invalid server given: wrongwrongwrong. Expected format is ip:port"} == \
        Validator.validate_server(args)
    end
  end

  describe "&Validator.validate_certificates/1" do
    test "Passing unexisting certificate gives error" do
      args = Parser.parse_args ~w()
      assert {:error, "Certificate file cert.pem does not exist"} == \
        Validator.validate_certificates(args)

      args = Parser.parse_args ~w(--certfile unknown.pem)
      assert {:error, "Certificate file unknown.pem does not exist"} == \
        Validator.validate_certificates(args)
    end

    @tag touch: ["cert.pem"]
    test "Passing unexisting key gives error" do
      args = Parser.parse_args ~w()
      assert {:error, "Key file key.pem does not exist"} == \
        Validator.validate_certificates(args)

      args = Parser.parse_args ~w(--keyfile unknown.key)
      assert {:error, "Key file unknown.key does not exist"} == \
        Validator.validate_certificates(args)
    end

    @tag touch: ["cert.pem", "key.pem"]
    test "Passing unexisting CA certificate gives error" do
      args = Parser.parse_args ~w()
      assert {:error, "CA certificate file cacert.pem does not exist"} == \
        Validator.validate_certificates(args)

      args = Parser.parse_args ~w(--cacertfile unknown.pem)
      assert {:error, "CA certificate file unknown.pem does not exist"} == \
        Validator.validate_certificates(args)
    end

    @tag touch: ["cert.pem", "key.pem", "cacert.pem"]
    test "Passing valid files should work" do
      args = Parser.parse_args ~w()
      assert {:ok, {"cert.pem", "key.pem", "cacert.pem", ""}} == \
        Validator.validate_certificates(args)

      args = Parser.parse_args ~w(--key-password 123456)
      assert {:ok, {"cert.pem", "key.pem", "cacert.pem", "123456"}} == \
        Validator.validate_certificates(args)
    end
  end

  describe "&Validator.validate_targets/1" do
    test "Not passing targets gives error" do
      args = Parser.parse_args ~w()
      assert {:error, "No targets given"} == Validator.validate_targets(args)
    end

    test "Passing single valid target should work" do
      args = Parser.parse_args ~w(10.20.30.40/8)
      assert {:ok, ["10.20.30.40/8"]} == Validator.validate_targets(args)

      args = Parser.parse_args ~w(8.8.8.8)
      assert {:ok, ["8.8.8.8"]} == Validator.validate_targets(args)
    end

    test "Passing multiple valid targets should work" do
      args = Parser.parse_args ~w(10.20.30.40/8 8.8.8.8 192.168.0.0/24)
      assert {:ok, ~w(10.20.30.40/8 8.8.8.8 192.168.0.0/24)} == \
        Validator.validate_targets(args)
    end

    test "Passing single invalid target should give error" do
      args = Parser.parse_args ~w(invalid)
      assert {:error, "Invalid target: invalid"} == \
        Validator.validate_targets(args)

      args = Parser.parse_args ~w(100.200.300.400/24)
      assert {:error, "Invalid target: 100.200.300.400/24"} == \
        Validator.validate_targets(args)

      args = Parser.parse_args ~w(8.8.8.8/33)
      assert {:error, "Invalid target: 8.8.8.8/33"} == \
        Validator.validate_targets(args)
    end

    test "Passing multiple invalid targets should give error" do
      args = Parser.parse_args ~w(8.8.8.8 invalid)
      assert {:error, "Invalid target: invalid"} == \
        Validator.validate_targets(args)
      
      args = Parser.parse_args ~w(invalid 256.256.256.256)
      assert {:error, "Invalid target: invalid"} == \
        Validator.validate_targets(args)

      args = Parser.parse_args ~w(256.256.256.256 invalid)
      assert {:error, "Invalid target: 256.256.256.256"} == \
        Validator.validate_targets(args)
    end
  end

  describe "&Validator.validate_args/1" do
    test "Passing invalid options should give error" do
      args = Parser.parse_args ~w(--invalid)
      assert {:error, "Invalid option --invalid"} == \
        Validator.validate_args(args)
    end

    @tag touch: ["cert.pem", "key.pem", "cacert.pem"]
    test "Passing valid options should work" do
      args = Parser.parse_args ~w(--port 22 192.168.1.0/24)
      assert {:ok, %{
        :ports => [22],
        :targets => ["192.168.1.0/24"],
        :server_ip => "127.0.0.1",
        :server_port => 5000,
        :certfile => "cert.pem",
        :keyfile => "key.pem",
        :cacertfile => "cacert.pem",
        :key_password => ""
      }} == Validator.validate_args(args)
    end

    test "Passing wrong ports should give error" do
      args = Parser.parse_args ~w(--port 22 --ports 80,443)
      assert {:error, "Both --port and --ports given"} == \
        Validator.validate_args(args)
    end
  end
end

