defmodule Mix.Tasks.Scoria.Test.InstallContractTest do
  use ExUnit.Case, async: true

  alias Scoria.VerificationLanes

  test "the install_contract lane is discoverable and targets the maintainer installer bundle" do
    Mix.Task.load_all()

    expected_files = [
      "test/scoria/install/report_test.exs",
      "test/scoria/install/mode_equivalence_test.exs",
      "test/mix/tasks/scoria.install_test.exs",
      "test/mix/tasks/scoria.install_check_test.exs",
      "test/scoria/install/planner_test.exs"
    ]

    assert Code.ensure_loaded?(Mix.Tasks.Scoria.Test.InstallContract)
    assert function_exported?(Mix.Tasks.Scoria.Test.InstallContract, :run, 1)
    assert function_exported?(Mix.Tasks.Scoria.Test.InstallContract, :install_contract_test_files, 0)
    assert function_exported?(Mix.Tasks.Test.InstallContract, :run, 1)
    assert Mix.Tasks.Scoria.Test.InstallContract.install_contract_test_files() == expected_files

    refute VerificationLanes.command(:adoption) == "mix scoria.test.install_contract"
    refute :install_contract in VerificationLanes.ids()
    refute Enum.any?(VerificationLanes.closeout_order(), &(&1 == :install_contract))

    assert Mix.Task.get("scoria.test.install_contract")
    assert Mix.Task.get("test.install_contract")
  end
end
