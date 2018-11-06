defmodule Virta.Executor do
  @moduledoc """
  Provides methods to interact with the workflow.
  """

  @doc """
  When a workflow doesn't use `Virta.Core.Out` component, i.e, the workflow doesn't return any
  data to the process which invoked it, cast needs to be used.

  `name` is the name with which the workflow is registered.

  The data should be a Map with the keys as the %Virta.Node{} and values as a list of messages with
  the format `{ request_id, port, value }` for the respective node.
   Example:
  ```elixir
  data = %{
    %Node{ module: Virta.Core.In, id: 0 } => [
      { 1, :augend, 10 }, { 1, :addend, 20 }
    ]
  }
  ```
  """
  def cast(name, data) do
    :poolboy.transaction(String.to_existing_atom(name), fn (server) ->
      Virta.Instance.execute(server, data)
    end)
  end

  @doc """
  When a workflow uses `Virta.Core.Out` component, i.e, the workflow returns output from the
  execution to the process which invoked it, call needs to be used.

  `name` is the name with which the workflow is registered.

  The data should be a Map with the keys as the %Virta.Node{} and values as a list of messages with
  the format `{ request_id, port, value }` for the respective node.
   Example:
  ```elixir
  data = %{
    %Node{ module: Virta.Core.In, id: 0 } => [
      { 1, :augend, 10 }, { 1, :addend, 20 }
    ]
  }
  ```
  """
  def call(name, data) do
    :poolboy.transaction(String.to_existing_atom(name), fn (server) ->
      Virta.Instance.execute(server, data)
      receive do
        message -> message
      end
    end)
  end
end
