defmodule Virta.EdgeData do
  @enforce_keys [ :from, :to ]
  defstruct [ from: nil, to: nil ]

  @typedoc """
  Represents the connection ports. Should be used as label for edges in the graphs.

  * `:from`: The port of the source component. An atom.
  * `:to`: The port of the destination component. An atom.
  """
  @type t :: %__MODULE__{
    from: atom,
    to: atom
  }
end
