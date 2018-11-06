defmodule Virta.Executor do
  def cast(name, data) do
    :poolboy.transaction(String.to_existing_atom(name), fn (server) ->
      Virta.Instance.execute(server, data)
    end)
  end

  def call(name, data) do
    :poolboy.transaction(String.to_existing_atom(name), fn (server) ->
      Virta.Instance.execute(server, data)
      receive do
        message -> message
      end
    end)
  end
end
