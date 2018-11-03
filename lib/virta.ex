defmodule Virta do
  alias Virta.Supervisor

  use Application

  def start(_type, _args) do
    Supervisor.start_link(name: Supervisor)
  end
end
