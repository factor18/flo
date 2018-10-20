defmodule Virta do
  alias Virta.Instance

  def run do
    graph = Graph.new(type: :directed)
    |> Graph.add_vertex(%Virta.Node{ module: "Virta.Add", id: 1 })
    |> Graph.add_vertex(%Virta.Node{ module: "Virta.Output", id: 2 })
    |> Graph.add_edge(
      %Virta.Node{ module: "Virta.Add", id: 1 },
      %Virta.Node{ module: "Virta.Output", id: 2 },
      label: %Virta.EdgeData{ from: :sum, to: :in_port }
    )

    unless Graph.is_cyclic?(graph) do
      lookup_table = graph
      |> Instance.new

      data = %{
        %Virta.Node{ module: "Virta.Add", id: 1 } => [{ :augend, 1 }, { :addend, 10 }]
      }

      Instance.run(lookup_table, data)
    else
      raise "Graph is expected to be acyclic"
    end
  end
end
