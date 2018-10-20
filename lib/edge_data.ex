defmodule Virta.EdgeData do
  @enforce_keys [ :from, :to ]
  defstruct [ from: nil, to: nil ]
end
