defmodule Virta.Add do
  def inports, do: [ :addend, :augend ]
  def outports, do: [sum: nil]

  def loop(augend, addend, data) do
    receive do
      {:augend, value} when addend != nil ->
        %{ pid: pid, to: to } = data
        send(pid, { to, addend + value })
        loop(nil, nil, data)
      {:augend, value} ->
        loop(value, addend, data)
      {:addend, value} when augend != nil ->
        %{ pid: pid, to: to } = data
        send(pid, { to, value + augend })
        loop(nil, nil, data)
      {:addend, value} ->
        loop(augend, value, data)
    end
  end
end
