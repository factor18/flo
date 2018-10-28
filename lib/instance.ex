defmodule Virta.Instance do
  use GenServer

  # Client API's

  def start_link(graph) do
    GenServer.start_link(__MODULE__, { :ok, graph })
  end

  def execute(server, data) do
    GenServer.call(server, { :execute, data })
  end

  # Server Callbacks

  def init({ :ok, graph }) do
    Process.flag(:trap_exit, true)

    lookup_table = graph
    |> Graph.topsort
    |> Enum.reverse
    |> Enum.reduce(Map.new(), fn(node, lookup_table) ->
      outport_args = get_outport_args(graph, node, lookup_table, graph)
      module = Module.concat("Elixir", Map.get(node, :module))
      { :ok, pid } = Task.start_link(module, :loop, [ %{}, outport_args, self() ])
      Map.put(lookup_table, node, pid)
    end)

    state = Map.new()
    |> Map.put(:graph, graph)
    |> Map.put(:lookup_table, lookup_table)

    { :ok, state }
  end

  def handle_call({ :execute, data }, { pid, _ref }, state) do
    Map.to_list(data)
    |> Enum.map(fn({ node, messages }) ->
      pid = Map.get(Map.get(state, :lookup_table), node)
      messages
      |> Enum.map(fn(message) ->
        send(pid, message)
      end)
    end)
    { :reply, :ok, Map.put(state, :from, pid) }
  end

  def handle_info({ request_id, :output, output }, state) do
    send(Map.get(state, :from), { request_id, output })
    { :noreply, state}
  end

  def handle_info({ :EXIT, _pid, reason }, state) do
    IO.inspect(reason)
    { :noreply, state }
  end

  # Private functions

  defp get_outport_args(graph, node, lookup_table, graph) do
    module = Module.concat("Elixir", Map.get(node, :module))
    if(Keyword.has_key?(module.__info__(:functions), :final) && module.final) do
      in_edges = Graph.in_edges(graph, node)
      Enum.map(in_edges, fn(edge) ->
        Map.get(edge, :label)
      end)
    else
      out_edges = Graph.out_edges(graph, node)
      Enum.map(out_edges, fn(edge) ->
        %{ v2: to_node, label: label } = edge
        Map.put(label, :pid, Map.get(lookup_table, to_node))
      end)
    end
  end
end
