defmodule Flo.Trigger do
  @callback initialize(%Flo.Context.Stimulus{}, Function) :: {:ok, any()}

  defmacro __using__(_) do
    quote do
      require Logger

      use GenServer

      @behaviour Flo.Trigger

      # Client

      @spec name() :: String.t()
      def name, do: @name

      @spec scope() :: String.t()
      def scope, do: @scope

      @spec configs() :: [%Flo.Port{}]
      def configs, do: @configs

      @spec outports() :: %Flo.Outports{}
      def outports, do: @outports

      def start_link(ref, %Flo.Workflow{} = workflow) do
        GenServer.start_link(__MODULE__, {ref, workflow})
      end

      # Server

      def init({ref, workflow} = config) do
        context = Flo.Context.new(ref, workflow)

        execute = fn outports ->
          context =
            context
            |> Kernel.put_in([:stimulus, :outports], outports)

          start(workflow, context)
        end

        context.stimulus |> initialize(execute)
      end

      def initialize(config), do: {:ok, config}

      defp start(workflow, context) do
        Flo.Executor.start(workflow, context, strategy: :sync)
      end

      defoverridable initialize: 1
    end
  end
end
