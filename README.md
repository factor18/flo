# Virta

### Description
FBP-ish implementation in elixir

### Architecture
Virta is made up of the following

#### Component
The core of virta is a Component. The `Component` behaviour abstracts out the message passing and messages aggregation.

Lets look at a code example:
Here is a simple component which inspects the data passed to it.

```elixir
defmodule Virta.Sample.Echo do
  @inports [:data]
  @outports []

  use Virta.Component

  @impl true
  def run(request_id, inport_args, _outport_args, _instance_pid) do
    value = Map.get(inport_args, :data)
    IO.inspect(value)
    { request_id, :noreply }
  end
end

# Start the component
{:ok, pid} = Task.start_link(Virta.Sample.Echo, :loop, [%{}, %{}, self()])

# Send sample data
send(pid, {1, :data, 10 })
#=> 10
```

Virta provides three special components `Virta.Core.In`, `Virta.Core.Out` and `Virta.Core.Workflow` which have special use cases which are discussed below.

#### Workflow
Components can be connected to each other to form a workflow using a Graph.

Each `Component` in a workflow is called a `Node` and is represented using a struct `Virta.Node` And connections between nodes is called an `Edge` and is represented using a struct `Virta.EdgeData`.

A sample node looks like:
`%Node{ module: "Virta.Sample.Echo", id: 0 }`
`module` represents the `component` and `id` is used to uniquely identify the node in the graph.

Lets look at a sample workflow:

```elixir
    alias Virta.Node
    alias Virta.EdgeData

    workflow = Graph.new(type: :directed)
    |> Graph.add_edge(
      %Node{ module: "Virta.Core.In", id: 0 },
      %Node{ module: "Virta.Sample.Echo", id: 1 },
      label: %EdgeData{ from: :data, to: :data }
    )
```

Here `%EdgeData{ from: :data, to: :data }` states that the port :data from `Virta.Core.In` is connected to the port :data of `Virta.Sample.Echo`

A workflow defined in a graph needs to be converted into an actual workflow before it can be used. It can be achieved using `Virta.Instance`.

#### Instance
`Virta.Instance` is implemented using `GenServer`
It takes a graph and initializes the nodes as processes. And establishes the connections between the processes.

It provides a `execute` method to send messages to the workflow components.

Lets see a code example for the workflow which we created earlier

```elixir
alias Virta.Node
alias Virta.EdgeData
alias Virta.Instance

sample = Graph.new(type: :directed)
|> Graph.add_edge(
  %Node{ module: "Virta.Core.In", id: 0 },
  %Node{ module: "Virta.Sample.Echo", id: 1 },
  label: %EdgeData{ from: :data, to: :data }
)

# Start the GenServer
{ :ok, pid } = Instance.start_link(sample)

data = %{
  %Node{ module: "Virta.Core.In", id: 0 } => [{ 1, :data, 10 }]
}

# Send the message with value `10` to port `:data` with request_id `1`
Instance.execute(pid, data)
#=> 10
#=> :ok
```

Here the component `Virta.Core.In` passes the data from its inport `:data` to the the inport of `Virta.Sample.Echo`. Once the data is received, `Virta.Sample.Echo` executes the `run` method, which prints `10`

The component `Virta.Core.In` is used to represent the inports of the workflow.

#### Registry
`Virta.Registry` is implemented using `GenServer`
It takes a name and a graph and creates a pool of instances using :poolboy, which can then be used for concurrency.

Lets create a new workflow which does more than just echo-ing:
```elixir
alias Virta.Node
alias Virta.Registry
alias Virta.EdgeData
alias Virta.Instance

adder = Graph.new(type: :directed)
|> Graph.add_edge(
  %Node{ module: "Virta.Core.In", id: 0 },
  %Node{ module: "Virta.Math.Add", id: 1 },
  label: %EdgeData{ from: :addend, to: :addend }
)
|> Graph.add_edge(
  %Node{ module: "Virta.Core.In", id: 0 },
  %Node{ module: "Virta.Math.Add", id: 1 },
  label: %EdgeData{ from: :augend, to: :augend }
)
|> Graph.add_edge(
  %Node{ module: "Virta.Math.Add", id: 1 },
  %Node{ module: "Virta.Core.Out", id: 2 },
  label: %EdgeData{ from: :sum, to: :sum }
)

# Register the graph with the name 'adder'
Registry.register("adder", adder)
```

Here we are using `Virta.Math.Add` component which has two inports `:addend` and `:augend` and has one outport `:sum` which all expect a number

When both the ports receive the message, the sum of the two numbers is calculated and a message is dispatched on to the ports connected to the outport `:sum`

The component `Virta.Core.Out` waits for messages and then sends a message to the process which invoked the workflow.

