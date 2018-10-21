defmodule Virta.Core.Output do
  @inports [ :in_port ]
  @outports []

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

  def run(inport_args, _outport_args) do
    %{ in_port: in_port } = inport_args
    IO.puts("#{inspect in_port}")
  end
end
