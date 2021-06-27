# Flo
Extensible workflow orchestration framework

### Installation

The package can be installed by adding `flo` to your list of dependencies in mix.exs:

```elixir
def deps do
  [{:flo, "~> 0.2"}]
end
```

Add to list of applications

```elixir
extra_applications: [:logger, :virta]
```

### Flo Framework
Flo exposes two [behaviours](https://elixir-lang.org/getting-started/typespecs-and-behaviours.html#behaviours) which can be used to create your own triggers and components
- `Component` is a behaviour for exposing common application logic in a reusable manner. Think of this as a function, such as write to database, publish to Kafka, etc that can be used by all Flo apps
- `Trigger` is a behaviour for building event-consumers that trigger workflows. The Kafka subscriber is an example of a trigger

 
 
#### Workflow is a combination of Trigger(s) and Components

- Triggers
  - Invokes the workflow
  - Can be invoked on its own (interval, cron etc) or by external events (http, queues etc)
- Components:
  - Definition of a task
  - Have a common interface which allows them to be interconnected
- Connections:
  - Defines the order of invokation
  - Can be conditional
  - Allows branching and merging

#### Component
Here is the implementation of a component which returns a dog pic of a given breed

`@name` and `@scope` are used for referencing this component in a workflow

`@inports` are a list of properties which can be consumed by the component

`@outports` defines the responses from this component, which can be consumed by other components

```elixir
defmodule Flo.Core.Component.Dog do
  alias Flo.{Port, Context, Outports}

  @name "dog"

  @scope "core"

  @inports [
    %Port{required: true, name: "breed", schema: %{"type" => "string"}}
  ]

  @outports %Outports{
    default: [
      %Port{name: "url", required: true, schema: %{"type" => "string"}}
    ],
    additional: %{
      "error" => [
        %Port{name: "message", required: true, schema: %{"type" => "string"}}
      ]
    }
  }

  use Flo.Component

  @impl true
  def run(%Context.Element{inports: inports}) do
    breed = inports |> Map.get("breed")

    url = "https://dog.ceo/api/breed/#{breed}/images/random/1"

    case HTTPoison.get(url) do
      {:ok, %{status_code: 200, body: body}} ->
        url = Jason.decode!(body) |> Map.get("message") |> Enum.at(0)
        %Context.Outports{outcome: "default", value: %{"url" => url}}
      _ ->
        %Context.Outports{outcome: "error", value: %{"message" => "No dog :-("}}
    end
  end
end

```
Now this component can be used in all of your workflows

#### Trigger
Here is the implementation of a trigger
`@name` and `@scope` are used for referencing this component in a workflow

`@configs` are a list of configs which can be consumed by the component

`@outports` defines the responses from this component, which can be consumed by other components

`initialize` function will be invoked with a callback function `start`

The `start` function will receive the outports map and will start the workflow whenever called

`Flo.Trigger` uses a `GenServer` behind the scenes, the return of `initialize` will be the return of GenServer's `init` callback

```elixir
defmodule Flo.Core.Trigger.AMQP do
  alias Flo.{Port, Context, Outports}

  @name "amqp"

  @scope "core"

  @configs [
    %Port{
      name: "queue",
      required: true,
      schema: %{"type" => "string"}
    },
    %Port{
      required: true,
      name: "connection_string",
      schema: %{"type" => "string"}
    }
  ]

  @outports %Outports{
    default: [
      %Port{
        required: true,
        name: "payload",
        schema: %{"type" => "string"}
      }
    ]
  }

  use Flo.Trigger

  @impl true
  def initialize(%Context.Stimulus{configs: configs}, start) do
    queue = configs |> Map.get("queue")
    connection_string = configs |> Map.get("connection_string")

    {:ok, conn} = AMQP.Connection.open(connection_string)
    {:ok, chan} = Channel.open(conn)

    AMQP.Queue.subscribe(chan, queue, fn payload, _meta ->
      start.(%{"payload" => payload})
    end)

    {:ok, %{start: start}}
  end
end

```

#### Workflow
![Image of Workflow](https://user-images.githubusercontent.com/11179580/123558812-dfe03f80-d7b5-11eb-8117-800168b87d15.png)

Here is a sample which implements the above workflow

`stimuli` are the list of triggers

`elements` are the list of components

`connections` form the flow between components

```elixir
%Flo.Workflow{
  name: "sample",
  description: "Sample Flow",
  stimuli: [
    %Flo.Stimulus{
      ref: "interval-trigger",
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
      ref: "dog-api",
      name: "dog",
      scope: "core",
      inports: %{
        "breed" => %Flo.Script{
          source: "shihtzu",
          language: Flo.Script.Language.vanilla(),
        }
      }
    },
    %Flo.Element{
      ref: "delay",
      name: "delay",
      scope: "core",
      inports: %{
        "delay" => %Flo.Script{
          source: 1500,
          language: Flo.Script.Language.vanilla(),
        }
      }
    },
    %Flo.Element{
      ref: "url-log",
      name: "log",
      scope: "core",
      inports: %{
        "delay" => %Flo.Script{
          source: "Check the photo {{elements.dog-api.outports.url.value}}",
          language: Flo.Script.Language.liquid(),
        }
      }
    },
    %Flo.Element{
      ref: "error-log",
      name: "log",
      scope: "core",
      inports: %{
        "delay" => %Flo.Script{
          source: "Error occured: {{elements.dog-api.outports.error.message.value}}",
          language: Flo.Script.Language.liquid(),
        }
      }
    },
    %Flo.Element{
      ref: "end-log",
      name: "log",
      scope: "core",
      inports: %{
        "delay" => %Flo.Script{
          source: "Done!!",
          language: Flo.Script.Language.vanilla(),
        }
      }
    }
  ],
  connections: [
    %Flo.Connection{
      source: "dog-api",
      outcome: "default",
      destination: "delay",
    },
    %Flo.Connection{
      source: "delay",
      outcome: "default",
      destination: "url-log",
    },
    %Flo.Connection{
      source: "dog-api",
      outcome: "error",
      destination: "error-log",
    },
    %Flo.Connection{
      source: "url-log",
      outcome: "default",
      destination: "end-log",
    },
    %Flo.Connection{
      source: "error-log",
      outcome: "default",
      destination: "end-log",
    }
  ]
}
|> Flo.WorkflowRegistry.register()
```

A component will be executed when all of the incoming connections are resolved

A connection can be in three states `INITIAL`, `RESOLVED`, `DISABLED`

If there are multiple connections to the component, the component will be executed only when all of the connections are in `RESOLVED` and `DISABLED` state and at least one connection should be in resolved state

If a connection is `DISABLED`, it will recursively disable all connections till a component is found which has a connection still in `INITIAL` or `RESOLVED` state

### TODO
- [x] Workflow execution
- [x] Branching and merging
- [x] Conditional branching
- [x] Multiple outcomes for components
- [ ] Loops
- [ ] Visual Editor
- [ ] Sub flows
- [ ] Error handling
- [ ] Documentation

### Contributing
Request a new feature by creating an issue or create a pull request with new features or fixes.

### License
`Flo` source code is released under Mozilla Public License 2.0.
Check [LICENSE](https://github.com/factor18/flo/blob/main/LICENSE) file for more information
