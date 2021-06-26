defmodule Flo.Core.Component.Delay do
  alias Flo.{Port, Context, Outports}

  @name "delay"

  @scope "core"

  @inports [
    %Port{
      name: "delay",
      required: true,
      schema: %{"type" => "integer", "minimum" => 0}
    }
  ]

  @outports %Outports{}

  use Flo.Component

  def run(%Context.Element{inports: inports}) do
    inports
    |> Map.get("delay")
    |> :timer.sleep()

    %{}
  end
end
