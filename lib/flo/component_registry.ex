defmodule Flo.ComponentRegistry do
  require Logger

  use GenServer

  alias Flo.Component
  alias Flo.Util.ModuleLoader

  # Client

  def start_link(), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  def components(), do: GenServer.call(__MODULE__, :components)

  def components(scope), do: GenServer.call(__MODULE__, {:components, scope})

  def component(scope, name), do: GenServer.call(__MODULE__, {:component, scope, name})

  def reload(), do: GenServer.cast(__MODULE__, :reload)

  # Server

  def init(:ok), do: {:ok, load()}

  def handle_call(:components, _req, state) do
    {:reply, state, state}
  end

  def handle_call({:components, scope}, _req, state) do
    filtered_components =
      state
      |> Enum.filter(fn component -> component.scope == scope end)

    {:reply, filtered_components, state}
  end

  def handle_call({:component, scope, name}, _req, state) do
    component =
      state
      |> Enum.find(fn component ->
        component.scope == scope && component.name == name
      end)

    {:reply, component, state}
  end

  def handle_cast(:reload, _components) do
    Logger.debug("Reloading components")
    {:noreply, load()}
  end

  defp load() do
    components = Component |> ModuleLoader.get_elements()
    components |> Enum.each(&Logger.debug("#{&1.scope}:#{&1.name} registered"))
    components
  end
end
