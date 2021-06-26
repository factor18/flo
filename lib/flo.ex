defmodule Flo do
  @moduledoc """
  Documentation for `Flo`.
  """

  def register do
    %Flo.Workflow{
      name: "test",
      description: "Testing",
      stimuli: [
        %Flo.Stimulus{
          ref: "a",
          inports: %{},
          scope: "core",
          name: "interval",
          configs: %{"delay" => %Flo.Script{language: Flo.Script.Language.vanilla(), source: 5000}}
        }
      ],
      elements: [
        %Flo.Element{
          ref: "b",
          name: "delay",
          scope: "core",
          inports: %{"delay" => %Flo.Script{language: Flo.Script.Language.vanilla(), source: 3000}}
        },
        %Flo.Element{
          ref: "c",
          name: "log",
          scope: "core",
          inports: %{
            "message" => %Flo.Script{language: Flo.Script.Language.liquid(), source: "{{\"Hello World\"}}"}
          }
        }
      ],
      connections: [
        %Flo.Connection{
          source: "a",
          destination: "b"
        },
        %Flo.Connection{
          source: "b",
          destination: "c",
          condition: %Flo.Script{language: Flo.Script.Language.lua(), source: "return (math.floor(math.random() + 0.5) == 1)"}
        }
      ]
    }
    |> Flo.WorkflowRegistry.register()
  end

  def deregister() do
    Flo.WorkflowRegistry.deregister("test")
  end
end
