defmodule Virta.Registry do
  use GenServer

  alias Virta.{Trigger, Component, ModuleLoader, TriggerSupervisor}

  import ModuleLoader

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def index() do
    GenServer.call(__MODULE__, :index)
  end

  def trigger(name) do
    GenServer.call(__MODULE__, {:get_trigger, name})
  end

  def triggers() do
    GenServer.call(__MODULE__, :triggers)
  end

  def component(name) do
    GenServer.call(__MODULE__, {:get_component, name})
  end

  def components() do
    GenServer.call(__MODULE__, :components)
  end

  def reload() do
    GenServer.cast(__MODULE__, :reload)
  end

  def init(_opts) do
    {:ok, load()}
  end

  def handle_call(:index, _req, state) do
    {:reply, state, state}
  end

  def handle_call({:get_trigger, name}, _req, state) do
    {:reply, state |> Kernel.get_in([:triggers, name]), state}
  end

  def handle_call(:triggers, _req, state) do
    {:reply, state |> Map.get(:triggers), state}
  end

  def handle_call({:get_component, name}, _req, state) do
    {:reply, state |> Kernel.get_in([:components, name]), state}
  end

  def handle_call(:components, _req, state) do
    {:reply, state |> Map.get(:components), state}
  end

  def handle_cast(:reload, _state) do
    {:noreply, load()}
  end

  defp load() do
    triggers = get_triggers()
    components = get_components()

    triggers |> Enum.each(fn({name, module}) ->
      DynamicSupervisor.start_child(TriggerSupervisor, {module, %{}})
    end)

    %{triggers: triggers, components: components}
  end

  defp get_triggers() do
    Trigger |> get_plugins_map
  end

  defp get_components() do
    Component |> get_plugins_map
  end

  defp get_plugins_map(plugin_type) do
    plugin_type
    |> get_plugins
    |> Enum.reduce(%{}, fn(mod, acc) -> acc |> Map.put(mod.name, mod) end)
  end
end
