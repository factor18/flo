defmodule Virta.Add do
  def inports, do: [ :addend, :augend ]
  def outports, do: [sum: nil]

  def loop(augend, addend, data) do
    receive do
      {:augend, value} when addend != nil ->
        IO.puts("Math.Add: {:augend, #{value}}")
        %{ pid: pid, to: to } = data
        send(pid, { to, addend + value })
        loop(nil, nil, data)
      {:augend, value} ->
        IO.puts("Math.Add: {:augend, #{value}}")
        loop(value, addend, data)
      {:addend, value} when augend != nil ->
        IO.puts("Math.Add: {:addend, #{value}}, augend: #{augend}")
        %{ pid: pid, to: to } = data
        send(pid, { to, value + augend })
        loop(nil, nil, data)
      {:addend, value} ->
        IO.puts("Math.Add: {:addend, #{value}}")
        loop(augend, value, data)
    end
  end
end
