defmodule VirtaTest do
  use ExUnit.Case
  doctest Virta

  alias Virta.Node
  alias Virta.Registry
  alias Virta.EdgeData

  test "sanity" do
    adder = Graph.new(type: :directed)
    |> Graph.add_edge(
      %Node{ module: Virta.Core.In, id: 0 },
      %Node{ module: Virta.Math.Add, id: 1 },
      label: %EdgeData{ from: :addend, to: :addend }
    )
    |> Graph.add_edge(
      %Node{ module: Virta.Core.In, id: 0 },
      %Node{ module: Virta.Math.Add, id: 1 },
      label: %EdgeData{ from: :augend, to: :augend }
    )
    |> Graph.add_edge(
      %Node{ module: Virta.Math.Add, id: 1 },
      %Node{ module: Virta.Core.Out, id: 2 },
      label: %EdgeData{ from: :sum, to: :sum }
    )
     multiplier = Graph.new(type: :directed)
    |> Graph.add_edge(
      %Node{ module: Virta.Core.In, id: 0 },
      %Node{ module: Virta.Math.Multiply, id: 1 },
      label: %EdgeData{ from: :multiplicand, to: :multiplicand }
    )
    |> Graph.add_edge(
      %Node{ module: Virta.Core.In, id: 0 },
      %Node{ module: Virta.Math.Multiply, id: 1 },
      label: %EdgeData{ from: :multiplier, to: :multiplier }
    )
    |> Graph.add_edge(
      %Node{ module: Virta.Math.Multiply, id: 1 },
      %Node{ module: Virta.Core.Out, id: 2 },
      label: %EdgeData{ from: :product, to: :product }
    )
     complex_graph = Graph.new(type: :directed)
    |> Graph.add_edge(
      %Node{ module: Virta.Core.In, id: 0 },
      %Node{ module: Virta.Core.Workflow, id: 1, ref: "adder" },
      label: %EdgeData{ from: :augend, to: :augend }
    )
    |> Graph.add_edge(
      %Node{ module: Virta.Core.In, id: 0 },
      %Node{ module: Virta.Core.Workflow, id: 1, ref: "adder" },
      label: %EdgeData{ from: :addend, to: :addend }
    )
    |> Graph.add_edge(
      %Node{ module: Virta.Core.Workflow, id: 1, ref: "adder" },
      %Node{ module: Virta.Core.Workflow, id: 2, ref: "multiplier" },
      label: %EdgeData{ from: :sum, to: :multiplicand }
    )
    |> Graph.add_edge(
      %Node{ module: Virta.Core.Workflow, id: 1, ref: "adder" },
      %Node{ module: Virta.Core.Workflow, id: 2, ref: "multiplier" },
      label: %EdgeData{ from: :sum, to: :multiplier }
    )
    |> Graph.add_edge(
      %Node{ module: Virta.Core.Workflow, id: 2, ref: "multiplier" },
      %Node{ module: Virta.Core.Out, id: 3 },
      label: %EdgeData{ from: :product, to: :output }
    )

    Registry.register("adder", adder)
    Registry.register("multiplier", multiplier)
    Registry.register("complex_graph", complex_graph)

    name = "complex_graph"

    Registry.get(name)

    data = %{
      %Node{ module: Virta.Core.In, id: 0 } => [{ 1, :augend, 1 }, { 1, :addend, 2 }]
    }

    Virta.Executor.call(name, data)
  end
end
