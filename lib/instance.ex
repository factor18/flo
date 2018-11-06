defmodule Virta.Instance do
  use GenServer

  # Client API's

  @doc false
  def child_spec(arg) do
    super(arg)
  end

  @doc false
  def start_link(graph) do
    GenServer.start_link(__MODULE__, { :ok, graph })
  end

  @doc """
  Sends the initial messages to the nodes in the workflow to start the execution.

  The data should be a Map with the keys as the %Virta.Node{} and values as a list of messages with
  the format `{ request_id, port, value }` for the respective node.

  Example:
  ```elixir
  data = %{
    %Node{ module: Virta.Core.In, id: 0 } => [
      { 1, :augend, 10 }, { 1, :addend, 20 }
    ]
  }
  ```

  Virta creates a pool of workers for the workflow using
  [poolboy](https://github.com/devinus/poolboy) in order to provide concurrency. We can request for
  a worker and execute the workflow with the above data as follows:

  ```elixir
  :poolboy.transaction(String.to_existing_atom("adder"), fn (server) ->
    Virta.Instance.execute(server, data)
    receive do
      message -> IO.inspect(message)
      # {1, %{sum: 30}}
    end
  end)
  ```
  """
  def execute(server, data) do
    GenServer.call(server, { :execute, data })
  end

  @doc """
  Returns the list of out-edges from the `Virta.Core.In` component.

  Example:
  ```elixir
  Virta.Instance.inports(server)
  #=>
  [
    %Graph.Edge{
      label: %Virta.EdgeData{from: :addend, to: :addend},
      v1: %Virta.Node{id: 0, module: Virta.Core.In, ref: nil},
      v2: %Virta.Node{id: 1, module: Virta.Core.Workflow, ref: "adder"},
      weight: 1
    },
    %Graph.Edge{
      label: %Virta.EdgeData{from: :augend, to: :augend},
      v1: %Virta.Node{id: 0, module: Virta.Core.In, ref: nil},
      v2: %Virta.Node{id: 1, module: Virta.Core.Workflow, ref: "adder"},
      weight: 1
    }
  ]
  ```
  """
  def inports(server) do
    GenServer.call(server, { :inports })
  end

  @doc """
  Returns the list of in-edges to the `Virta.Core.Out` component.

  Example:
  ```elixir
  Virta.Instance.outports(server)
  #=>
  [
    %Graph.Edge{
      label: %Virta.EdgeData{from: :product, to: :output},
      v1: %Virta.Node{id: 2, module: Virta.Core.Workflow, ref: "multiplier"},
      v2: %Virta.Node{id: 3, module: Virta.Core.Out, ref: nil},
      weight: 1
    }
  ]
  ```
  """
  def outports(server) do
    GenServer.call(server, { :outports })
  end

  # Server Callbacks

  @doc false
  def init({ :ok, graph }) do
    lookup_table = graph
    |> Graph.topsort
    |> Enum.reverse
    |> Enum.reduce(Map.new(), fn(node, lookup_table) ->
      outport_args = get_outport_args(graph, node, lookup_table, graph)
      { :ok, pid } = Task.start_link(Map.get(node, :module), :loop, [ %{}, outport_args, self() ])
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

  def handle_call({ :inports }, _from, state) do
    graph = Map.get(state, :graph)
    vertex = graph
    |> Graph.topsort
    |> Enum.at(0)
    { :reply, Graph.out_edges(graph, vertex), state }
  end

  def handle_call({ :outports }, _from, state) do
    graph = Map.get(state, :graph)
    vertex = graph
    |> Graph.topsort
    |> Enum.reverse
    |> Enum.at(0)
    { :reply, Graph.in_edges(graph, vertex), state }
  end

  def handle_info({ request_id, :output, output }, state) do
    send(Map.get(state, :from), { request_id, output })
    { :noreply, state}
  end

  # Private functions

  defp get_outport_args(graph, node, lookup_table, graph) do
    module = Map.get(node, :module)
    cond do
      Keyword.has_key?(module.__info__(:functions), :final) && module.final ->
        in_edges = Graph.in_edges(graph, node)
        Enum.map(in_edges, fn(edge) ->
          Map.get(edge, :label)
        end)
      Keyword.has_key?(module.__info__(:functions), :workflow) && module.workflow ->
        in_edges = Graph.in_edges(graph, node)
        out_edges = Graph.out_edges(graph, node)
        Enum.map(in_edges, fn(edge) ->
          %{ v2: to_node, label: label } = edge
          Map.put(label, :ref, to_node)
        end) ++ Enum.map(out_edges, fn(edge) ->
          %{ v2: to_node, label: label } = edge
          Map.put(label, :pid, Map.get(lookup_table, to_node))
        end)
      true ->
        out_edges = Graph.out_edges(graph, node)
        Enum.map(out_edges, fn(edge) ->
          %{ v2: to_node, label: label } = edge
          Map.put(label, :pid, Map.get(lookup_table, to_node))
        end)
    end
  end
end
