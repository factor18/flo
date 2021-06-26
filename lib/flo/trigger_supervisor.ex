defmodule Flo.TriggerSupervisor do
  use Supervisor, restart: :temporary

  alias Flo.{Workflow, Stimulus, TriggerRegistry}

  def start_link(%Workflow{} = workflow) do
    Supervisor.start_link(__MODULE__, workflow)
  end

  @impl true
  def init(%Workflow{} = workflow) do
    children =
      workflow
      |> Map.get(:stimuli)
      |> Enum.map(&trigger_spec(&1, workflow))

    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end

  defp trigger_spec(%Stimulus{scope: scope, name: name, ref: ref}, workflow) do
    trigger = TriggerRegistry.trigger(scope, name)

    %{
      id: trigger,
      start: {trigger, :start_link, [ref, workflow]}
    }
  end
end
