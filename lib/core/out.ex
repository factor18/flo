defmodule Virta.Core.Out do
  @inports []
  @outports []

  use Virta.Component

  def final do true end

  @impl true
  def loop(requests, outport_args, instance_pid) do
    receive do
      { request_id, port, value } ->
        inport_args = Map.get(requests, request_id) || %{}
        inport_args = Map.put(inport_args, port, value)
        required_fields = Enum.map(outport_args, fn(arg) -> Map.get(arg, :to) end)
        if(required_fields |> Enum.all?(&(Map.has_key?(inport_args, &1)))) do
          run(request_id, inport_args, outport_args, instance_pid)
          loop(Map.delete(requests, request_id), outport_args, instance_pid)
        else
          loop(Map.put(requests, request_id, inport_args), outport_args, instance_pid)
        end
    end
  end

  @impl true
  def run(request_id, inport_args, _outport_args, instance_pid) do
    send(instance_pid, { request_id, :output, inport_args })
  end
end
