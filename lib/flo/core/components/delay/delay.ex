defmodule Flo.Core.Component.Delay do
  alias Flo.{Port, Context, Outports}

  @name "delay"

  @scope "core"

  @inports [
    %Port{
      name: "delay",
      required: true,
      schema: %{"type" => "integer", "minimum" => 0}
    },
    %Port{
      required: true,
      name: "random_error",
      schema: %{"type" => "boolean"}
    }
  ]

  @outports %Outports{additional: %{"error" => []}}

  use Flo.Component

  def run(%Context.Element{inports: inports}) do
    inports
    |> Map.get("delay")
    |> :timer.sleep()

    outcome =
      if inports |> Map.get("random_error") do
        ["default", "error"] |> Enum.random()
      else
        "default"
      end

    %Context.Outports{outcome: outcome, value: %{}}
  end
end
