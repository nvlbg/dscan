defmodule Client do
  @halt_mfa Application.get_env(:client, :halt_mfa)

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

  def halt(code) do
    {mod, func, []} = @halt_mfa
    apply(mod, func, [code])
  end
end

