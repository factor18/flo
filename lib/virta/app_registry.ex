defmodule Virta.AppRegistry do
  use GenServer

  alias Virta.Registry

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def index() do
    GenServer.call(__MODULE__, :index)
  end

  def get(name) do
    GenServer.call(__MODULE__, {:get, name})
  end

  def register(application) do
    GenServer.call(__MODULE__, {:register, application})
  end

  def deregister(name) do
    GenServer.call(__MODULE__, {:deregister, name})
  end

  def init(_opts) do
    {:ok, %{}}
  end

  def handle_call(:index, _req, state) do
    {:reply, state, state}
  end

  def handle_call({:get, name}, _req, state) do
    {:reply, Map.get(state, name), state}
  end

  def handle_call({:register, application}, _req, state) do
    name = application.name
    if Map.has_key?(state, name) do
      {:reply, {:error, "already_exists"}, state}
    else
      application.triggers |> Enum.each(fn trigger ->
        Registry.trigger(trigger.ref).register(trigger)
      end)
      {:reply, {:ok, "registered"}, Map.put(state, name, application)}
    end
  end

  def handle_call({:deregister, name}, _req, state) do
    if Map.has_key?(state, name) do
      Map.get(state, name).triggers |> Enum.each(fn trigger ->
        Registry.trigger(trigger.ref).deregister(trigger.id)
      end)
      {:reply, {:ok, "unregistered"}, Map.delete(state, name)}
    else
      {:reply, {:error, "not_found"}, state}
    end
  end
end
