defmodule Virta.Pool do
  use Supervisor

  def start_link(data) do
    Supervisor.start_link(__MODULE__, { :ok, data })
  end

  defp poolboy_config(name) do
    [
      {:name, {:local, String.to_atom(name)}},
      {:worker_module, Virta.Instance},
      {:size, 5},
      {:max_overflow, 2}
    ]
  end

  def init({ :ok, %{ name: name, graph: graph } }) do
    children = [
       :poolboy.child_spec(:worker, poolboy_config(name), graph)
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
