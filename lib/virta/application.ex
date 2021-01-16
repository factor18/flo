defmodule Virta.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Virta.AppRegistry,
      {DynamicSupervisor, name: Virta.TriggerSupervisor, strategy: :one_for_one},
      Virta.Registry,
    ]

    opts = [strategy: :one_for_one, name: Virta.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
