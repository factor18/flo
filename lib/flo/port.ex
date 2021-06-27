defmodule Flo.Port do
  @derive Jason.Encoder

  use Accessible

  use Construct do
    field(:schema, :map)
    field(:name, :string)
    field(:required, :boolean)
  end
end
