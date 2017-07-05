defmodule Parser do
  @moduledoc """
  A module for parsing cli options
  """

  @doc """
  Parses an argv list into a keyword list

  Returns {parsed, argv, invalid} according to `OptionParser.parse/2`
  """
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

