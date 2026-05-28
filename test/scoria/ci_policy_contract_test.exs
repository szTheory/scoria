defmodule Scoria.CiPolicyContractTest do
  use ExUnit.Case, async: true

  alias Scoria.VerificationLanes

  @baseline_check "mix scoria.warning_baseline.check"
  @compile_wae "mix compile --warnings-as-errors"
  @ci_policy_contract "test/scoria/ci_policy_contract_test.exs"
  @lane_contract "test/scoria/verification_lanes_test.exs"
  @ratchet_wae "mix scoria.warning_ratchet.test --warnings-as-errors"

  test "policy job runs warning baseline check before compile WAE" do
    ci_workflow = File.read!(".github/workflows/ci.yml")
    [policy_section, _test_section] = split_jobs(ci_workflow)

    assert policy_section =~ @baseline_check
    assert index_of(policy_section, @baseline_check) < index_of(policy_section, @compile_wae)
    assert index_of(policy_section, @compile_wae) <
             index_of(policy_section, "Verify lane-contract tests with warnings as errors")
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

  test "CI-03 documents CI gate map for maintainers" do
    operator_docs = File.read!("docs/operator_verification.md")

    assert operator_docs =~ "CI gate map"
    assert operator_docs =~ "policy"
    assert operator_docs =~ "needs: policy" or operator_docs =~ "`policy`"
    assert operator_docs =~ "Not in PR CI"
    assert operator_docs =~ "mix test.semantic_fast_path"
    assert operator_docs =~ "Version namespaces"
    assert operator_docs =~ "mix scoria.test.install_contract"
  end

  test "policy job does not run warning_ratchet.test" do
    ci_workflow = File.read!(".github/workflows/ci.yml")
    [policy_section, _test_section] = split_jobs(ci_workflow)

    refute policy_section =~ "scoria.warning_ratchet"
    refute policy_section =~ @ratchet_wae
  end

  test "ci.yml has workflow header comment block before jobs" do
    ci_workflow = File.read!(".github/workflows/ci.yml")
    [header, _rest] = String.split(ci_workflow, "\njobs:", parts: 2)

    comment_lines =
      header
      |> String.split("\n")
      |> Enum.filter(&String.starts_with?(&1, "#"))

    assert length(comment_lines) >= 5
    assert header =~ "policy"
    assert header =~ "test"
  end

  test "ci.yml documents per-job intent comments for policy and test" do
    ci_workflow = File.read!(".github/workflows/ci.yml")
    [policy_section, _test_section] = split_jobs(ci_workflow)

    assert policy_section =~ "# policy:"
    assert ci_workflow =~ "# test:"
  end

  test "operator CI gate map documents topology, parity, ratchet, and failure diagnosis" do
    operator_docs = File.read!("docs/operator_verification.md")
    gate_map = section_after(operator_docs, "### CI gate map (maintainers)")

    assert gate_map =~ "Policy job"
    assert gate_map =~ "Test job closeout"
    assert gate_map =~ "Local parity"
    assert gate_map =~ "Ratchet is maintainer-only"
    assert gate_map =~ "When CI fails, run the matching maintainer command next"
    assert gate_map =~ "mix compile --warnings-as-errors"
    refute gate_map =~ "Policy: compile WAE failed → `MIX_ENV=test mix compile --warnings-as-errors`"
  end

  test "README links maintainers to CI gate map near the CI badge" do
    readme =
      "README.md"
      |> File.read!()
      |> String.split("\n")
      |> Enum.take(10)
      |> Enum.join("\n")

    assert readme =~ "CI gate map"
    assert readme =~ "operator_verification.md#ci-gate-map-maintainers"
    refute String.match?(readme, ~r/Maintainer CI topology.*\n.*Maintainer CI topology/s)
  end

  test "ci.yml triggers on push and pull_request to main" do
    ci_workflow = File.read!(".github/workflows/ci.yml")

    assert ci_workflow =~ "push:"
    assert ci_workflow =~ "pull_request:"
    assert ci_workflow =~ "- main"
  end

  test "policy job runs ci_policy_contract_test in lane-contract step" do
    ci_workflow = File.read!(".github/workflows/ci.yml")
    [policy_section, _test_section] = split_jobs(ci_workflow)
    lane_step = lane_contract_step(policy_section)

    assert lane_step =~ @ci_policy_contract
    assert lane_step =~ @lane_contract
    assert index_of(lane_step, @ci_policy_contract) < index_of(lane_step, @lane_contract)
  end

  test "69-VERIFICATION.md records CI-03 traceability" do
    verification =
      File.read!(
        ".planning/phases/69-ci-trust-and-milestone-closeout/69-VERIFICATION.md"
      )

    assert verification =~ "CI-03 traceability"
    assert verification =~ "ci_policy_contract_test"
  end

  test "v2.6 milestone audit documents CI closeout contract" do
    audit = File.read!(".planning/milestones/v2.6-MILESTONE-AUDIT.md")

    assert audit =~ "CI closeout contract"
    assert audit =~ "policy"
  end

  test "planning ledgers mark CI-03 and phase 69 complete" do
    requirements = File.read!(".planning/REQUIREMENTS.md")
    roadmap = File.read!(".planning/ROADMAP.md")

    assert requirements =~ "[x] **CI-03**"
    assert roadmap =~ "69"
    assert roadmap =~ "3/3"
    assert roadmap =~ "Complete"
  end

  defp lane_contract_step(policy_section) do
    case Regex.run(~r/- name: Verify lane-contract tests with warnings as errors\n\s+run: (.+)/, policy_section) do
      [_, run_line] -> run_line
      _ -> flunk("expected lane-contract step in policy job")
    end
  end

  defp split_jobs(content) do
    case :binary.match(content, "\n  test:") do
      {index, _length} ->
        [String.slice(content, 0, index), String.slice(content, index, byte_size(content))]

      :nomatch ->
        flunk("expected policy and test jobs in ci.yml")
    end
  end

  defp section_after(content, heading) do
    case :binary.match(content, heading) do
      {start, _len} ->
        content
        |> String.slice(start, byte_size(content))
        |> String.split("\n### ", parts: 2)
        |> List.first()

      :nomatch ->
        flunk("expected #{inspect(heading)} in content")
    end
  end

  defp index_of(content, needle) do
    case :binary.match(content, needle) do
      {index, _length} -> index
      :nomatch -> flunk("Expected to find #{inspect(needle)} in content")
    end
  end
end
