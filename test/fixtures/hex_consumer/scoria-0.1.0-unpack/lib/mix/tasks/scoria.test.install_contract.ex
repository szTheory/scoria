defmodule Mix.Tasks.Scoria.Test.InstallContract do
  use Mix.Task

  @shortdoc "Runs installer contract proofs (maintainer DX; not a closeout lane)"
  @install_contract_test_files [
    "test/scoria/install/report_test.exs",
    "test/scoria/install/mode_equivalence_test.exs",
    "test/mix/tasks/scoria.install_test.exs",
    "test/mix/tasks/scoria.install_check_test.exs",
    "test/scoria/install/planner_test.exs"
  ]

  def install_contract_test_files, do: @install_contract_test_files

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("loadpaths")
    Mix.Task.reenable("test")
    Mix.Task.run("test", args ++ @install_contract_test_files)
  end
end

defmodule Mix.Tasks.Test.InstallContract do
  use Mix.Task

  @shortdoc "Compatibility wrapper for installer contract verification (maintainer DX only)"

  @impl Mix.Task
  def run(args), do: Mix.Tasks.Scoria.Test.InstallContract.run(args)
end
