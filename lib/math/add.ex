defmodule Virta.Math.Add do
  def inports, do: [ :addend, :augend ]
  def outports, do: [sum: nil]

  def loop(augend, addend, outport_args) do
    receive do
      {:augend, value} when addend != nil ->
        value = addend + value
        Enum.map(outport_args, fn(outport_arg) ->
          %{ pid: pid, to: to } = outport_arg
          send(pid, { to, value })
        end)
        loop(nil, nil, outport_args)
      {:augend, value} ->
        loop(value, addend, outport_args)
      {:addend, value} when augend != nil ->
        value = augend + value
        Enum.map(outport_args, fn(outport_arg) ->
          %{ pid: pid, to: to } = outport_arg
          send(pid, { to, value })
        end)
        loop(nil, nil, outport_args)
      {:addend, value} ->
        loop(augend, value, outport_args)
    end
  end
end
