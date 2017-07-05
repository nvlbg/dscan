defmodule Client do
  @moduledoc """
  The client application is responsible for getting scan requests
  and sending them to a server (or a cluster of servers), where
  the actual scannig will happen. It also displays the result of
  the scan to the user.
  """

  @halt_mfa Application.get_env(:client, :halt_mfa)

  @doc """
  This function is called with the command line arguments

  It tries to parse them, validate them and sent a request to a server
  """
  def main(argv) do
    args = argv
    |> Parser.parse_args
    |> Validator.validate_args

    case args do
      {:ok, args} ->
        case Processor.send_request(args) do
          :ok -> :noop
          {:error, reason} ->
            IO.puts(:stderr, reason)
            halt(1)
        end
      {:error, reason} ->
        IO.puts(:stderr, reason)
        halt(1)
    end
  end

  defp halt(code) do
    {mod, func, []} = @halt_mfa
    apply(mod, func, [code])
  end
end

