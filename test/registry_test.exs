defmodule Virta.RegistryTest do
  use ExUnit.Case, async: false
  doctest Virta.Registry

  alias Virta.Node
  alias Virta.Registry
  alias Virta.EdgeData

  setup do
    graph = Graph.new(type: :directed)
    |> Graph.add_edge(
      %Node{ module: Virta.Core.In, id: 0 },
      %Node{ module: Virta.Math.Add, id: 1 },
      label: %EdgeData{ from: :addend, to: :addend }
    )
    |> Graph.add_edge(
      %Node{ module: Virta.Core.In, id: 0 },
      %Node{ module: Virta.Math.Add, id: 1 },
      label: %EdgeData{ from: :augend, to: :augend }
    )
    |> Graph.add_edge(
      %Node{ module: Virta.Math.Add, id: 1 },
      %Node{ module: Virta.Core.Out, id: 2 },
      label: %EdgeData{ from: :sum, to: :sum }
    )

    Registry.unregister("graph")

    { :ok, graph: graph }
  end

  test "should return nil when graph isn't registered" do
    assert Registry.get("graph") == nil
  end

  test "should register the graph", context do
    assert Registry.register("graph", context[:graph]) == { :ok, "registered" }
  end

  test "should return the pid when graph is registered", context do
    assert Registry.register("graph", context[:graph]) == { :ok, "registered" }
    assert is_pid(Registry.get("graph"))
  end

  test "should return error if tried to re-register a graph", context do
    assert Registry.register("graph", context[:graph]) == { :ok, "registered" }
    assert Registry.register("graph", context[:graph]) == { :error, "already_exists" }
  end

  test "should unregister the graph", context do
    assert Registry.register("graph", context[:graph]) == { :ok, "registered" }
    assert { :ok, "unregistered" } = Registry.unregister("graph")
    assert Registry.get("graph") == nil
  end
end
