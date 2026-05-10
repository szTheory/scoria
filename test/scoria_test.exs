defmodule ScoriaTest do
  use ExUnit.Case
  doctest Scoria

  test "greets the world" do
    assert Scoria.hello() == :world
  end
end
