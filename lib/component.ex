defmodule Virta.Component do
  @callback inports :: [atom]
  @callback outports :: [atom]
  @callback loop(%{}, %{}, pid) :: any

  defmacro __using__(_) do
    quote do
      @behaviour Virta.Component

      @impl true
      def inports, do: @inports

      @impl true
      def outports, do: @outports

      @impl true
      def loop(inport_args, outport_args, instance_pid) do
        receive do
          { port, value } when port in @inports ->
            inport_args = Map.put(inport_args, port, value)
            if(@inports |> Enum.all?(&(Map.has_key?(inport_args, &1)))) do
              run(inport_args, outport_args, instance_pid)
            else
              loop(inport_args, outport_args, instance_pid)
            end
        end
      end

      defoverridable loop: 3
    end
  end
end
