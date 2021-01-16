defmodule Virta.Port do
  defstruct name: nil, type: nil, default: nil, required: false

  @type t() :: %__MODULE__{
    name: String.t,
    type: String.t,
    default: any(),
    required: boolean(),
  }
end
