defmodule Flo.WorkflowRegistry do
  use GenServer

  alias Flo.{Workflow, WorkflowSupervisor}

  # Client

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def register(workflow = %Workflow{}) do
    GenServer.call(__MODULE__, {:register, workflow})
  end

  def deregister(name) do
    GenServer.call(__MODULE__, {:deregister, name})
  end

  # Server

  @impl true
  def init(:ok) do
    refs = %{}
    names = %{}
    {:ok, {names, refs}}
  end

  @impl true
  def handle_call({:register, %Workflow{name: name} = workflow}, _from, {names, refs}) do
    case names |> Map.get(name) do
      nil ->
        {:ok, pid} = WorkflowSupervisor.start_workflow(workflow)
        ref = Process.monitor(pid)
        refs = refs |> Map.put(ref, name)
        names = names |> Map.put(name, pid)
        {:reply, pid, {names, refs}}

      pid ->
        {:reply, pid, {names, refs}}
    end
  end

  @impl true
  def handle_call({:deregister, workflow_name}, _from, {names, refs}) do
    case names |> Map.get(workflow_name) do
      nil ->
        {:reply, :ok, {names, refs}}

      pid ->
        Process.exit(pid, :kill)
        {:reply, :ok, {names, refs}}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    {name, refs} = refs |> Map.pop(ref)
    names = names |> Map.delete(name)
    {:noreply, {names, refs}}
  end
end
