defmodule Flo.Graph do
  alias Flo.{Workflow, Connection}

  def new(%Workflow{} = workflow) do
    workflow
    |> Map.get(:connections)
    |> Enum.reduce(
      Graph.new(type: :directed),
      fn %Connection{source: source, destination: destination}, graph ->
        graph |> Graph.add_edge(source, destination)
      end
    )
  end

  def root(graph) do
    Graph.arborescence_root(graph)
  end

  def next(graph, ref) do
    graph |> Graph.out_neighbors(ref)
  end
end
