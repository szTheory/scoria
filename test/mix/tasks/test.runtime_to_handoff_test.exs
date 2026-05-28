defmodule Mix.Tasks.Scoria.Test.RuntimeToHandoffTest do
  use ExUnit.Case, async: true

  test "the runtime-to-handoff lane is discoverable and excludes optional setup paths" do
    Mix.Task.load_all()

    expected_files = [
      "test/scoria/runtime_test.exs",
      "test/scoria/runtime_integration_test.exs",
      "test/scoria/adoption_surface_test.exs",
      "test/scoria/phoenix_example_source_test.exs",
      "test/scoria/handoff_example_source_test.exs",
      "test/mix/tasks/test.runtime_to_handoff_test.exs"
    ]

    assert Code.ensure_loaded?(Mix.Tasks.Scoria.Test.RuntimeToHandoff)
    assert function_exported?(Mix.Tasks.Scoria.Test.RuntimeToHandoff, :run, 1)
    assert function_exported?(Mix.Tasks.Scoria.Test.RuntimeToHandoff, :runtime_to_handoff_test_files, 0)
    assert function_exported?(Mix.Tasks.Test.RuntimeToHandoff, :run, 1)
    assert Mix.Tasks.Scoria.Test.RuntimeToHandoff.runtime_to_handoff_test_files() == expected_files
    assert Mix.Task.get("scoria.test.runtime_to_handoff")
    assert Mix.Task.get("test.runtime_to_handoff")

    refute Enum.any?(expected_files, &String.contains?(&1, "semantic"))
    refute Enum.any?(expected_files, &String.contains?(&1, "knowledge"))
    refute Enum.any?(expected_files, &String.contains?(&1, "install"))
    refute Enum.any?(expected_files, &String.contains?(&1, "host_app_consumer"))
  end
end
