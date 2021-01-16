defmodule Virta.Link do
  defstruct from: nil, to: nil

  @type t() :: %__MODULE__{
    to: String.t,
    from: String.t,
  }
end
