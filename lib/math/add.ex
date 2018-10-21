defmodule Virta.Math.Add do
  @inports [ :addend, :augend ]
  @outports [ :sum ]

  use Virta.Component

  def run(inport_args, outport_args, _instance_pid) do
    %{ augend: augend, addend: addend } = inport_args
    value = augend + addend
    Enum.map(outport_args, fn(outport_arg) ->
      %{ pid: pid, to: to } = outport_arg
      send(pid, { to, value })
    end)
  end
end
