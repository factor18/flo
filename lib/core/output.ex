defmodule Virta.Core.Output do
  def inports, do: [ :in_port ]
  def outports, do: []

  def loop(_in_port, outport_args) do
    receive do
      {:in_port, value} ->
        IO.puts("#{inspect value}")
        loop(nil, outport_args)
    end
  end
end
