defmodule Mix.Tasks.Scoria.Test.SemanticFastPath do
  use Mix.Task

  @shortdoc "Runs the semantic fast-path verification lane"
  @semantic_fast_path_test_files [
    "test/scoria/runtime/semantic_fast_path_test.exs",
    "test/scoria/semantic_cache/lookup_test.exs",
    "test/scoria/semantic_cache/invalidation_test.exs",
    "test/scoria_web/live/orchestrator_live_test.exs",
    "test/scoria_web/components/runtime_detail_drawer_component_test.exs",
    "test/scoria_web/components/semantic_evidence_notebook_component_test.exs",
    "test/scoria_web/live/workflow_live_test.exs",
    "test/mix/tasks/test.semantic_fast_path_test.exs"
  ]

  def semantic_fast_path_test_files, do: @semantic_fast_path_test_files

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("loadpaths")
    Mix.Task.reenable("test")
    Mix.Task.run("test", args ++ @semantic_fast_path_test_files)
  end
end
