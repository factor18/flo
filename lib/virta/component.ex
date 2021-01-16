defmodule Virta.Component do
  alias Virta.{Port, Component}

  @callback name     :: String.t
  @callback inports  :: [Port.t]
  @callback outports :: [Port.t]
  @callback settings :: [Port.t]

  @callback run(%{}, %{}, %{}) :: %{}

  defmacro __using__(_) do
    quote do
      @behaviour Component

      @impl true
      def name, do: @name

      @impl true
      def inports,  do: @inports

      @impl true
      def outports, do: @outports

      @impl true
      def settings, do: @settings

      def execute(context) do

      end
    end
  end
end
