defmodule Virta do
  alias Virta.Instance

  def run do
    graph = Graph.new(type: :directed)
    |> Graph.add_vertex(%Virta.Node{ module: "Virta.Math.Add", id: 1 })
    |> Graph.add_vertex(%Virta.Node{ module: "Virta.Core.Output", id: 2 })
    |> Graph.add_vertex(%Virta.Node{ module: "Virta.Math.Add", id: 3 })
    |> Graph.add_vertex(%Virta.Node{ module: "Virta.Core.Output", id: 4 })
    |> Graph.add_edge(
      %Virta.Node{ module: "Virta.Math.Add", id: 1 },
      %Virta.Node{ module: "Virta.Core.Output", id: 2 },
      label: %Virta.EdgeData{ from: :sum, to: :in_port }
    )
    |> Graph.add_edge(
      %Virta.Node{ module: "Virta.Math.Add", id: 1 },
      %Virta.Node{ module: "Virta.Math.Add", id: 3 },
      label: %Virta.EdgeData{ from: :sum, to: :addend }
    )
    |> Graph.add_edge(
      %Virta.Node{ module: "Virta.Math.Add", id: 1 },
      %Virta.Node{ module: "Virta.Math.Add", id: 3 },
      label: %Virta.EdgeData{ from: :sum, to: :augend }
    )
    |> Graph.add_edge(
      %Virta.Node{ module: "Virta.Math.Add", id: 3 },
      %Virta.Node{ module: "Virta.Core.Output", id: 4 },
      label: %Virta.EdgeData{ from: :sum, to: :in_port }
    )
    |> Graph.add_edge(
      %Virta.Node{ module: "Virta.Math.Add", id: 3 },
      %Virta.Node{ module: "Virta.Math.Add", id: 5 },
      label: %Virta.EdgeData{ from: :sum, to: :addend }
    )
    |> Graph.add_edge(
      %Virta.Node{ module: "Virta.Math.Add", id: 3 },
      %Virta.Node{ module: "Virta.Math.Add", id: 5 },
      label: %Virta.EdgeData{ from: :sum, to: :augend }
    )
    |> Graph.add_edge(
      %Virta.Node{ module: "Virta.Math.Add", id: 5 },
      %Virta.Node{ module: "Virta.Core.Output", id: 6 },
      label: %Virta.EdgeData{ from: :sum, to: :in_port }
    )

    unless Graph.is_cyclic?(graph) do
      lookup_table = graph
      |> Instance.new

      data = %{
        %Virta.Node{ module: "Virta.Math.Add", id: 1 } => [{ :augend, 0 }, { :addend, 1 }]
      }

      Instance.run(lookup_table, data)
    else
      raise "Graph is expected to be acyclic"
    end
  end
end
