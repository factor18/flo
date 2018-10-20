defmodule Virta.Instance do
  def new(graph) do
    lookup_table = Map.new()

    Graph.topsort(graph)
    |> Enum.reverse
    |> Enum.reduce(lookup_table, fn(node, lookup_table) ->
      { inports, _args } = Code.eval_string(node[:module] <> ".inports")
      inport_args = List.duplicate(nil, Enum.count(inports))
      outport_args = get_outport_args(graph, node, lookup_table)

      module = Module.concat("Elixir", node[:module])
      { :ok, pid } = Task.start_link(module, :loop, inport_args ++ outport_args)
      Map.put(lookup_table, node, pid)
    end)
  end

  def run(lookup_table, data) do
    #graph
    #|> Graph.vertices
    #|> Enum.filter(fn vertex ->
    #  Enum.count(Graph.in_edges(graph, vertex)) == 0
    #end)

    Map.to_list(data)
    |> Enum.map(fn({ node, messages }) ->
      pid = Map.get(lookup_table, node)
      messages
      |> Enum.map(fn(message) ->
        send(pid, message)
      end)
    end)
  end

  # Private functions

  defp get_outport_args(graph, node, lookup_table) do
    out_edges = Graph.out_edges(graph, node)
    Enum.map(out_edges, fn(edge) ->
      %{ v2: to_node, label: label } = edge
      Map.put(label, :pid, Map.get(lookup_table, to_node))
    end)
  end
end
