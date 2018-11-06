defmodule Virta.Registry do
  use GenServer

  alias Virta.Pool
  alias Virta.InstanceSupervisor

  # ------------------------------------------------------------------------------- Client API -----

  @doc false
  def child_spec(arg) do
    super(arg)
  end

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc false
  def get(name) do
    GenServer.call(__MODULE__, { :get, name })
  end

  @doc """
  Registers a graph and generates the workflow

  ```elixir
  adder = Graph.new(type: :directed)
  |> Graph.add_edge(
    %Node{ module: Virta.Core.In, id: 0 },
    %Node{ module: Virta.Math.Add, id: 1 },
    label: %EdgeData{ from: :addend, to: :addend }
  )
  |> Graph.add_edge(
    %Node{ module: Virta.Core.In, id: 0 },
    %Node{ module: Virta.Math.Add, id: 1 },
    label: %EdgeData{ from: :augend, to: :augend }
  )
  |> Graph.add_edge(
    %Node{ module: Virta.Math.Add, id: 1 },
    %Node{ module: Virta.Core.Out, id: 2 },
    label: %EdgeData{ from: :sum, to: :output }
  )

  Virta.Registry.register("adder", adder)
  ```
  """
  def register(name, graph) do
    GenServer.cast(__MODULE__, { :register, name, graph })
  end

  @doc """
  Unregister a graph and removes the workflow

  ```elixir
  Virta.Registry.unregister("adder")
  ```
  """
  def unregister(name) do
    GenServer.cast(__MODULE__, { :unregister, name })
  end

  # ------------------------------------------------------------------------- Server Callbacks -----

  @doc false
  def init(_opts) do
    { :ok, %{} }
  end

  def handle_call({ :get, name }, _req, state) do
    if Map.has_key?(state, name) do
      { :reply, Map.get(state, name), state }
    else
      { :reply, nil, state }
    end
  end

  def handle_cast({ :register, name, graph }, state) do
    if Map.has_key?(state, name) do
      { :noreply, state }
    else
      { :ok, pid } = DynamicSupervisor.start_child(InstanceSupervisor, { Pool, %{ name: name, graph: graph } })
      { :noreply, Map.put(state, name, pid) }
    end
  end

  def handle_cast({ :unregister, name }, state) do
    if Map.has_key?(state, name) do
      DynamicSupervisor.terminate_child(InstanceSupervisor, Map.get(state, name))
      { :noreply, Map.delete(state, name) }
    else
      { :noreply, state }
    end
  end
end
