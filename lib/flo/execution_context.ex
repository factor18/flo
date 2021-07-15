defmodule Flo.ExecutionContext do
  @moduledoc false

  @derive Jason.Encoder

  use Accessible

  defmodule Status do
    @moduledoc false

    @behaviour Construct.Type

    @entries ["INITIAL", "RESOLVED", "DISABLED"]

    @entries
    |> Enum.each(fn entry ->
      def unquote(:"#{entry |> String.downcase() |> Macro.underscore()}")() do
        unquote(entry)
      end
    end)

    def entries, do: @entries

    def cast(value) when value in @entries do
      {:ok, value}
    end

    def cast(_), do: :error
  end

  defmodule Connection do
    @moduledoc false

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
    @moduledoc false

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
        |> Map.get(Flo.Connection.id(edge.v1, edge.v2, edge.label))
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

  def not_executable?(execution_context, current) do
    element_status =
      execution_context.elements
      |> Map.get(current)
      |> Map.get(:status)

    element_status != "INITIAL" || execution_context |> disabled?(current)
  end

  def disabled?(execution_context, current) do
    statuses =
      Flo.Graph.prev_connections(execution_context.graph, current)
      |> Enum.map(fn edge ->
        execution_context.connections
        |> Map.get(Flo.Connection.id(edge.v1, edge.v2, edge.label))
        |> Map.get(:status)
      end)

    !(statuses |> Enum.empty?()) && statuses |> Enum.all?(&(&1 == "DISABLED"))
  end

  def resolve(%Flo.ExecutionContext{workflow: workflow} = context, current, outcome) do
    # TODO: refactor
    workflow.connections
    |> Enum.filter(fn connection -> connection.source == current end)
    |> Enum.reduce(context, fn connection, context ->
      enabled = connection.outcome == outcome

      enabled =
        if enabled do
          if connection.condition do
            {:ok, result} = Flo.Script.execute(connection.condition, context.context)
            !!result
          else
            true
          end
        else
          enabled
        end

      status =
        if enabled do
          "RESOLVED"
        else
          "DISABLED"
        end

      context = context |> update_connection_status(Flo.Connection.id(connection), status)

      if status == "DISABLED" do
        disable_recursively(context, connection.destination)
      else
        context
      end
    end)
    |> Kernel.put_in([:elements, current, :status], "RESOLVED")
  end

  defp update_connection_status(context, connection_id, status) do
    context
    |> Kernel.put_in(
      [
        :connections,
        connection_id,
        :status
      ],
      status
    )
  end

  defp disable_recursively(context, destination) do
    if disabled?(context, destination) do
      context.graph
      |> Graph.out_edges(destination)
      |> Enum.reduce(context, fn edge, context ->
        context
        |> update_connection_status(Flo.Connection.id(edge.v1, edge.v2, edge.label), "DISABLED")
        |> disable_recursively(edge.v2)
      end)
    else
      context
    end
  end
end
