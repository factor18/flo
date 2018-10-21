defmodule Virta.Instance do
  use GenServer

  # Client API's

  def start_link(graph) do
    GenServer.start_link(__MODULE__, { :ok, graph })
  end

  def initialize(server) do
    GenServer.call(server, { :initialize })
  end

  def execute(server, data) do
    GenServer.cast(server, { :execute, data })
  end

  # Server Callbacks

  def init({ :ok, graph }) do
    Process.flag(:trap_exit, true)
    { :ok, %{ graph: graph } }
  end

  def handle_call({ :initialize }, _from, state) do
    graph = Map.get(state, :graph)

    lookup_table = graph
    |> Graph.topsort
    |> Enum.reverse
    |> Enum.reduce(Map.new(), fn(node, lookup_table) ->
      outport_args = get_outport_args(graph, node, lookup_table, graph)
      module = Module.concat("Elixir", Map.get(node, :module))
      { :ok, pid } = Task.start_link(module, :loop, [ %{}, outport_args, self() ])
      Map.put(lookup_table, node, pid)
    end)

    { :reply, lookup_table, Map.put(state, :lookup_table, lookup_table )}
  end

  def handle_cast({ :execute, data }, state) do
    Map.to_list(data)
    |> Enum.map(fn({ node, messages }) ->
      pid = Map.get(Map.get(state, :lookup_table), node)
      messages
      |> Enum.map(fn(message) ->
        send(pid, message)
      end)
    end)
    { :noreply, state }
  end

  def handle_info({ :output, output }, state) do
    { :noreply, Map.put(state, :output, { :ok, output }) }
  end

  def handle_info({ :EXIT, _pid, reason }, state) do
    count = Map.get(state, :count) || 0

    state = unless reason == :normal do
      Map.put(state, :output, { :error, reason })
    else
      state
    end

    if(length(Graph.vertices(Map.get(state, :graph))) == count + 1) do
      IO.puts("Exiting: #{inspect Map.get(state, :output)}")
      { :stop, :normal, state }
    else
      { :noreply, Map.put(state, :count, count + 1) }
    end
  end

  # Private functions

  defp get_outport_args(graph, node, lookup_table, graph) do
    module = Module.concat("Elixir", Map.get(node, :module))
    if(Keyword.has_key?(module.__info__(:functions), :deflate) && module.deflate) do
      in_edges = Graph.in_edges(graph, node)
      Enum.map(in_edges, fn(edge) ->
        %{ label: label } = edge
        Map.put(label, :deflate, true)
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
