defmodule Flo.Executor do
  alias Flo.{Graph, Context, Workflow, ComponentRegistry, ExecutionContext}

  def start(%Workflow{} = workflow, %Context{} = context, strategy: strategy) do
    graph = Graph.new(workflow)
    root = Graph.root(graph)

    execution_context = %ExecutionContext{
      graph: graph,
      context: context,
      workflow: workflow,
      strategy: strategy,
      queue: [root]
    }

    do_execute(execution_context)
  end

  def step(%ExecutionContext{queue: []} = execution_context) do
    execution_context
  end

  def step(%ExecutionContext{graph: graph, workflow: workflow, queue: [current | next], context: context} = execution_context) do
    element =
      workflow.elements
      |> Enum.find(fn element -> element.ref == current end)

    component = ComponentRegistry.component(element.scope, element.name)
    context = context |> Context.resolve(element)
    outports = component.run(context |> Kernel.get_in([:elements, element.ref]))
    context = context |> Context.update_outports(element, outports)
    to_enqueue = graph |> Graph.next(current)

    execution_context
    |> Map.put(:context, context)
    |> Map.put(:queue, next ++ to_enqueue)
  end

  defp do_execute(%ExecutionContext{queue: []} = execution_context) do
    execution_context
  end

  defp do_execute(execution_context) do
    step(execution_context) |> do_execute()
  end
end
