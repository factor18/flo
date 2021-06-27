defmodule Flo.Executor do
  alias Flo.{Graph, Context, Workflow, ComponentRegistry, ExecutionContext}

  def start(%Workflow{} = workflow, %Context{} = context) do
    ExecutionContext.new(workflow, context) |> do_execute()
  end

  def step(%ExecutionContext{queue: []} = execution_context) do
    execution_context
  end

  def step(%ExecutionContext{queue: [current | next]} = execution_context) do
    if ExecutionContext.can_execute?(execution_context, current) do
      element =
        execution_context.workflow.elements
        |> Enum.find(fn element -> element.ref == current end)

      component = ComponentRegistry.component(element.scope, element.name)
      context = execution_context.context |> Context.resolve(element)
      outports = component.run(context |> Kernel.get_in([:elements, element.ref]))
      context = context |> Context.update_outports(element, outports)
      to_enqueue = execution_context.graph |> Graph.next(current)

      execution_context
      |> Map.put(:context, context)
      |> ExecutionContext.resolve(current)
      |> Map.put(:queue, next ++ to_enqueue)
    else
      if ExecutionContext.disabled?(execution_context, current) do
        execution_context
        |> Map.put(:queue, next)
        |> step()
      else
        execution_context
        |> Map.put(:queue, next ++ [current])
        |> step()
      end
    end
  end

  defp do_execute(%ExecutionContext{queue: []} = execution_context) do
    execution_context
  end

  defp do_execute(execution_context) do
    step(execution_context) |> do_execute()
  end
end
