defmodule Virta do
  alias Virta.Node
  alias Virta.Registry
  alias Virta.EdgeData
  alias Virta.Instance
  alias Virta.Supervisor

  use Application

  def start(_type, _args) do
    Supervisor.start_link(name: Supervisor)
  end

  def run do
    adder = Graph.new(type: :directed)
    |> Graph.add_edge(
      %Node{ module: "Virta.Core.In", id: 0 },
      %Node{ module: "Virta.Math.Add", id: 1 },
      label: %EdgeData{ from: :addend, to: :addend }
    )
    |> Graph.add_edge(
      %Node{ module: "Virta.Core.In", id: 0 },
      %Node{ module: "Virta.Math.Add", id: 1 },
      label: %EdgeData{ from: :augend, to: :augend }
    )
    |> Graph.add_edge(
      %Node{ module: "Virta.Math.Add", id: 1 },
      %Node{ module: "Virta.Core.Out", id: 2 },
      label: %EdgeData{ from: :sum, to: :sum }
    )

    multiplier = Graph.new(type: :directed)
    |> Graph.add_edge(
      %Node{ module: "Virta.Core.In", id: 0 },
      %Node{ module: "Virta.Math.Multiply", id: 1 },
      label: %EdgeData{ from: :multiplicand, to: :multiplicand }
    )
    |> Graph.add_edge(
      %Node{ module: "Virta.Core.In", id: 0 },
      %Node{ module: "Virta.Math.Multiply", id: 1 },
      label: %EdgeData{ from: :multiplier, to: :multiplier }
    )
    |> Graph.add_edge(
      %Node{ module: "Virta.Math.Multiply", id: 1 },
      %Node{ module: "Virta.Core.Out", id: 2 },
      label: %EdgeData{ from: :product, to: :product }
    )

    complex_graph = Graph.new(type: :directed)
    |> Graph.add_edge(
      %Node{ module: "Virta.Core.In", id: 0 },
      %Node{ module: "Virta.Core.Workflow", id: 1 },
      label: %EdgeData{ from: :augend, to: :augend }
    )
    |> Graph.add_edge(
      %Node{ module: "Virta.Core.In", id: 0 },
      %Node{ module: "Virta.Core.Workflow", id: 1 },
      label: %EdgeData{ from: :addend, to: :addend }
    )
    |> Graph.add_edge(
      %Node{ module: "Virta.Core.Workflow", id: 1 },
      %Node{ module: "Virta.Core.Workflow", id: 2 },
      label: %EdgeData{ from: :sum, to: :multiplicand }
    )
    |> Graph.add_edge(
      %Node{ module: "Virta.Core.Workflow", id: 1 },
      %Node{ module: "Virta.Core.Workflow", id: 2 },
      label: %EdgeData{ from: :sum, to: :multiplier }
    )
    |> Graph.add_edge(
      %Node{ module: "Virta.Core.Workflow", id: 2 },
      %Node{ module: "Virta.Core.Out", id: 3 },
      label: %EdgeData{ from: :product, to: :product }
    )

    unless Graph.is_cyclic?(adder) do
      Registry.register("adder", adder)
      Registry.register("multiplier", multiplier)
      Registry.register("complex_graph", complex_graph)

      name = "complex_graph"
      Registry.get(name)

      Enum.each(1..10000, fn i ->
        data = %{
          %Node{ module: "Virta.Core.In", id: 0 } => [{ i, :augend, i }, { i, :addend, i*2 }],
          %Node{ module: "Virta.Core.Workflow", id: 1 } => [{ i, :graph, "adder" }],
          %Node{ module: "Virta.Core.Workflow", id: 2 } => [{ i, :graph, "multiplier" }]
        }

        :poolboy.transaction(String.to_existing_atom(name), fn (server) ->
          Instance.execute(server, data)
          receive do
            message -> IO.inspect(message)
          end
        end)
      end)
    else
      raise "Graph is expected to be acyclic"
    end
  end
end
