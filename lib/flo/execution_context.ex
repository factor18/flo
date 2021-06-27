defmodule Flo.ExecutionContext do
  @derive Jason.Encoder

  use Accessible

  use Construct do
    field :graph, :any
    field :strategy, :string
    field :context, Flo.Context
    field :workflow, Flo.Workflow
    field :queue, {:array, :string}
  end
end
