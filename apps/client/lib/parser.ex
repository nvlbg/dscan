defmodule Parser do
  def parse_args(argv) do
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

