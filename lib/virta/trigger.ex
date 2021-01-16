defmodule Virta.Trigger do
  alias Virta.{Port, Trigger, Pair}

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

  @callback register(%{})   :: any()
  @callback deregister(%{}) :: any()

  defmacro __using__(_) do
    quote do
      use GenServer

      @behaviour Trigger

      def start_link(opts) do
        GenServer.start_link(__MODULE__, opts, name: __MODULE__)
      end

      @impl true
      def register(trigger) do
        GenServer.cast(__MODULE__, {:register, trigger})
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
    end
  end
end
