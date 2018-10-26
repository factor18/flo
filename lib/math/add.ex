defmodule Virta.Math.Add do
  @inports [ :addend, :augend ]
  @outports [ :sum ]

  use Virta.Component

  @impl true
  def run(inport_args, _outport_args, _instance_pid) do
    value = Map.get(inport_args, :augend) + Map.get(inport_args, :addend)
    { :normal, %{ sum: value } }
  end
end