Lets see this in action

```elixir
Registry.get("adder")
#=> #PID<0.167.0>

data = %{
  %Node{ module: "Virta.Core.In", id: 0 } => [
    { 1, :augend, 10 }, { 1, :addend, 20 }
  ]
}

:poolboy.transaction(String.to_existing_atom("adder"), fn (server) ->
  Instance.execute(server, data)
  receive do
    message -> IO.inspect(message)
    # {1, %{sum: 30}}
  end
end)
```

### Invoking a workflow within a workflow:
`Virta.Core.Worflow` is a special component which allows us to invoke a different workflow from the current workflow. This allows us to reuse workflows.

A workflow node can be represented as
`%Node{ module: "Virta.Core.Workflow", id: 1, ref: "adder" }`
Notice the `:ref` property. It refers to the registered workflow with the name `adder`.

Lets see a code example for a complex worflow which invokes other workflows:
```elixir
alias Virta.Node
alias Virta.Registry
alias Virta.EdgeData
alias Virta.Instance

adder = Graph.new(type: :directed)
|> Graph.add_edge(
  %Node{ module: "Virta.Core.In", id: 0 },
  %Node{ module: "Virta.Math.Add", id: 1 },
  label: %EdgeData{ from: :addend, to: :addend }
)
|> Graph.add_edge(
  %Node{ module: "Virta.Core.In", id: 0 },
  %Node{ module: "Virta.Math.Add", id: 1 },
  label: %EdgeData{ from: :augend, to: :augend }
)
|> Graph.add_edge(
  %Node{ module: "Virta.Math.Add", id: 1 },
  %Node{ module: "Virta.Core.Out", id: 2 },
  label: %EdgeData{ from: :sum, to: :sum }
)

multiplier = Graph.new(type: :directed)
|> Graph.add_edge(
  %Node{ module: "Virta.Core.In", id: 0 },
  %Node{ module: "Virta.Math.Multiply", id: 1 },
  label: %EdgeData{ from: :multiplicand, to: :multiplicand }
)
|> Graph.add_edge(
  %Node{ module: "Virta.Core.In", id: 0 },
  %Node{ module: "Virta.Math.Multiply", id: 1 },
  label: %EdgeData{ from: :multiplier, to: :multiplier }
)
|> Graph.add_edge(
  %Node{ module: "Virta.Math.Multiply", id: 1 },
  %Node{ module: "Virta.Core.Out", id: 2 },
  label: %EdgeData{ from: :product, to: :product }
)

complex_graph = Graph.new(type: :directed)
|> Graph.add_edge(
  %Node{ module: "Virta.Core.In", id: 0 },
  %Node{ module: "Virta.Core.Workflow", id: 1, ref: "adder" },
  label: %EdgeData{ from: :augend, to: :augend }
)
|> Graph.add_edge(
  %Node{ module: "Virta.Core.In", id: 0 },
  %Node{ module: "Virta.Core.Workflow", id: 1, ref: "adder" },
  label: %EdgeData{ from: :addend, to: :addend }
)
|> Graph.add_edge(
  %Node{ module: "Virta.Core.Workflow", id: 1, ref: "adder" },
  %Node{ module: "Virta.Core.Workflow", id: 2, ref: "multiplier" },
  label: %EdgeData{ from: :sum, to: :multiplicand }
)
|> Graph.add_edge(
  %Node{ module: "Virta.Core.Workflow", id: 1, ref: "adder" },
  %Node{ module: "Virta.Core.Workflow", id: 2, ref: "multiplier" },
  label: %EdgeData{ from: :sum, to: :multiplier }
)
|> Graph.add_edge(
  %Node{ module: "Virta.Core.Workflow", id: 2, ref: "multiplier" },
  %Node{ module: "Virta.Core.Out", id: 3 },
  label: %EdgeData{ from: :product, to: :product }
)

Registry.register("adder", adder)
Registry.register("multiplier", multiplier)
Registry.register("complex_graph", complex_graph)

name = "complex_graph"
Registry.get(name)
#=> #PID<0.572.0>

data = %{
  %Node{ module: "Virta.Core.In", id: 0 } => [
    { 1, :augend, 10 }, { 1, :addend, 20 }
  ]
}

:poolboy.transaction(String.to_existing_atom(name), fn (server) ->
  Instance.execute(server, data)
  receive do
    message -> IO.inspect(message)
    # {1, %{product: 900}}
  end
end)
```

### Status

The project is still under development. This can be considered just as a 'proof of concept'.

### Contributing
Request a new feature by creating an issue or create a pull request with new features or fixes.

### License
`Virta` source code is released under Apache 2 License.
Check [LICENSE](https://github.com/sarat1669/virta/blob/master/LICENSE) file for more information
