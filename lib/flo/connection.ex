defmodule Flo.Connection do
  @derive Jason.Encoder

  use Accessible

  use Construct do
    field :source, :string
    field :destination, :string
    field :condition, Flo.Script, default: nil
  end
end
