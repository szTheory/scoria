defmodule Mix.Tasks.Scoria.Test.SemanticFastPathTest do
  use ExUnit.Case, async: true

  test "the semantic fast-path lane is discoverable and targets the bounded semantic subset" do
    Mix.Task.load_all()

    expected_files = [
      "test/scoria/runtime/semantic_fast_path_test.exs",
      "test/scoria/semantic_cache/lookup_test.exs",
      "test/scoria/semantic_cache/invalidation_test.exs",
      "test/scoria_web/live/orchestrator_live_test.exs",
      "test/scoria_web/components/runtime_detail_drawer_component_test.exs",
      "test/scoria_web/components/semantic_evidence_notebook_component_test.exs",
      "test/scoria_web/live/workflow_live_test.exs",
      "test/mix/tasks/test.semantic_fast_path_test.exs"
    ]

    assert Code.ensure_loaded?(Mix.Tasks.Scoria.Test.SemanticFastPath)
    assert function_exported?(Mix.Tasks.Scoria.Test.SemanticFastPath, :run, 1)
    assert function_exported?(Mix.Tasks.Scoria.Test.SemanticFastPath, :semantic_fast_path_test_files, 0)
    assert function_exported?(Mix.Tasks.Test.SemanticFastPath, :run, 1)
    assert Mix.Tasks.Scoria.Test.SemanticFastPath.semantic_fast_path_test_files() == expected_files
    assert "test/scoria/runtime/semantic_fast_path_test.exs" in expected_files
    assert "test/scoria_web/live/orchestrator_live_test.exs" in expected_files
    assert "test/scoria_web/components/runtime_detail_drawer_component_test.exs" in expected_files
    assert "test/scoria_web/components/semantic_evidence_notebook_component_test.exs" in expected_files
    assert "test/scoria_web/live/workflow_live_test.exs" in expected_files
    refute "test/scoria/adoption_surface_test.exs" in expected_files
    assert Mix.Task.get("scoria.test.semantic_fast_path")
    assert Mix.Task.get("test.semantic_fast_path")
  end
end
