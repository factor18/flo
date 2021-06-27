defmodule Flo.Stimulus do
  @derive Jason.Encoder

  use Accessible

  use Construct do
    field(:ref, :string)
    field(:name, :string)
    field(:scope, :string)
    field(:inports, {:map, Flo.Script})
    field(:configs, {:map, Flo.Script})
  end
end
