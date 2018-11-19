# Virta
Flow based programming for elixir

[source](https://github.com/sarat1669/virta) | [documentation](https://hexdocs.pm/virta/Virta.html)

### Installation
Virta requires Elixir v1.6. Just add :virta to your list of dependencies in mix.exs:
```elixir
def deps do
  [{:virta, "~> 0.1"}]
end
```

Ensure `:virta` is started before your application:
```elixir
def application do
  [applications: [:virta]]
end
```

### Usage
Virta is a Flow-Based Programming environment for Elixir. In flow-based programs, the logic of your application is defined as an acyclic graph. The nodes of the graph are instances of components, the edges define the connections between them.

The components react to the incoming mesages. When a component receives a message, it performs a predefined operation and sends its result as a message to its outports.

A graph needs to be registered on the registry before it can be executed. A registered graph is called a Workflow.

#### Creating components
The components are modules which implement the `Virta.Component` behaviour.

A component communicates with other components using ports. The component waits for message to arrive on each inport. Once messages are received on all the in-ports, it executes the component functional logic.

`Virta.Component` also provides a `__using__` macro which injects the bootstrap code for creating a component.

Lets look at a code example:

```elixir
defmodule Echo do
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
```

Here the component doesn't have any outports, hence it returns `{ request_id, :noreply }`
If the component has outports, it needs to return `{ request_id, :reply, value }`. Where value is a Map with outport names as the keys with their respective values. Lets see this in action:

```elixir
defmodule Add do
  @inports [ :addend, :augend ]
  @outports [ :sum ]

  use Virta.Component

  @impl true
  def run(request_id, inport_args, _outport_args, _instance_pid) do
    value = Map.get(inport_args, :augend) + Map.get(inport_args, :addend)
    { request_id, :reply, %{ sum: value } }
  end
end
```

Once the execution is done, the messages are passed on to the outports (if any).

Virta provides three in-built components which are useful for creating workflows.
* `Virta.Core.In`
* `Virta.Core.Out`
* `Virta.Core.Workflow`

The purpose of these components are discussed in the below sections.

#### Creating workflows
Components can be connected to each other to form a an acyclic graph (check [libgraph](https://hexdocs.pm/libgraph/api-reference.html) for more details on the implementation).

A node in a is represented by `%Virta.Node{}` and the label of the edge connecting the nodes should be `%Virta.EdgeData{}`, which has the ports to which the edge needs to be connected.

Lets look at a simple example:

```elixir
alias Virta.Node
alias Virta.EdgeData

workflow = Graph.new(type: :directed)
|> Graph.add_vertex(%Node{ module: Virta.Core.In, id: 0 })
|> Graph.add_vertex(%Node{ module: Echo, id: 1 })
|> Graph.add_edge(
  %Node{ module: Virta.Core.In, id: 0 },
  %Node{ module: Echo, id: 1 },
  label: %EdgeData{ from: :data, to: :data }
)
```

###### NOTE:
* Adding a vertex is optional. A graph can be purely constructed using edges.
* Here we are using an in-built component `Virta.Core.In`. Every workflow should have this component as the entry point.
* `Virta.Core.In` is being used internally for workflow port discovery, which enables invoking a workflow from another workflow (discussed in the sections below).
* Any workflow which needs to return a value (or values) needs to use `Virta.Core.Out` as the last node in the graph. It acts as a collector and sends a message to the invoking process with the output.

Lets look at a graph which returns a value:

```elixir
adder = Graph.new(type: :directed)
|> Graph.add_edge(
  %Node{ module: Virta.Core.In, id: 0 },
  %Node{ module: Virta.Math.Add, id: 1 },
  label: %EdgeData{ from: :addend, to: :addend }
)
|> Graph.add_edge(
  %Node{ module: Virta.Core.In, id: 0 },
  %Node{ module: Virta.Math.Add, id: 1 },
  label: %EdgeData{ from: :augend, to: :augend }
)
|> Graph.add_edge(
  %Node{ module: Virta.Math.Add, id: 1 },
  %Node{ module: Virta.Core.Out, id: 2 },
  label: %EdgeData{ from: :sum, to: :output }
)
```

Once a graph is created, it needs to be registered to create a workflow. Lets look at how this is done:

```elixir
Virta.Registry.register("adder", adder)
```

#### Executing the workflow
The input for a workflow should be a list of messages with the format `{ request_id, port, value }` for the input node as follows:

```elixir
data = %{
  %Node{ module: Virta.Core.In, id: 0 } => [
    { 1, :augend, 10 }, { 1, :addend, 20 }
  ]
}
```

Virta creates a pool of workers for the workflow using [poolboy](https://github.com/devinus/poolboy) in order to provide concurrency. We can request for a worker and execute the workflow with the above data using `Virta.Executor` as follows:

```elixir
{ requst_id, output } = Virta.Executor.call("adder", data)
```

#### Invoking a workflow within a workflow:
Virta.Core.Worflow is a special component which allows us to invoke a different workflow from the current workflow. This allows us to reuse workflows.

A workflow node can be represented as %Node{ module: Virta.Core.Workflow, id: 1, ref: "adder" } Notice the :ref property. It refers to the registered workflow with the name adder.

Lets see a code example for a complex workflow which invokes other workflows:

```elixir
alias Virta.Node
alias Virta.Registry
alias Virta.EdgeData

adder = Graph.new(type: :directed)
|> Graph.add_edge(
  %Node{ module: Virta.Core.In, id: 0 },
  %Node{ module: Virta.Math.Add, id: 1 },
  label: %EdgeData{ from: :addend, to: :addend }
)
|> Graph.add_edge(
  %Node{ module: Virta.Core.In, id: 0 },
  %Node{ module: Virta.Math.Add, id: 1 },
  label: %EdgeData{ from: :augend, to: :augend }
)
|> Graph.add_edge(
  %Node{ module: Virta.Math.Add, id: 1 },
  %Node{ module: Virta.Core.Out, id: 2 },
  label: %EdgeData{ from: :sum, to: :sum }
)

multiplier = Graph.new(type: :directed)
|> Graph.add_edge(
  %Node{ module: Virta.Core.In, id: 0 },
  %Node{ module: Virta.Math.Multiply, id: 1 },
  label: %EdgeData{ from: :multiplicand, to: :multiplicand }
)
|> Graph.add_edge(
  %Node{ module: Virta.Core.In, id: 0 },
  %Node{ module: Virta.Math.Multiply, id: 1 },
  label: %EdgeData{ from: :multiplier, to: :multiplier }
)
|> Graph.add_edge(
  %Node{ module: Virta.Math.Multiply, id: 1 },
  %Node{ module: Virta.Core.Out, id: 2 },
  label: %EdgeData{ from: :product, to: :product }
)

complex_graph = Graph.new(type: :directed)
|> Graph.add_edge(
  %Node{ module: Virta.Core.In, id: 0 },
  %Node{ module: Virta.Core.Workflow, id: 1, ref: "adder" },
  label: %EdgeData{ from: :augend, to: :augend }
)
|> Graph.add_edge(
  %Node{ module: Virta.Core.In, id: 0 },
  %Node{ module: Virta.Core.Workflow, id: 1, ref: "adder" },
  label: %EdgeData{ from: :addend, to: :addend }
)
|> Graph.add_edge(
  %Node{ module: Virta.Core.Workflow, id: 1, ref: "adder" },
  %Node{ module: Virta.Core.Workflow, id: 2, ref: "multiplier" },
  label: %EdgeData{ from: :sum, to: :multiplicand }
)
|> Graph.add_edge(
  %Node{ module: Virta.Core.Workflow, id: 1, ref: "adder" },
  %Node{ module: Virta.Core.Workflow, id: 2, ref: "multiplier" },
  label: %EdgeData{ from: :sum, to: :multiplier }
)
|> Graph.add_edge(
  %Node{ module: Virta.Core.Workflow, id: 2, ref: "multiplier" },
  %Node{ module: Virta.Core.Out, id: 3 },
  label: %EdgeData{ from: :product, to: :product }
)

Registry.register("adder", adder)
Registry.register("multiplier", multiplier)
Registry.register("complex_graph", complex_graph)
```

This can then be executed as follows:
```elixir
data = %{
  %Node{ module: Virta.Core.In, id: 0 } => [
    { 1, :augend, 10 }, { 1, :addend, 20 }
  ]
}

{ requst_id, output } = Virta.Executor.call("complex_graph", data)
```

### Status

The project is under active development and not production ready yet.

### Contributing
Request a new feature by creating an issue or create a pull request with new features or fixes.

### License
`Virta` source code is released under Apache 2 License.
Check [LICENSE](https://github.com/sarat1669/virta/blob/master/LICENSE) file for more information
