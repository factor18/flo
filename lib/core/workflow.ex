defmodule Virta.Core.Workflow do
  @inports []
  @outports []

  alias Virta.Node
  alias Virta.Instance

  use Virta.Component

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
      messages = (Map.get(acc, %Node{ module: "Virta.Core.In", id: 0 }) || []) ++ [{ request_id, to, value }]
      Map.put(acc, %Node{ module: "Virta.Core.In", id: 0 }, messages)
    end)

    :poolboy.transaction(String.to_existing_atom(ref), fn (server) ->
      Instance.execute(server, data)
      receive do
        { _request_id, response } ->
          outport_args
          |> Enum.filter(fn arg -> Map.has_key?(arg, :pid) end)
          |> Enum.map(fn(arg) ->
            %{ from: from, to: to, pid: pid } = arg
            send(pid, { request_id, to , Map.get(response, from) })
          end)
      end
    end)
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
