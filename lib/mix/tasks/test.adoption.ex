defmodule Mix.Tasks.Scoria.Test.Adoption do
  use Mix.Task

  @shortdoc "Runs the adoption-focused default verification lane"
  @adoption_test_files [
    "test/scoria_test.exs",
    "test/scoria/identity_doctest_test.exs",
    "test/scoria/adoption_surface_test.exs",
    "test/scoria/handoff_example_source_test.exs",
    "test/scoria/phoenix_example_source_test.exs",
    "test/scoria/runtime_integration_test.exs",
    "test/scoria/runtime_test.exs",
    "test/mix/tasks/scoria.install_test.exs",
    "test/mix/tasks/scoria.install_route_smoke_test.exs",
    "test/scoria/bootstrap/migration_lane_compatibility_test.exs"
  ]

  def adoption_test_files, do: @adoption_test_files

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("loadpaths")
    Mix.Task.reenable("test")
    Mix.Task.run("test", args ++ @adoption_test_files)
  end
end

defmodule Mix.Tasks.Test.Adoption do
  use Mix.Task

  @shortdoc "Compatibility wrapper for the explicit Scoria adoption verification lane"

  @impl Mix.Task
  def run(args), do: Mix.Tasks.Scoria.Test.Adoption.run(args)
end
