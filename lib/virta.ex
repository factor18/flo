defmodule Virta do
  @moduledoc """
  Virta is a Flow-Based Programming environment for Elixir. In flow-based programs, the logic of
  your application is defined as an acyclic graph. The nodes of the graph are instances of
  components, the edges define the connections between them.

  The components react to the incoming mesages. When a component receives a message, it performs a
  predefined operation and sends its result as a message to its outports.

  The components are elixir modules which implement the `Virta.Component` behaviour.

  A graph needs to be registered with a name on `Virta.Registry` before it can be executed. A
  registered graph is called a Workflow. `Virta.Executor` API provides methods to interact with
  the workflow.
  """

  alias Virta.Supervisor

  use Application

  @doc false
  def start(_type, _args) do
    Supervisor.start_link(name: Supervisor)
  end
end
