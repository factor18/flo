defmodule Virta.Core.Out do
  @moduledoc """
  Serves as the output collection point for a workflow.

  Any workflow which needs to return a value (or values) needs to use `Virta.Core.Out` as the last
  node in the graph. It acts as a collector and sends a message to the invoking process with the
  output.
  """

  @inports []
  @outports []

  use Virta.Component

  @doc false
  def final do true end

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
  def run(request_id, inport_args, _outport_args, instance_pid) do
    send(instance_pid, { request_id, :output, inport_args })
  end
end
