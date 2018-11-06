defmodule Virta.Math.Multiply do
  @inports [ :multiplicand, :multiplier ]
  @outports [ :product ]

  use Virta.Component

  @impl true
  def run(request_id, inport_args, _outport_args, _instance_pid) do
    value = Map.get(inport_args, :multiplier) * Map.get(inport_args, :multiplicand)
    { request_id, :reply, %{ product: value } }
  end
end
