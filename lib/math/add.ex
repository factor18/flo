defmodule Virta.Math.Add do
  @inports [ :addend, :augend ]
  @outports [ :sum ]

  def inports, do: @inports
  def outports, do: @outports

  def loop(inport_args, outport_args) do
    receive do
      { port, value } when port in @inports ->
        inport_args = Map.put(inport_args, port, value)
        if(@inports |> Enum.all?(&(Map.has_key?(inport_args, &1)))) do
          run(inport_args, outport_args)
          loop(%{}, outport_args)
        else
          loop(inport_args, outport_args)
        end
    end
  end

  def run(inport_args, outport_args) do
    %{ augend: augend, addend: addend } = inport_args
    value = augend + addend
    Enum.map(outport_args, fn(outport_arg) ->
      %{ pid: pid, to: to } = outport_arg
      send(pid, { to, value })
    end)
  end
end
