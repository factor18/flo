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
          configs: %{
            "delay" => %Flo.Script{language: Flo.Script.Language.vanilla(), source: 5000}
          }
        }
      ],
      elements: [
        %Flo.Element{
          ref: "b",
          name: "delay",
          scope: "core",
          inports: %{
            "delay" => %Flo.Script{language: Flo.Script.Language.vanilla(), source: 3000}
          }
        },
        %Flo.Element{
          ref: "c",
          name: "log",
          scope: "core",
          inports: %{
            "message" => %Flo.Script{
              language: Flo.Script.Language.liquid(),
              source: "{{\"Hello World\"}}"
            }
          }
        },
        %Flo.Element{
          ref: "d",
          name: "log",
          scope: "core",
          inports: %{
            "message" => %Flo.Script{
              language: Flo.Script.Language.liquid(),
              source: "{{\"Bye\"}}"
            }
          }
        },
        %Flo.Element{
          ref: "e",
          name: "delay",
          scope: "core",
          inports: %{
            "delay" => %Flo.Script{language: Flo.Script.Language.vanilla(), source: 1000}
          }
        },
        %Flo.Element{
          ref: "f",
          name: "log",
          scope: "core",
          inports: %{
            "message" => %Flo.Script{
              language: Flo.Script.Language.vanilla(),
              source: "{{\"Hola\"}}"
            }
          }
        }
      ],
      connections: [
        %Flo.Connection{
          source: "b",
          destination: "c",
          outcome: "default",
          condition: %Flo.Script{
            language: Flo.Script.Language.lua(),
            source: "return (math.floor(math.random() + 0.5) == 1)"
          }
        },
        %Flo.Connection{
          source: "b",
          destination: "d",
          outcome: "default"
        },
        %Flo.Connection{
          source: "d",
          destination: "e",
          outcome: "default"
        },
        %Flo.Connection{
          source: "c",
          destination: "e",
          outcome: "default"
        },
        %Flo.Connection{
          source: "e",
          destination: "f",
          outcome: "default"
        }
      ]
    }
    |> Flo.WorkflowRegistry.register()
  end

  def deregister() do
    Flo.WorkflowRegistry.deregister("test")
  end
end
