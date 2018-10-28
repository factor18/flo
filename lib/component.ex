defmodule Virta.Component do
  @callback inports :: [atom]
  @callback outports :: [atom]
  @callback run(any, %{}, %{}, pid) :: any
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
      def loop(requests, outport_args, instance_pid) do
        receive do
          { request_id, port, value } when port in @inports ->
            inport_args = Map.get(requests, request_id) || %{}
            inport_args = Map.put(inport_args, port, value)
            if(@inports |> Enum.all?(&(Map.has_key?(inport_args, &1)))) do
              run(request_id, inport_args, outport_args, instance_pid)
              |> dispatch(outport_args)
              loop(Map.delete(requests, request_id), outport_args, instance_pid)
            else
              loop(Map.put(requests, request_id, inport_args), outport_args, instance_pid)
            end
        end
      end

      @impl true
      def dispatch({ request_id, :noreply }, outport_args) do
        unless length(outport_args) == 0 do
          raise ":normal expected"
        end
      end

      @impl true
      def dispatch({ request_id, :normal, args }, outport_args) do
        Enum.map(outport_args, fn(outport_arg) ->
          %{ pid: pid, to: to, from: from } = outport_arg
          send(pid, { request_id, to, Map.get(args, from) })
        end)
      end

      defoverridable loop: 3
    end
  end
end
