defmodule Virta.App do
  alias Virta.{Task, Link, Trigger}

  defstruct name: nil, version: nil, description: nil, triggers: [], tasks: [], links: []

  @type t() :: %__MODULE__{
    name: String.t,
    links: [Link.t],
    tasks: [Task.t],
    version: String.t,
    description: String.t,
    triggers: [Trigger.t],
  }
end
