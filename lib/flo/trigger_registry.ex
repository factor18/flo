defmodule Flo.TriggerRegistry do
  require Logger

  use GenServer

  alias Flo.Trigger
  alias Flo.Util.ModuleLoader

  # Client

  def start_link(), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  def triggers(), do: GenServer.call(__MODULE__, :triggers)

  def triggers(scope), do: GenServer.call(__MODULE__, {:triggers, scope})

  def trigger(scope, name), do: GenServer.call(__MODULE__, {:trigger, scope, name})

  def reload(), do: GenServer.cast(__MODULE__, :reload)

  # Server

  def init(:ok), do: {:ok, load()}

  def handle_call(:triggers, _req, state) do
    {:reply, state, state}
  end

  def handle_call({:triggers, scope}, _req, state) do
    filtered_triggers =
      state
      |> Enum.filter(fn trigger -> trigger.scope == scope end)

    {:reply, filtered_triggers, state}
  end

  def handle_call({:trigger, scope, name}, _req, state) do
    trigger =
      state
      |> Enum.find(fn trigger ->
        trigger.scope == scope && trigger.name == name
      end)

    {:reply, trigger, state}
  end

  def handle_cast(:reload, _triggers) do
    Logger.debug("Reloading triggers")
    {:noreply, load()}
  end

  defp load() do
    triggers = Trigger |> ModuleLoader.get_elements()
    triggers |> Enum.each(&Logger.debug("#{&1.scope}:#{&1.name} registered"))
    triggers
  end
end
