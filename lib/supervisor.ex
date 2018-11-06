defmodule Virta.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      Virta.Registry,
      { DynamicSupervisor, name: Virta.InstanceSupervisor, strategy: :one_for_one }
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
