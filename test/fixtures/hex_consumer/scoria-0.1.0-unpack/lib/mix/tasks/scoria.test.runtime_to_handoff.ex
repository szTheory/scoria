defmodule Mix.Tasks.Scoria.Test.RuntimeToHandoff do
  use Mix.Task

  @shortdoc "Runs the bounded runtime-to-handoff verification lane"
  @runtime_to_handoff_test_files [
    "test/scoria/runtime_test.exs",
    "test/scoria/runtime_integration_test.exs",
    "test/scoria/adoption_surface_test.exs",
    "test/scoria/phoenix_example_source_test.exs",
    "test/scoria/handoff_example_source_test.exs",
    "test/mix/tasks/test.runtime_to_handoff_test.exs"
  ]

  def runtime_to_handoff_test_files, do: @runtime_to_handoff_test_files

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("loadpaths")
    Mix.Task.reenable("test")
    Mix.Task.run("test", args ++ @runtime_to_handoff_test_files)
  end
end
