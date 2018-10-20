defmodule Virta.Output do
  def inports, do: [ :in_port, :out_pid ]
  def outports, do: []

  def loop(_in_port, _out_pid) do
    receive do
      {:in_port, value} ->
        IO.puts("\nCore.Output:in = #{inspect value}")
        loop(nil, nil)
    end
  end
end
