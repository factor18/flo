defmodule Virta do
  alias Virta.Node
  alias Virta.EdgeData
  alias Virta.Instance

  def run do
    graph = Graph.new(type: :directed)
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
      %Node{ module: "Virta.IO.Output", id: 2 },
      label: %EdgeData{ from: :sum, to: :in }
    )
    |> Graph.add_edge(
      %Node{ module: "Virta.Math.Add", id: 1 },
      %Node{ module: "Virta.Math.Add", id: 3 },
      label: %EdgeData{ from: :sum, to: :addend }
    )
    |> Graph.add_edge(
      %Node{ module: "Virta.Math.Add", id: 1 },
      %Node{ module: "Virta.Math.Add", id: 3 },
      label: %EdgeData{ from: :sum, to: :augend }
    )
    |> Graph.add_edge(
      %Node{ module: "Virta.Math.Add", id: 3 },
      %Node{ module: "Virta.IO.Output", id: 4 },
      label: %EdgeData{ from: :sum, to: :in }
    )
    |> Graph.add_edge(
      %Node{ module: "Virta.Math.Add", id: 3 },
      %Node{ module: "Virta.Math.Add", id: 5 },
      label: %EdgeData{ from: :sum, to: :addend }
    )
    |> Graph.add_edge(
      %Node{ module: "Virta.Math.Add", id: 3 },
      %Node{ module: "Virta.Math.Add", id: 5 },
      label: %EdgeData{ from: :sum, to: :augend }
    )
    |> Graph.add_edge(
      %Node{ module: "Virta.Math.Add", id: 5 },
      %Node{ module: "Virta.IO.Output", id: 6 },
      label: %EdgeData{ from: :sum, to: :in }
    )
    |> Graph.add_edge(
      %Node{ module: "Virta.Math.Add", id: 5 },
      %Node{ module: "Virta.Core.Out", id: 7 },
      label: %EdgeData{ from: :sum, to: :sum }
    )

    data = %{
      %Node{ module: "Virta.Core.In", id: 0 } => [{ :inflate,  %{ augend: 0, addend: 1 } }]
    }

    unless Graph.is_cyclic?(graph) do
      { :ok, server } = Instance.start_link(graph)
      Instance.initialize(server)
      Instance.execute(server, data)
    else
      raise "Graph is expected to be acyclic"
    end
  end
end
