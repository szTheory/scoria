defmodule Mix.Tasks.Scoria.Test.KnowledgeTest do
  use ExUnit.Case, async: true

  test "the explicit Scoria knowledge lane is discoverable and keeps the compatibility wrapper" do
    Mix.Task.load_all()

    assert Code.ensure_loaded?(Mix.Tasks.Scoria.Test.Knowledge)
    assert function_exported?(Mix.Tasks.Scoria.Test.Knowledge, :run, 1)
    assert function_exported?(Mix.Tasks.Test.Knowledge, :run, 1)
    assert Mix.Task.get("scoria.test.knowledge")
    assert Mix.Task.get("test.knowledge")
  end
end
