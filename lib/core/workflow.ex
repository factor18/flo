defmodule Virta.Core.Workflow do
  @inports []
  @outports []

  alias Virta.Instance

  use Virta.Component

  @impl true
  def loop(requests, outport_args, instance_pid, request_inports \\ %{}, request_graph_name \\ %{}) do
    receive do
      { request_id, port, value } ->
        { inports, graph_name } = if(port == :graph) do
          get_ports_from_graph(value)
        else
          {
            Map.get(request_inports, request_id),
            Map.get(request_graph_name, request_id)
          }
        end
        inport_args = Map.get(requests, request_id) || %{}
        inport_args = Map.put(inport_args, port, value)
        request_inports = Map.put(request_inports, request_id, inports)
        request_graph_name = Map.put(request_graph_name, request_id, graph_name)
        required_fields = check_required_fields(inport_args, inports || [])
        if(required_fields |> Enum.all?(&(Map.has_key?(inport_args, &1)))) do
          run(request_id, inport_args, outport_args, instance_pid, inports, graph_name)
          loop(
            Map.delete(requests, request_id),
            outport_args,
            instance_pid,
            Map.delete(request_inports, request_id),
            Map.delete(request_graph_name, request_id)
          )
        else
          loop(Map.put(requests, request_id, inport_args), outport_args, instance_pid, request_inports, request_graph_name)
        end
    end
  end

  @impl true
  def run(request_id, inport_args, outport_args, _instance_pid, inports \\ [], value \\ nil) do
    data = Enum.reduce(inports, %{}, fn(inport, acc) ->
      node = Map.get(inport, :v1)
      port = inport |> Map.get(:label) |> Map.get(:from)
      messages = Map.get(acc, node) || []
      Map.put(acc, node, messages ++ [{ request_id, port, Map.get(inport_args, port) }])
    end)

    :poolboy.transaction(String.to_existing_atom(value), fn (server) ->
      Instance.execute(server, data)
      receive do
        { _request_id, response } ->
          Enum.map(outport_args, fn(arg) ->
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

  defp check_required_fields(_inport_args, inports) do
    inports
    |> Enum.map(&Map.get(&1, :label))
    |> Enum.map(&Map.get(&1, :from))
    |> Enum.concat([ :graph ])
  end
end
