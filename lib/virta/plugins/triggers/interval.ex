defmodule Virta.Plugins.Trigger.Interval do
  alias Virta.{Port, Trigger}

  @name "virta:plugins:trigger:interval"

  @settings [
    %Port{
      name: "delay",
      type: "integer",
      required: true,
    },
  ]

  @outports []

  use Trigger

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:register, trigger}, state) do
    delay = Enum.find(trigger.settings, fn pair -> pair.name == "delay" end).value
    {:ok, ref} = :timer.send_interval(delay, {:trigger, trigger})
    {:noreply, state |> Map.put(trigger.id, ref)}
  end

  @impl true
  def handle_cast({:deregister, trigger_id}, state) do
    state |> Map.get(trigger_id) |> :timer.cancel
    {:noreply, state |> Map.delete(trigger_id)}
  end

  @impl true
  def handle_info({:trigger, _config}, state) do
    # TODO: pending
    {:noreply, state}
  end
end
