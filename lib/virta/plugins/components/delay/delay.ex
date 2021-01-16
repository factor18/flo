defmodule Virta.Plugins.Component.Delay do
  alias Virta.{Port, Component}

  @name "virta:plugins:component:delay"

  @settings [
    %Port{
      name: "delay",
      required: true,
      type: "integer",
    }
  ]

  @inports  []

  @outports []

  use Component

  @impl true
  def run(_inports, settings, _context) do
    delay = settings["delay"]

    :timer.sleep(delay)

    %{}
  end
end
