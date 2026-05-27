defmodule Mix.Tasks.Scoria.InstallCheckTest do
  use ExUnit.Case, async: true

  alias Scoria.Install.Report

  test "check_result returns compliant when all planner entries are no_op" do
    plan = %{
      entries: [
        %{classification: :no_op, evidence: %{managed?: true}},
        %{classification: :no_op, evidence: %{optional?: true}}
      ]
    }

    assert Report.check_result(plan) == %{status: :compliant, exit_code: 0}
  end

  test "check_result returns drift when planner has create or update entries" do
    plan = %{entries: [%{classification: :create}, %{classification: :no_op}]}
    assert Report.check_result(plan) == %{status: :drift, exit_code: 1}

    update_plan = %{entries: [%{classification: :update}]}
    assert Report.check_result(update_plan) == %{status: :drift, exit_code: 1}
  end

  test "check_result returns manual_review when planner includes manual review entries" do
    plan = %{entries: [%{classification: :manual_review}, %{classification: :create}]}
    assert Report.check_result(plan) == %{status: :manual_review, exit_code: 1}
  end

  test "check_result returns error when planner data is invalid" do
    assert Report.check_result(%{entries: :not_a_list}) == %{status: :error, exit_code: 2}
    assert Report.check_result(nil) == %{status: :error, exit_code: 2}
  end

  test "trailer_line emits stable machine-readable payload" do
    result = %{status: :drift, exit_code: 1}

    assert Report.trailer_line(result) ==
             "SCORIA_CHECK_RESULT status=drift exit_code=1"
  end
end
