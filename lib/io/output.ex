defmodule Virta.IO.Output do
  @inports [ :in ]
  @outports []

  use Virta.Component

  @impl true
  def run(inport_args, _outport_args, _instance_pid) do
    IO.puts("#{inspect Map.get(inport_args, :in)}")
    { :noreply }
  end
end
