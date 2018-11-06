defmodule Virta.Core.Workflow do
  @moduledoc """
  Virta.Core.Worflow is a special component which allows us to invoke a different workflow from the
  current workflow.

  A workflow node can be represented as %Node{ module: Virta.Core.Workflow, id: 1, ref: "adder" }

  Notice the :ref property. It refers to the registered workflow with the name adder.

  Lets see a code example for a complex worflow which invokes other workflows:

  ```elixir
  alias Virta.Node
  alias Virta.Registry
  alias Virta.EdgeData
  alias Virta.Instance

  adder = Graph.new(type: :directed)
  |> Graph.add_edge(
    %Node{ module: Virta.Core.In, id: 0 },
    %Node{ module: Virta.Math.Add, id: 1 },
    label: %EdgeData{ from: :addend, to: :addend }
  )
  |> Graph.add_edge(
    %Node{ module: Virta.Core.In, id: 0 },
    %Node{ module: Virta.Math.Add, id: 1 },
    label: %EdgeData{ from: :augend, to: :augend }
  )
  |> Graph.add_edge(
    %Node{ module: Virta.Math.Add, id: 1 },
    %Node{ module: Virta.Core.Out, id: 2 },
    label: %EdgeData{ from: :sum, to: :sum }
  )

  multiplier = Graph.new(type: :directed)
  |> Graph.add_edge(
    %Node{ module: Virta.Core.In, id: 0 },
    %Node{ module: Virta.Math.Multiply, id: 1 },
    label: %EdgeData{ from: :multiplicand, to: :multiplicand }
  )
  |> Graph.add_edge(
    %Node{ module: Virta.Core.In, id: 0 },
    %Node{ module: Virta.Math.Multiply, id: 1 },
    label: %EdgeData{ from: :multiplier, to: :multiplier }
  )
  |> Graph.add_edge(
    %Node{ module: Virta.Math.Multiply, id: 1 },
    %Node{ module: Virta.Core.Out, id: 2 },
    label: %EdgeData{ from: :product, to: :product }
  )

  complex_graph = Graph.new(type: :directed)
  |> Graph.add_edge(
    %Node{ module: Virta.Core.In, id: 0 },
    %Node{ module: Virta.Core.Workflow, id: 1, ref: "adder" },
    label: %EdgeData{ from: :augend, to: :augend }
  )
  |> Graph.add_edge(
    %Node{ module: Virta.Core.In, id: 0 },
    %Node{ module: Virta.Core.Workflow, id: 1, ref: "adder" },
    label: %EdgeData{ from: :addend, to: :addend }
  )
  |> Graph.add_edge(
    %Node{ module: Virta.Core.Workflow, id: 1, ref: "adder" },
    %Node{ module: Virta.Core.Workflow, id: 2, ref: "multiplier" },
    label: %EdgeData{ from: :sum, to: :multiplicand }
  )
  |> Graph.add_edge(
    %Node{ module: Virta.Core.Workflow, id: 1, ref: "adder" },
    %Node{ module: Virta.Core.Workflow, id: 2, ref: "multiplier" },
    label: %EdgeData{ from: :sum, to: :multiplier }
  )
  |> Graph.add_edge(
    %Node{ module: Virta.Core.Workflow, id: 2, ref: "multiplier" },
    %Node{ module: Virta.Core.Out, id: 3 },
    label: %EdgeData{ from: :product, to: :product }
  )

  Registry.register("adder", adder)
  Registry.register("multiplier", multiplier)
  Registry.register("complex_graph", complex_graph)
  ```

  This can then be executed as follows:
  ```elixir
  data = %{
    %Node{ module: Virta.Core.In, id: 0 } => [
      { 1, :augend, 10 }, { 1, :addend, 20 }
    ]
  }

  { requst_id, output } = Virta.Executor.call("complex_graph", data)
  ```
  """
  @inports []
  @outports []

  alias Virta.Node
  alias Virta.Instance

  use Virta.Component

  @doc false
  def workflow do true end

  @impl true
  def loop(inport_args, outport_args, instance_pid, rinports \\ nil, rgraph_name \\ nil) do
    receive do
      { request_id, port, value } ->
        { inports, graph_name } = if(port == :graph) do
          get_ports_from_graph(value)
        else
          { rinports, rgraph_name }
        end
        inport_args = Map.put(inport_args, port, value)
        required_fields = check_required_fields(outport_args)
        if(required_fields |> Enum.all?(&(Map.has_key?(inport_args, &1)))) do
          run(request_id, inport_args, outport_args, instance_pid)
          loop(%{}, outport_args, instance_pid, inports, graph_name)
        else
          loop(inport_args, outport_args, instance_pid, inports, graph_name)
        end
    end
  end

  @impl true
  def run(request_id, inport_args, outport_args, _instance_pid) do
    { ref, message_configs } = outport_args
    |> Enum.filter(fn arg -> !Map.has_key?(arg, :pid) end)
    |> Enum.reduce({ nil, [] }, fn(arg, { _ref, message_configs }) ->
      to_port = Map.get(arg, :to)
      from_port = Map.get(arg, :from)
      ref = arg |> Map.get(:ref) |> Map.get(:ref)
      message_configs = message_configs ++ [{ from_port, to_port }]
      { ref, message_configs }
    end)

    data = message_configs
    |> Enum.reduce(%{}, fn({ _from, to}, acc) ->
      value = Map.get(inport_args, to)
      messages = (Map.get(acc, %Node{ module: Virta.Core.In, id: 0 }) || []) ++ [{ request_id, to, value }]
      Map.put(acc, %Node{ module: Virta.Core.In, id: 0 }, messages)
    end)

    { _requst_id, response } = Virta.Executor.call(ref, data)
    outport_args
    |> Enum.filter(fn arg -> Map.has_key?(arg, :pid) end)
    |> Enum.map(fn(arg) ->
      %{ from: from, to: to, pid: pid } = arg
      send(pid, { request_id, to , Map.get(response, from) })
    end)

    { request_id, :noreply }
  end

  defp get_ports_from_graph(value) do
    :poolboy.transaction(String.to_existing_atom(value), fn (server) ->
      inports = Instance.inports(server)
      { inports, value }
    end)
  end

  defp check_required_fields(outport_args) do
    outport_args
    |> Enum.filter(fn arg -> !Map.has_key?(arg, :pid) end)
    |> Enum.map(&Map.get(&1, :to))
  end
end
