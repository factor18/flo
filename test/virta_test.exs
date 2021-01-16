defmodule VirtaTest do
  use ExUnit.Case
  doctest Virta

  test "greets the world" do
    assert Virta.hello() == :world
  end
end
