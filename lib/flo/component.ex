defmodule Flo.Component do
  @callback run(%Flo.Context.Element{}) :: %Flo.Context.Outports{}

  defmacro __using__(_) do
    quote do
      require Logger

      @behaviour Flo.Component

      @spec name() :: String.t()
      def name, do: @name

      @spec scope() :: String.t()
      def scope, do: @scope

      @spec inports() :: [%Flo.Port{}]
      def inports, do: @inports

      @spec outports() :: %Flo.Outports{}
      def outports, do: @outports
    end
  end
end
