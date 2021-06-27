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
          ref: "c",
          name: "delay",
          scope: "core",
          inports: %{
            "delay" => %Flo.Script{language: Flo.Script.Language.vanilla(), source: 1500}
          }
        },
        %Flo.Element{
          ref: "b",
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
            "delay" => %Flo.Script{language: Flo.Script.Language.vanilla(), source: 1000},
            "random_error" => %Flo.Script{
              language: Flo.Script.Language.vanilla(),
              source: true
            }
          }
        },
        %Flo.Element{
          ref: "f",
          name: "log",
          scope: "core",
          inports: %{
            "message" => %Flo.Script{
              language: Flo.Script.Language.vanilla(),
              source: "See you soon"
            }
          }
        },
        %Flo.Element{
          ref: "g",
          name: "log",
          scope: "core",
          inports: %{
            "message" => %Flo.Script{
              language: Flo.Script.Language.vanilla(),
              source: "Error!!!"
            }
          }
        }
      ],
      connections: [
        %Flo.Connection{
          source: "b",
          destination: "c",
          outcome: "default"
        },
        %Flo.Connection{
          source: "b",
          destination: "d",
          outcome: "default",
          condition: %Flo.Script{
            language: Flo.Script.Language.lua(),
            source: "return (math.floor(math.random() + 0.5) == 1)"
          }
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
        },
        %Flo.Connection{
          source: "e",
          destination: "g",
          outcome: "error"
        }
      ]
    }
    |> Flo.WorkflowRegistry.register()
  end

  def deregister() do
    Flo.WorkflowRegistry.deregister("test")
  end
end
