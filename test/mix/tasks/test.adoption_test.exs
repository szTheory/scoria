defmodule Mix.Tasks.Scoria.Test.AdoptionTest do
  use ExUnit.Case, async: true

  test "the adoption lane is discoverable and targets the bounded default-suite subset" do
    Mix.Task.load_all()

    expected_files = [
      "test/scoria_test.exs",
      "test/scoria/identity_doctest_test.exs",
      "test/scoria/adoption_surface_test.exs",
      "test/scoria/handoff_example_source_test.exs",
      "test/scoria/phoenix_example_source_test.exs",
      "test/scoria/semantic_fast_path_example_source_test.exs",
      "test/scoria/runtime_integration_test.exs",
      "test/scoria/runtime_test.exs",
      "test/scoria/host_app_consumer_proof_test.exs",
      "test/mix/tasks/scoria.install_test.exs",
      "test/mix/tasks/scoria.install_route_smoke_test.exs",
      "test/scoria/bootstrap/migration_lane_compatibility_test.exs"
    ]

    assert Code.ensure_loaded?(Mix.Tasks.Scoria.Test.Adoption)
    assert function_exported?(Mix.Tasks.Scoria.Test.Adoption, :run, 1)
    assert function_exported?(Mix.Tasks.Scoria.Test.Adoption, :adoption_test_files, 0)
    assert function_exported?(Mix.Tasks.Test.Adoption, :run, 1)
    assert Mix.Tasks.Scoria.Test.Adoption.adoption_test_files() == expected_files
    assert "test/scoria/runtime_test.exs" in expected_files
    assert "test/scoria/host_app_consumer_proof_test.exs" in expected_files
    refute Enum.any?(expected_files, &String.contains?(&1, "semantic_cache"))
    refute "test/scoria/knowledge_test.exs" in expected_files
    refute "test/scoria/runtime/semantic_fast_path_test.exs" in expected_files
    assert Mix.Task.get("scoria.test.adoption")
    assert Mix.Task.get("test.adoption")
  end
end
