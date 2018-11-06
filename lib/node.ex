defmodule Virta.Node do
  @enforce_keys [ :id, :module ]
  defstruct [ id: nil, module: nil, ref: nil ]

  @typedoc """
  Represents the node in a graph used to generate the workflow.

  * `:id`: It should be unique to the node in a graph. Usually a string or an integer.
  * `:module`: The reference to the module. An atom.
  * `:ref`: In case of a workflow component, the name of the registered workflow. A string.
  """
  @type t :: %__MODULE__{
    id: any(),
    module: atom,
    ref: String.t
  }
end
