defmodule Flo.Core.Trigger.Interval do
  alias Flo.{Port, Context, Outports}

  @name "interval"

  @scope "core"

  @configs [
    %Port{
      required: true,
      name: "message",
      schema: %{"type" => "string"}
    }
  ]

  @outports %Outports{}

  use Flo.Trigger

  @impl true
  def initialize(%Context.Stimulus{configs: configs}, start) do
    timer_ref =
      configs
      |> Map.get("delay")
      |> :timer.send_interval(:execute)

    {:ok, %{timer_ref: timer_ref, start: start}}
  end

  @impl true
  def handle_info(:execute, %{start: start} = state) do
    start.(%{})
    {:noreply, state}
  end
end
