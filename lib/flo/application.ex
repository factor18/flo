defmodule Flo.Application do
  @moduledoc false

  use Application

  alias Flo.{TriggerRegistry, ComponentRegistry, WorkflowRegistry, WorkflowSupervisor}

  @impl true
  def start(_type, _args) do
    children = [
      trigger_registry_spec(),
      component_registry_spec(),
      workflow_supervisor_spec(),
      workflow_registry_spec()
    ]

    opts = [strategy: :one_for_one, name: Flo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp trigger_registry_spec do
    %{
      id: TriggerRegistry,
      start: {TriggerRegistry, :start_link, []}
    }
  end

  defp component_registry_spec do
    %{
      id: ComponentRegistry,
      start: {ComponentRegistry, :start_link, []}
    }
  end

  defp workflow_supervisor_spec do
    %{
      id: WorkflowSupervisor,
      start: {WorkflowSupervisor, :start_link, []}
    }
  end

  defp workflow_registry_spec do
    %{
      id: WorkflowRegistry,
      start: {WorkflowRegistry, :start_link, []}
    }
  end
end
