defmodule Virta do
  alias Virta.Instance

  def run do
    graph = Graph.new(type: :directed)
    |> Graph.add_vertex(%{ module: "Virta.Add", id: 1 })
    |> Graph.add_vertex(%{ module: "Virta.Output", id: 2 })
    |> Graph.add_edge(%{ module: "Virta.Add", id: 1 }, %{ module: "Virta.Output", id: 2 }, label: %{ from: :sum, to: :in_port })

    unless Graph.is_cyclic?(graph) do
      lookup_table = graph
      |> Instance.new


      data = %{
        %{ module: "Virta.Add", id: 1 } => [{ :augend, 1 }, { :addend, 10 }]
      }

      Instance.run(lookup_table, data)
    else
      IO.puts("The given graph is cyclic")
    end
  end
end
