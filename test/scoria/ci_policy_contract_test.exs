defmodule Scoria.CiPolicyContractTest do
  use ExUnit.Case, async: true

  alias Scoria.VerificationLanes

  @ci_verify ".github/workflows/ci-verify.yml"
  @ci_entry ".github/workflows/ci.yml"
  @baseline_check "mix scoria.warning_baseline.check"
  @compile_wae "mix compile --warnings-as-errors"
  @ci_policy_contract "test/scoria/ci_policy_contract_test.exs"
  @lane_contract "test/scoria/verification_lanes_test.exs"
  @ratchet_wae "mix scoria.warning_ratchet.test --warnings-as-errors"

  test "ci-verify.yml is reusable workflow_call SSOT" do
    ci_verify = File.read!(@ci_verify)

    assert ci_verify =~ "workflow_call"
    assert ci_verify =~ @baseline_check
    assert ci_verify =~ "MIX_ENV=dev mix scoria.release_preview"
    assert ci_verify =~ "services:"
    assert ci_verify =~ "postgres"
  end

  test "release-please.yml uses ci-verify and disables publish in phase 71" do
    release_please = File.read!(".github/workflows/release-please.yml")

    assert release_please =~ "googleapis/release-please-action"
    assert release_please =~ "ci-verify.yml"
    assert release_please =~ "publish-hex"
    assert release_please =~ "if: false"
    refute release_please =~ "sync_release_summary"
  end

  test "hex-publish.yml supports workflow_dispatch recovery with verify" do
    hex_publish = File.read!(".github/workflows/hex-publish.yml")

    assert hex_publish =~ "workflow_dispatch"
    assert hex_publish =~ "tag:"
    assert hex_publish =~ "release_version"
    assert hex_publish =~ "ci-verify.yml"
    refute Regex.match?(~r/^\s+run: mix hex\.publish --yes/m, hex_publish)
  end

  test "release-please bootstrap config uses manifest 0.0.0" do
    manifest = File.read!(".release-please-manifest.json")
    config = File.read!("release-please-config.json")

    assert manifest =~ "0.0.0"
    assert config =~ "release-as"
    assert config =~ "0.1.0"
    assert config =~ "bootstrap-sha"
    assert config =~ "changelog-path"
  end

  test "ci.yml delegates to ci-verify and extends triggers" do
    ci_entry = File.read!(@ci_entry)

    assert ci_entry =~ "uses: ./.github/workflows/ci-verify.yml"
    assert ci_entry =~ "release-please--"
    assert ci_entry =~ "workflow_dispatch"
    refute ci_entry =~ "\n  policy:"
  end

  test "policy job runs warning baseline check before compile WAE" do
    ci_verify = File.read!(@ci_verify)
    [policy_section, _test_section] = split_jobs(ci_verify)

    assert policy_section =~ @baseline_check
    assert index_of(policy_section, @baseline_check) < index_of(policy_section, @compile_wae)
    assert index_of(policy_section, @compile_wae) <
             index_of(policy_section, "Verify lane-contract tests with warnings as errors")
  end

  test "test job depends on policy and preserves closeout chain order" do
    ci_verify = File.read!(@ci_verify)

    release_preview = VerificationLanes.ci_command(:release_preview)
    adoption = VerificationLanes.ci_command(:adoption)
    runtime_to_handoff = VerificationLanes.ci_command(:runtime_to_handoff)

    assert ci_verify =~ "needs: policy"
    assert ci_verify =~ release_preview
    assert ci_verify =~ adoption
    assert ci_verify =~ runtime_to_handoff

    assert index_of(ci_verify, release_preview) < index_of(ci_verify, adoption)
    assert index_of(ci_verify, adoption) < index_of(ci_verify, runtime_to_handoff)
  end

  test "postgres service is configured only for the test job" do
    ci_verify = File.read!(@ci_verify)
    [policy_section, test_section] = split_jobs(ci_verify)

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
    ci_verify = File.read!(@ci_verify)
    [_policy_section, test_section] = split_jobs(ci_verify)
    runtime_to_handoff = VerificationLanes.ci_command(:runtime_to_handoff)

    assert test_section =~ "run: mix test --warnings-as-errors"
    refute test_section =~ "mix scoria.warning_ratchet.test --warnings-as-errors"
    assert index_of(test_section, runtime_to_handoff) <
             index_of(test_section, "run: mix test --warnings-as-errors")

    assert index_of(test_section, "run: mix test --warnings-as-errors") <
             index_of(test_section, "mix test.knowledge")
  end

  test "operator guide documents Hex release section and README links anchor" do
    operator_docs = File.read!("docs/operator_verification.md")
    readme = File.read!("README.md")

    assert operator_docs =~ "## Hex release & recovery"
    assert operator_docs =~ "hex-release--recovery-maintainers"
    assert operator_docs =~ "HEX_API_KEY"
    assert operator_docs =~ "hex-publish.yml"
    assert operator_docs =~ "release-please--"
    assert operator_docs =~ "default_workflow_permissions=write"
    assert readme =~ "hex-release--recovery-maintainers"
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
    ci_verify = File.read!(@ci_verify)
    [policy_section, _test_section] = split_jobs(ci_verify)

    refute policy_section =~ "scoria.warning_ratchet"
    refute policy_section =~ @ratchet_wae
  end

  test "ci.yml has workflow header comment block before jobs" do
    ci_entry = File.read!(@ci_entry)
    [header, _rest] = String.split(ci_entry, "\njobs:", parts: 2)

    comment_lines =
      header
      |> String.split("\n")
      |> Enum.filter(&String.starts_with?(&1, "#"))

    assert length(comment_lines) >= 5
    assert header =~ "ci-verify"
    assert header =~ "policy"
    assert header =~ "test"
  end

  test "ci-verify.yml documents per-job intent comments for policy and test" do
    ci_verify = File.read!(@ci_verify)
    [policy_section, _test_section] = split_jobs(ci_verify)

    assert policy_section =~ "# policy:"
    assert ci_verify =~ "# test:"
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
    ci_entry = File.read!(@ci_entry)

    assert ci_entry =~ "push:"
    assert ci_entry =~ "pull_request:"
    assert ci_entry =~ "- main"
  end

  test "policy job runs ci_policy_contract_test in lane-contract step" do
    ci_verify = File.read!(@ci_verify)
    [policy_section, _test_section] = split_jobs(ci_verify)
    lane_step = lane_contract_step(policy_section)

    assert lane_step =~ @ci_policy_contract
    assert lane_step =~ @lane_contract
    assert index_of(lane_step, @ci_policy_contract) < index_of(lane_step, @lane_contract)
  end

  test "v2.6 milestone audit records CI-03 traceability" do
    audit = File.read!(".planning/milestones/v2.6-MILESTONE-AUDIT.md")

    assert audit =~ "CI-03"
    assert audit =~ "ci_policy_contract_test"
  end

  test "v2.6 milestone audit documents CI closeout contract" do
    audit = File.read!(".planning/milestones/v2.6-MILESTONE-AUDIT.md")

    assert audit =~ "CI closeout contract"
    assert audit =~ "policy"
  end

  test "planning ledgers mark phase 69 complete" do
    roadmap = File.read!(".planning/ROADMAP.md")
    milestones = File.read!(".planning/MILESTONES.md")

    assert roadmap =~ "69"
    assert roadmap =~ "Complete"
    assert milestones =~ "CI-03"
    assert milestones =~ "v2.6 Warning Ratchet"
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
        flunk("expected policy and test jobs in ci-verify.yml")
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
