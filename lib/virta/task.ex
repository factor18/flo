defmodule Virta.Task do
  alias Virta.Pair

  defstruct id: nil, ref: nil, inports: [], outports: [], settings: []

  @type t() :: %__MODULE__{
    id: String.t,
    ref: String.t,
    inports: [Pair.t],
    outports: [Pair.t],
    settings: [Pair.t],
  }
end
