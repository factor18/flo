defmodule Virta.Node do
  @enforce_keys [ :id, :module ]
  defstruct [ id: nil, module: nil, ref: nil ]
end
