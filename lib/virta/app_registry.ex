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
    components = order(application)
    if Map.has_key?(state, name) do
      {:reply, {:error, "already_exists"}, state}
    else
      application.triggers |> Enum.each(fn trigger ->
        subgraph = components |> Enum.find(fn subgraph ->
          subgraph |> Enum.find_value(fn vertex -> vertex == trigger.id end)
        end)

        tasks = application.tasks |> Enum.map(fn task -> task.id end)

        current_tasks = subgraph
        |> Enum.filter(fn vertex ->
           tasks |> Enum.find_value(fn task_id -> vertex == task_id end)
        end)
        |> Enum.map(fn task_id ->
          application.tasks |> Enum.find(fn task -> task.id == task_id end)
        end)

        Registry.trigger(trigger.ref).register(trigger, current_tasks)
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

  defp order(application) do
    graph = application.links
    |> Enum.reduce(Graph.new(type: :directed), fn (link, graph) -> graph |> Graph.add_edge(link.from, link.to) end)

    topological_order = graph |> Graph.topsort

    # TODO: solve for multiple triggers in single component
    # TODO: solve for conditional branching

    graph
    |> Graph.components
    |> Enum.map(fn subgraph ->
      subgraph |> Enum.sort_by(fn vertex ->
        topological_order |> Enum.find_index(fn x -> x == vertex end)
      end)
    end)
  end
end
