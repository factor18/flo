defmodule Virta.Pair do
  defstruct name: nil, value: nil

  @type t() :: %__MODULE__{
    name: String.t,
    value: any(),
  }
end
