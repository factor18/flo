defmodule Virta.Registry do
  use GenServer

  alias Virta.Instance
  alias Virta.InstanceSupervisor

  # ------------------------------------------------------------------------------- Client API -----

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get(name) do
    GenServer.call(__MODULE__, { :get, name })
  end

  def register(name, graph) do
    GenServer.cast(__MODULE__, { :register, name, graph })
  end

  def unregister(name) do
    GenServer.cast(__MODULE__, { :unregister, name })
  end

  # ------------------------------------------------------------------------- Server Callbacks -----

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
      { :ok, pid } = DynamicSupervisor.start_child(InstanceSupervisor, { Instance, graph })
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
