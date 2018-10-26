defmodule Virta.Component do
  @callback inports :: [atom]
  @callback outports :: [atom]
  @callback run(%{}, %{}, pid) :: any
  @callback dispatch(any, %{}) :: any
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
              |> dispatch(outport_args)
            else
              loop(inport_args, outport_args, instance_pid)
            end
        end
      end

      @impl true
      def dispatch({ :noreply }, outport_args) do
        unless length(outport_args) == 0 do
          raise ":normal or :deflate expected"
        end
      end

      @impl true
      def dispatch({ :normal, args }, outport_args) do
        Enum.map(outport_args, fn(outport_arg) ->
          %{ pid: pid, to: to, from: from } = outport_arg
          send(pid, { to, Map.get(args, from) })
        end)
      end

      @impl true
      def dispatch({ :deflate, value }, outport_args) do
        Enum.map(outport_args, fn(outport_arg) ->
          %{ pid: pid, to: to } = outport_arg
          send(pid, { to, value })
        end)
      end

      defoverridable loop: 3
    end
  end
end
