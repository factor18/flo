defmodule Flo.Core.Component.Log do
  alias Flo.{Port, Context, Outports}

  @name "log"

  @scope "core"

  @inports [
    %Port{
      required: true,
      name: "message",
      schema: %{"type" => "string"}
    }
  ]

  @outports %Outports{}

  use Flo.Component

  def run(%Context.Element{inports: inports}) do
    inports
    |> Map.get("message")
    |> Logger.info()

    %{}
  end
end
