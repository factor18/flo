defmodule Flo.Connection do
  @derive Jason.Encoder

  use Accessible

  use Construct do
    field(:source, :string)
    field(:destination, :string)
    field(:condition, Flo.Script, default: nil)
    field(:outcome, :string, default: "default")
  end

  def id(connection) do
    id(connection.source, connection.destination, connection.outcome)
  end

  def id(source, destination, outcome) do
    source <> "~>" <> destination <> "=>" <> outcome
  end
end
