defmodule Flo.Workflow do
  @derive Jason.Encoder

  alias Flo.{Connection, Element, Stimulus}

  use Accessible

  use Construct do
    field :name, :string
    field :description, :string
    field :stimuli, {:array, Stimulus}
    field :elements, {:array, Element}
    field :connections, {:array, Connection}
  end
end
