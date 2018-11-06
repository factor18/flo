defmodule Virta.Core.In do
  @moduledoc """
  Serves as an entry point for a workflow.

  `Virta.Core.In` is used internally for workflow port discovery, which enables invoking a workflow
  from another workflow.

  All workflows must use this component.
  """

  @inports []
  @outports []

  use Virta.Component

  @impl true
  def loop(inport_args, outport_args, instance_pid) do
    receive do
      { request_id, port, value } ->
        inport_args = Map.put(inport_args, port, value)
        required_fields = Enum.map(outport_args, fn(arg) -> Map.get(arg, :to) end)
        if(required_fields |> Enum.all?(&(Map.has_key?(inport_args, &1)))) do
          run(request_id, inport_args, outport_args, instance_pid)
          loop(%{}, outport_args, instance_pid)
        else
          loop(inport_args, outport_args, instance_pid)
        end
    end
  end

  @impl true
  def run(request_id, inport_args, outport_args, _instance_pid) do
    Enum.map(outport_args, fn(arg) ->
      %{ to: port, pid: pid } = arg
      send(pid, { request_id, port , Map.get(inport_args, port) })
    end)
    { request_id, :noreply }
  end
end
