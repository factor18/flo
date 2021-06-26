defmodule Flo.Outports do
  @derive Jason.Encoder

  use Accessible

  use Construct do
    field :default, {:array, Flo.Port}, default: []
    field :additional, {:map, {:array, Flo.Port}}, default: %{}
  end
end
