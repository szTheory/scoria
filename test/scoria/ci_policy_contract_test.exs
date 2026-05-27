defmodule Scoria.CiPolicyContractTest do
  use ExUnit.Case, async: true

  alias Scoria.VerificationLanes

  @baseline_check "mix scoria.warning_baseline.check"
  @compile_wae "mix compile --warnings-as-errors"
  @lane_contract "test/scoria/verification_lanes_test.exs"
  @ratchet_wae "mix scoria.warning_ratchet.test --warnings-as-errors"

  test "policy job runs warning baseline check before compile WAE" do
    ci_workflow = File.read!(".github/workflows/ci.yml")

    assert ci_workflow =~ @baseline_check
    assert index_of(ci_workflow, @baseline_check) < index_of(ci_workflow, @compile_wae)
    assert index_of(ci_workflow, @compile_wae) < index_of(ci_workflow, @lane_contract)
  end

  test "test job depends on policy and preserves closeout chain order" do
    ci_workflow = File.read!(".github/workflows/ci.yml")

    release_preview = VerificationLanes.ci_command(:release_preview)
    adoption = VerificationLanes.ci_command(:adoption)
    runtime_to_handoff = VerificationLanes.ci_command(:runtime_to_handoff)

    assert ci_workflow =~ "needs: policy"
    assert ci_workflow =~ release_preview
    assert ci_workflow =~ adoption
    assert ci_workflow =~ runtime_to_handoff

    assert index_of(ci_workflow, release_preview) < index_of(ci_workflow, adoption)
    assert index_of(ci_workflow, adoption) < index_of(ci_workflow, runtime_to_handoff)
  end

  test "postgres service is configured only for the test job" do
    ci_workflow = File.read!(".github/workflows/ci.yml")
    [policy_section, test_section] = split_jobs(ci_workflow)

    refute policy_section =~ "services:"
    assert test_section =~ "services:"
    assert test_section =~ "postgres"
  end

  test "WARN-06 documents WarningRatchet maintainer commands" do
    operator_docs = File.read!("docs/operator_verification.md")

    assert operator_docs =~ "mix scoria.warning_ratchet.test"
    assert operator_docs =~ "mix scoria.warning_ratchet.check"
    assert length(Scoria.WarningRatchet.high_signal_wae_paths()) > 0
  end

  test "test job runs full suite WAE after runtime_to_handoff and before knowledge lane" do
    ci_workflow = File.read!(".github/workflows/ci.yml")
    [_policy_section, test_section] = split_jobs(ci_workflow)
    runtime_to_handoff = VerificationLanes.ci_command(:runtime_to_handoff)

    assert test_section =~ "run: mix test --warnings-as-errors"
    refute test_section =~ "mix scoria.warning_ratchet.test --warnings-as-errors"
    assert index_of(test_section, runtime_to_handoff) <
             index_of(test_section, "run: mix test --warnings-as-errors")

    assert index_of(test_section, "run: mix test --warnings-as-errors") <
             index_of(test_section, "mix test.knowledge")
  end

  test "policy job does not run warning_ratchet.test" do
    ci_workflow = File.read!(".github/workflows/ci.yml")
    [policy_section, _test_section] = split_jobs(ci_workflow)

    refute policy_section =~ "scoria.warning_ratchet"
    refute policy_section =~ @ratchet_wae
  end

  defp split_jobs(content) do
    case :binary.match(content, "\n  test:") do
      {index, _length} ->
        [String.slice(content, 0, index), String.slice(content, index, byte_size(content))]

      :nomatch ->
        flunk("expected policy and test jobs in ci.yml")
    end
  end

  defp index_of(content, needle) do
    case :binary.match(content, needle) do
      {index, _length} -> index
      :nomatch -> flunk("Expected to find #{inspect(needle)} in content")
    end
  end
end
