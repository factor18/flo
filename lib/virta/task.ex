defmodule Virta.Task do
  defstruct id: nil, ref: nil, inports: [], outports: [], settings: []

  alias Virta.Pair

  @type t() :: %__MODULE__{
    id: String.t,
    ref: String.t,
    inports: [Pair.t],
    outports: [Pair.t],
    settings: [Pair.t],
  }
end
