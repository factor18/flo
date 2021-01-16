defmodule Virta.Trigger do
  alias Virta.{Port, Pair, Task, Trigger, Registry}

  defstruct id: nil, ref: nil, outports: [], settings: []

  @type t() :: %__MODULE__{
    id: String.t,
    ref: String.t,
    outports: [Pair.t],
    settings: [Pair.t],
  }

  @callback name     :: String.t
  @callback outports :: [Port.t]
  @callback settings :: [Port.t]

  @callback deregister(String.t)            :: any()
  @callback register(%Trigger{}, [%Task{}]) :: any()

  defmacro __using__(_) do
    quote do
      use GenServer

      @behaviour Trigger

      def start_link(opts) do
        GenServer.start_link(__MODULE__, opts, name: __MODULE__)
      end

      @impl true
      def register(trigger, tasks) do
        GenServer.cast(__MODULE__, {:register, trigger, tasks})
      end

      @impl true
      def deregister(trigger_id) do
        GenServer.cast(__MODULE__, {:deregister, trigger_id})
      end

      @impl true
      def name, do: @name

      @impl true
      def outports, do: @outports

      @impl true
      def settings, do: @settings

      def execute(tasks) do
        context = %{tasks: %{}}
        tasks |> Enum.reduce(context, fn (task, context) ->
          inports = task.inports |> Enum.reduce(%{}, fn (pair, inports) ->
            inports |> Map.put(pair.name, pair.value)
          end)

          settings = task.settings |> Enum.reduce(%{}, fn (pair, settings) ->
            settings |> Map.put(pair.name, pair.value)
          end)

          task_context = %{inports: inports, outports: [], settings: settings}
          context = context |> Kernel.put_in([:tasks, task.id], task_context)

          component = Registry.component(task.ref)

          component.execute(task, context)
        end)
      end
    end
  end
end
