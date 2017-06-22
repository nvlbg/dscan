defmodule Client do
  def main(argv) do
    argv
    |> parse_args
    |> Validator.validate_args
    |> Processor.send_request
  end

  def halt(code), do: Process.exit(self(), code)
  def halt(code, msg) do
    IO.puts(:stderr, msg)
    Process.exit(self(), code)
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
end

