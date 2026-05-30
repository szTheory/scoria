defmodule Scoria.CiPolicyContractTest do
  use ExUnit.Case, async: true

  alias Scoria.VerificationLanes

  @ci_verify ".github/workflows/ci-verify.yml"
  @ci_entry ".github/workflows/ci.yml"
  @maintainer_docs "docs/MAINTAINERS.md"
  @operator_docs "docs/operator_verification.md"
  @baseline_check "mix scoria.warning_baseline.check"
  @inventory_baseline_check "mix scoria.warning_inventory.check_baseline"
  @semantic_lane "mix test.semantic_fast_path --warnings-as-errors"
  @compile_wae "mix compile --warnings-as-errors"
  @ci_policy_contract "test/scoria/ci_policy_contract_test.exs"
  @lane_contract "test/scoria/verification_lanes_test.exs"
  @ratchet_wae "mix scoria.warning_ratchet.test --warnings-as-errors"

  test "ci-verify.yml is reusable workflow_call SSOT" do
    ci_verify = File.read!(@ci_verify)

    assert ci_verify =~ "workflow_call"
    assert ci_verify =~ @baseline_check
    assert ci_verify =~ @inventory_baseline_check
    assert ci_verify =~ "mix archive.install hex phx_new"
    assert ci_verify =~ "services:"
    assert ci_verify =~ "postgres"
  end

  test "release-please.yml uses ci-verify and enables publish-hex for Phase 72" do
    release_please = File.read!(".github/workflows/release-please.yml")

    assert release_please =~ "googleapis/release-please-action"
    assert release_please =~ "ci-verify.yml"
    assert release_please =~ "publish-hex"
    assert release_please =~ "release_created"
    assert release_please =~ "mix hex.publish --dry-run --yes"
    assert release_please =~ "mix hex.publish --yes"
    assert release_please =~ "HEX_API_KEY"
    refute release_please =~ "sync_release_summary"

    publish_hex_section =
      release_please
      |> String.split("publish-hex:")
      |> Enum.at(1, "")
      |> String.split("\n  verify:")
      |> hd()

    refute publish_hex_section =~ "if: false"
  end

  test "release-please.yml includes preflight and publish hardening" do
    release_please = File.read!(".github/workflows/release-please.yml")

    assert release_please =~ "Detect already-tagged release PR"
    assert release_please =~ "Skip if version already on Hex"
    assert release_please =~ "Wait for Hex.pm index"
    assert release_please =~ "gate-ci-green"
    assert release_please =~ "post-publish-attest"
    assert release_please =~ "post-publish-smoke.yml"
  end

  test "release-pr-automerge.yml guards release PR merges" do
    automerge = File.read!(".github/workflows/release-pr-automerge.yml")

    assert automerge =~ "release-please--branches--main"
    assert automerge =~ "autorelease: pending"
    assert automerge =~ "do-not-merge"
    assert automerge =~ "verify / policy"
    assert automerge =~ "verify / test"
  end

  test "ci-verify.yml prepares knowledge migrations before semantic cache" do
    ci_verify = File.read!(@ci_verify)

    assert ci_verify =~ "mix ecto.migrate --to 20260511000300"
    assert ci_verify =~ "Scoria.TestSupport.Migrations.migrate_knowledge!()"
    assert ci_verify =~ "mix ecto.migrate"
  end

  test "hex-publish.yml recovery includes ci gate and idempotency" do
    hex_publish = File.read!(".github/workflows/hex-publish.yml")

    assert hex_publish =~ "gate-ci-green"
    assert hex_publish =~ "Skip if version already on Hex"
    assert hex_publish =~ "Wait for Hex.pm index"
    assert hex_publish =~ "post-publish-smoke.yml"
  end

  test "hex-publish.yml supports workflow_dispatch recovery with verify and publish" do
    hex_publish = File.read!(".github/workflows/hex-publish.yml")

    assert hex_publish =~ "workflow_dispatch"
    assert hex_publish =~ "tag:"
    assert hex_publish =~ "release_version"
    assert hex_publish =~ "ci-verify.yml"
    assert hex_publish =~ "needs.verify.result == 'success'"
    assert Regex.match?(~r/^\s+run: mix hex\.publish --yes/m, hex_publish)
    refute hex_publish =~ "sync_release_summary"
  end

  test "release-please bootstrap config reflects prepared 0.1.1 maintenance release" do
    manifest = File.read!(".release-please-manifest.json")
    config = File.read!("release-please-config.json")

    assert manifest =~ "0.1.1"
    refute manifest =~ "0.0.0"
    refute config =~ "release-as"
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

  test "policy job runs warning baseline and inventory checks before compile WAE" do
    ci_verify = File.read!(@ci_verify)
    [policy_section, _test_section] = split_jobs(ci_verify)

    assert policy_section =~ @baseline_check
    assert policy_section =~ @inventory_baseline_check
    assert index_of(policy_section, @baseline_check) <
             index_of(policy_section, @inventory_baseline_check)
    assert index_of(policy_section, @inventory_baseline_check) < index_of(policy_section, @compile_wae)
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
    operator_docs = File.read!(@operator_docs)

    assert operator_docs =~ "mix scoria.warning_ratchet.test"
    assert operator_docs =~ "mix scoria.warning_ratchet.check"
    assert length(Scoria.WarningRatchet.high_signal_wae_paths()) > 0
  end

  test "test job runs semantic lane after runtime_to_handoff and before ratchet hygiene" do
    ci_verify = File.read!(@ci_verify)
    [_policy_section, test_section] = split_jobs(ci_verify)
    runtime_to_handoff = VerificationLanes.ci_command(:runtime_to_handoff)

    assert test_section =~ @semantic_lane
    assert index_of(test_section, runtime_to_handoff) < index_of(test_section, @semantic_lane)

    assert index_of(test_section, @semantic_lane) <
             index_of(
               test_section,
               "MIX_ENV=test mix test --warnings-as-errors test/scoria/warning_inventory/tmp_preflight_test.exs"
             )
  end

  test "test job runs full suite WAE after closeout lanes and before knowledge WAE lane" do
    ci_verify = File.read!(@ci_verify)
    [_policy_section, test_section] = split_jobs(ci_verify)
    runtime_to_handoff = VerificationLanes.ci_command(:runtime_to_handoff)

    assert test_section =~ "run: mix test --warnings-as-errors"
    refute test_section =~ "mix scoria.warning_ratchet.test --warnings-as-errors"
    assert index_of(test_section, runtime_to_handoff) <
             index_of(test_section, "run: mix test --warnings-as-errors")

    assert index_of(test_section, "run: mix test --warnings-as-errors") <
             index_of(test_section, "mix test.knowledge --warnings-as-errors")
  end

  test "test job runs connector lane after knowledge WAE and before gallery lane" do
    ci_verify = File.read!(@ci_verify)
    [_policy_section, test_section] = split_jobs(ci_verify)
    connector_cmd = VerificationLanes.ci_command(:connector)
    knowledge_cmd = "mix test.knowledge --warnings-as-errors"
    gallery_cmd = VerificationLanes.ci_command(:support_copilot_gallery)

    assert test_section =~ connector_cmd
    assert index_of(test_section, knowledge_cmd) < index_of(test_section, connector_cmd)
    assert index_of(test_section, connector_cmd) < index_of(test_section, gallery_cmd)
    refute :connector in VerificationLanes.closeout_order()
  end

  test "test job runs support copilot gallery lane after knowledge WAE and outside closeout order" do
    ci_verify = File.read!(@ci_verify)
    [_policy_section, test_section] = split_jobs(ci_verify)
    gallery_cmd = VerificationLanes.ci_command(:support_copilot_gallery)
    knowledge_cmd = "mix test.knowledge --warnings-as-errors"

    assert test_section =~ gallery_cmd
    assert index_of(test_section, knowledge_cmd) < index_of(test_section, gallery_cmd)
    refute :support_copilot_gallery in VerificationLanes.closeout_order()
  end

  test "maintainer guide documents Hex release section and README links anchor" do
    maintainer_docs = File.read!(@maintainer_docs)
    readme = File.read!("README.md")

    assert maintainer_docs =~ "## Hex release & recovery"
    assert maintainer_docs =~ "hex-release--recovery-maintainers"
    assert maintainer_docs =~ "HEX_API_KEY"
    assert maintainer_docs =~ "hex-publish.yml"
    assert maintainer_docs =~ "release-please--"
    assert readme =~ "docs/MAINTAINERS.md"
  end

  test "CI-03 documents CI gate map for maintainers" do
    maintainer_docs = File.read!(@maintainer_docs)

    assert maintainer_docs =~ "CI gate map"
    assert maintainer_docs =~ "policy"
    assert maintainer_docs =~ "needs: policy" or maintainer_docs =~ "`policy`"
    assert maintainer_docs =~ "mix test.semantic_fast_path"
    assert maintainer_docs =~ "mix test.connector"
    assert maintainer_docs =~ "mix scoria.warning_inventory.check_baseline"
    assert maintainer_docs =~ "Version namespaces"
    assert maintainer_docs =~ "mix scoria.test.install_contract"
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

  test "maintainer gate map pins v2.10 PR vs release proof depth" do
    maintainer_docs = File.read!(@maintainer_docs)
    gate_map = section_after(maintainer_docs, "## CI gate map")
    pr_release = section_after(gate_map, "**PR vs release proof depth**")

    assert pr_release =~ "mix test.adoption"
    assert pr_release =~ "content-revision upgrade"
    assert pr_release =~ "Tarball consumer full overlay" or pr_release =~ "mix hex.build"
    assert pr_release =~ "mix scoria.post_publish_smoke"
    assert pr_release =~ "publish-hex"
    assert maintainer_docs =~ "post-publish-smoke.yml"
    assert pr_release =~ "scoria-0.1.0-unpack"
    assert pr_release =~ "HEAD tarball"
    assert pr_release =~ "baseline exact previous"
    assert pr_release =~ "target just-published"
    assert maintainer_docs =~ "v2.x"
  end

  test "maintainer CI gate map documents topology, parity, ratchet, and failure diagnosis" do
    maintainer_docs = File.read!(@maintainer_docs)
    gate_map = section_after(maintainer_docs, "## CI gate map")

    assert gate_map =~ "Policy job"
    assert gate_map =~ "Test job closeout"
    assert gate_map =~ "Local parity"
    assert gate_map =~ "Ratchet is maintainer-only"
    assert gate_map =~ "When CI fails, run the matching maintainer command next"
    assert gate_map =~ "mix compile --warnings-as-errors"
    refute gate_map =~ "Policy: compile WAE failed → `MIX_ENV=test mix compile --warnings-as-errors`"
  end

  test "README links maintainers to maintainer guide near status section" do
    readme = File.read!("README.md")

    assert readme =~ "For maintainers"
    assert readme =~ "docs/MAINTAINERS.md"
    assert readme =~ "CI topology"
    refute String.match?(readme, ~r/Maintainer guide.*\n.*Maintainer guide/s)
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

  test "test config uses inline workflow dispatch for deterministic integration specs" do
    test_config = File.read!("config/test.exs")

    assert test_config =~ ":workflow_dispatch, :inline"
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

  test "planning ledgers reflect shipped hex consumer and connector milestones" do
    roadmap = File.read!(".planning/ROADMAP.md")
    archived_roadmap = File.read!(".planning/milestones/v2.10-ROADMAP.md")
    milestones = File.read!(".planning/MILESTONES.md")

    assert roadmap =~ "v2.15"
    assert roadmap =~ "Connector Adoption Lane"
    assert archived_roadmap =~ "81"
    assert archived_roadmap =~ "post-publish"
    assert milestones =~ "v2.10 Hex Consumer"
    assert milestones =~ "v2.12 Adoption Confidence"
  end

  defp lane_contract_step(policy_section) do
    case Regex.run(
           ~r/- name: Verify lane-contract tests with warnings as errors\n(?:\s+env:\n(?:\s+.+\n)+)?\s+run: (.+)/,
           policy_section
         ) do
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
