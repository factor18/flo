defmodule Virta.Core.Out do
  def deflate, do: true

  def loop(inport_args, outport_args, instance_pid) do
    receive do
      { port, value } ->
        inport_args = Map.put(inport_args, port, value)
        required_fields = Enum.map(outport_args, fn(arg) -> Map.get(arg, :to) end)
        if(required_fields |> Enum.all?(&(Map.has_key?(inport_args, &1)))) do
          run(inport_args, outport_args, instance_pid)
        else
          loop(inport_args, outport_args, instance_pid)
        end
    end
  end

  def run(inport_args, _outport_args, instance_pid) do
    send(instance_pid, { :output, inport_args })
  end
end
