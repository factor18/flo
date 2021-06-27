defmodule Flo.ExecutionContext do
  @derive Jason.Encoder

  use Accessible

  defmodule Status do
    @behaviour Construct.Type

    @entries ["INITIAL", "RESOLVED", "DISABLED"]

    @entries
    |> Enum.each(fn entry ->
      def unquote(:"#{entry |> String.downcase() |> Macro.underscore()}")() do
        unquote(entry)
      end
    end)

    def cast(value) when value in @entries do
      {:ok, value}
    end

    def cast(_), do: :error
  end

  defmodule Connection do
    @derive Jason.Encoder

    use Accessible

    use Construct do
      field(:source, :string)
      field(:outcome, :string)
      field(:destination, :string)
      field(:status, Flo.ExecutionContext.Status)
    end
  end

  defmodule Element do
    @derive Jason.Encoder

    use Accessible

    use Construct do
      field(:status, Flo.ExecutionContext.Status)
    end
  end

  use Construct do
    field(:graph, :any)
    field(:context, Flo.Context)
    field(:workflow, Flo.Workflow)
    field(:queue, {:array, :string})
    field(:elements, {:map, Flo.ExecutionContext.Element})
    field(:connections, {:map, Flo.ExecutionContext.Connection})
  end

  def new(workflow, context) do
    graph = Flo.Graph.new(workflow)
    root = Flo.Graph.root(graph)

    connections =
      workflow.connections
      |> Enum.reduce(%{}, fn connection, acc ->
        c = %Flo.ExecutionContext.Connection{
          status: "INITIAL",
          source: connection.source,
          outcome: connection.outcome,
          destination: connection.destination
        }

        acc |> Map.put(Flo.Connection.id(connection), c)
      end)

    elements =
      workflow.elements
      |> Enum.reduce(%{}, fn element, acc ->
        acc |> Map.put(element.ref, %Flo.ExecutionContext.Element{status: "INITIAL"})
      end)

    %Flo.ExecutionContext{
      graph: graph,
      queue: [root],
      context: context,
      elements: elements,
      workflow: workflow,
      connections: connections
    }
  end

  def can_execute?(execution_context, current) do
    statuses =
      Flo.Graph.prev_connections(execution_context.graph, current)
      |> Enum.map(fn edge ->
        execution_context.connections
        |> Map.get(Flo.Connection.id(edge.v1, edge.v2))
        |> Map.get(:status)
      end)

    element_status =
      execution_context.elements
      |> Map.get(current)
      |> Map.get(:status)

    atleast_one_resolved =
      statuses
      |> Enum.all?(&(&1 != "INITIAL")) && statuses |> Enum.member?("RESOLVED")

    element_status == "INITIAL" && (statuses |> Enum.empty?() || atleast_one_resolved)
  end

  def disabled?(execution_context, current) do
    statuses =
      Flo.Graph.prev_connections(execution_context.graph, current)
      |> Enum.map(fn edge ->
        execution_context.connections
        |> Map.get(Flo.Connection.id(edge.v1, edge.v2))
        |> Map.get(:status)
      end)

    element_status =
      execution_context.elements
      |> Map.get(current)
      |> Map.get(:status)

    element_status != "INITIAL" ||
      (!(statuses |> Enum.empty?()) && statuses |> Enum.all?(&(&1 == "DISABLED")))
  end

  def resolve(%Flo.ExecutionContext{graph: graph} = context, current) do
    Flo.Graph.next_connections(graph, current)
    |> Enum.reduce(context, fn edge, context ->
      context
      |> Kernel.put_in([:connections, Flo.Connection.id(edge.v1, edge.v2), :status], "RESOLVED")
    end)
    |> Kernel.put_in([:elements, current, :status], "RESOLVED")
  end
end
