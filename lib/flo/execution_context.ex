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

  use Construct do
    field(:graph, :any)
    field(:context, Flo.Context)
    field(:workflow, Flo.Workflow)
    field(:queue, {:array, :string})
    field(:connections, {:map, Flo.ExecutionContext.Connection})
  end

  def new(workflow, context) do
    graph = Flo.Graph.new(workflow)
    root = Flo.Graph.root(graph)

    connections =
      workflow.connections
      |> Enum.reduce(%{}, fn connection, acc ->
        status =
          if connection.source == root do
            "PENDING"
          else
            "INITIAL"
          end

        c = %Flo.ExecutionContext.Connection{
          status: status,
          source: connection.source,
          outcome: connection.outcome,
          destination: connection.destination
        }

        acc |> Map.put(Flo.Connection.id(connection), c)
      end)

    %Flo.ExecutionContext{
      graph: graph,
      queue: [root],
      context: context,
      workflow: workflow,
      connections: connections
    }
  end

  def can_execute?(%Flo.ExecutionContext{graph: graph, connections: connections}, current) do
    statuses =
      Flo.Graph.prev_connections(graph, current)
      |> Enum.map(fn edge ->
        connections |> Map.get(Flo.Connection.id(edge.v1, edge.v2)) |> Map.get(:status)
      end)

    statuses |> Enum.empty?() ||
      (statuses |> Enum.all?(&(&1 != "INITIAL")) && statuses |> Enum.member?("RESOLVED"))
  end

  def disabled?(%Flo.ExecutionContext{graph: graph, connections: connections}, current) do
    statuses =
      Flo.Graph.prev_connections(graph, current)
      |> Enum.map(fn edge ->
        connections |> Map.get(Flo.Connection.id(edge.v1, edge.v2)) |> Map.get(:status)
      end)

    !(statuses |> Enum.empty?()) && statuses |> Enum.all?(&(&1 == "DISABLED"))
  end

  def resolve(%Flo.ExecutionContext{graph: graph} = context, current) do
    Flo.Graph.next_connections(graph, current)
    |> Enum.reduce(context, fn edge, context ->
      context
      |> Kernel.put_in([:connections, Flo.Connection.id(edge.v1, edge.v2), :status], "RESOLVED")
    end)
  end
end
