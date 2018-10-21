defmodule Virta.IO.Output do
  @inports [ :in_port ]
  @outports []

  use Virta.Component

  def run(inport_args, _outport_args, _instance_pid) do
    %{ in_port: in_port } = inport_args
    IO.puts("#{inspect in_port}")
  end
end
