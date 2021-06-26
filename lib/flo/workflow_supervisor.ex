defmodule Flo.WorkflowSupervisor do
  use DynamicSupervisor

  alias Flo.{Workflow, TriggerSupervisor}

  # Client

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def start_workflow(%Workflow{} = workflow) do
    spec = workflow_instance_supervisor_spec(workflow)
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  # Server

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  # Helpers

  defp workflow_instance_supervisor_spec(workflow) do
    %{
      id: TriggerSupervisor,
      start: {TriggerSupervisor, :start_link, [workflow]},
      type: :supervisor,
      restart: :temporary
    }
  end
end
