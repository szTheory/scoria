defmodule Scoria.CiPolicyContractTest do
  use ExUnit.Case, async: true

  alias Scoria.VerificationLanes

  @ci_verify ".github/workflows/ci-verify.yml"
  @ci_entry ".github/workflows/ci.yml"
  @post_publish_smoke ".github/workflows/post-publish-smoke.yml"
  @compose_file "compose.yml"
  @dockerignore ".dockerignore"
  @maintainer_docs "docs/MAINTAINERS.md"
  @operator_docs "docs/operator_verification.md"
  @playwright_package "priv/dev/package.json"
  @ephemeral_range_min 32_768
  @baseline_check "mix scoria.warning_baseline.check"
  @inventory_baseline_check "mix scoria.warning_inventory.check_baseline"
  @semantic_lane "mix test.semantic_fast_path --warnings-as-errors"
  @compile_wae "mix compile --warnings-as-errors"
  @ci_policy_contract "test/scoria/ci_policy_contract_test.exs"
  @docker_dx_doc_contract "test/scoria/docker_dx_doc_contract_test.exs"
  @lane_contract "test/scoria/verification_lanes_test.exs"
  @ratchet_wae "mix scoria.warning_ratchet.test --warnings-as-errors"
  @layer_invariant_marker "INVARIANT: volatile source"

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
    assert release_please =~ "bootstrap-release-pr-ci"
    assert release_please =~ "prs_created"
  end

  test "release-pr-automerge.yml guards release PR merges" do
    automerge = File.read!(".github/workflows/release-pr-automerge.yml")

    assert automerge =~ "release-please--branches--main"
    assert automerge =~ "autorelease: pending"
    assert automerge =~ "do-not-merge"
    assert automerge =~ "ci-gate"
    assert automerge =~ "seq 1 12"
    assert automerge =~ "Trigger release workflow after merge"
  end

  test "MAINTAINERS.md documents fully automated release train" do
    maintainers = File.read!(@maintainer_docs)

    assert maintainers =~ "Normal patch release (fully automated)"
    assert maintainers =~ "RELEASE_PLEASE_TOKEN"
    assert maintainers =~ "no manual merge"
    refute maintainers =~ "Merge the Release PR"
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

  test "release-please bootstrap config matches mix.exs version" do
    manifest = File.read!(".release-please-manifest.json")
    config = File.read!("release-please-config.json")
    mix_exs = File.read!("mix.exs")

    version =
      ~r/@version "([^"]+)"/
      |> Regex.run(mix_exs)
      |> Enum.at(1)

    assert manifest =~ version
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
    assert ci_entry =~ "ci-gate"
    refute ci_entry =~ "\n  policy:"
  end

  test "policy job runs warning baseline and inventory checks before compile WAE" do
    ci_verify = File.read!(@ci_verify)
    [policy_section, _test_section] = split_jobs(ci_verify)

    assert policy_section =~ @baseline_check
    assert policy_section =~ @inventory_baseline_check

    assert index_of(policy_section, @baseline_check) <
             index_of(policy_section, @inventory_baseline_check)

    assert index_of(policy_section, @inventory_baseline_check) <
             index_of(policy_section, @compile_wae)

    assert index_of(policy_section, @baseline_check) < index_of(policy_section, @compile_wae)

    assert index_of(policy_section, @compile_wae) <
             index_of(policy_section, "Verify lane-contract tests with warnings as errors")
  end

  test "policy job compiles with MIX_ENV: test (WR-01 pin)" do
    ci_verify = File.read!(@ci_verify)
    [policy_section, _test_section] = split_jobs(ci_verify)

    assert policy_section =~ "MIX_ENV: test"
  end

  test "test job depends on build and preserves closeout chain order" do
    ci_verify = File.read!(@ci_verify)
    blocks = job_blocks(ci_verify)
    test_body = Map.fetch!(blocks, "test")

    release_preview = VerificationLanes.ci_command(:release_preview)
    adoption = VerificationLanes.ci_command(:adoption)
    runtime_to_handoff = VerificationLanes.ci_command(:runtime_to_handoff)

    assert test_body =~ "needs: build"
    assert test_body =~ release_preview
    assert test_body =~ adoption
    assert test_body =~ runtime_to_handoff

    assert index_of(test_body, release_preview) < index_of(test_body, adoption)
    assert index_of(test_body, adoption) < index_of(test_body, runtime_to_handoff)
  end

  test "postgres service is configured for the app-booting verify lanes (incl. ratchet)" do
    ci_verify = File.read!(@ci_verify)
    blocks = job_blocks(ci_verify)

    # Jobs that must have Postgres services
    assert Map.fetch!(blocks, "test") =~ "services:"
    assert Map.fetch!(blocks, "knowledge") =~ "services:"
    assert Map.fetch!(blocks, "connector") =~ "services:"
    assert Map.fetch!(blocks, "full-suite") =~ "services:"
    # ratchet runs `mix test`, which boots Scoria.Application (Oban.verify_migrated!/1 → DB);
    # the WARN-06 compile-only parity guard only captures faithfully with the app started, so
    # the lane needs Postgres like its siblings (a DB-free `--no-start` run breaks the guard).
    assert Map.fetch!(blocks, "ratchet") =~ "services:"

    # Jobs that must NOT have Postgres services (no `mix test` → no app boot)
    refute Map.fetch!(blocks, "policy") =~ "services:"
    refute Map.fetch!(blocks, "build") =~ "services:"
    refute Map.fetch!(blocks, "verify-summary") =~ "services:"
  end

  test "no CI Postgres job binds a host port in the ephemeral range (>= 32768)" do
    ci_verify = File.read!(@ci_verify)
    ci_entry = File.read!(@ci_entry)
    post_publish = File.read!(@post_publish_smoke)

    # Derive all job blocks that reference postgres: across policy and smoke workflows.
    # job_blocks/1 is file-agnostic — call once per file, filter by body content.
    verify_postgres =
      job_blocks(ci_verify) |> Enum.filter(fn {_name, body} -> body =~ "postgres:" end)

    entry_postgres =
      job_blocks(ci_entry) |> Enum.filter(fn {_name, body} -> body =~ "postgres:" end)

    post_publish_postgres =
      post_publish
      |> job_blocks()
      |> Enum.filter(fn {_name, body} -> body =~ "postgres:" end)
      |> Enum.map(fn {job, body} -> {"post-publish-smoke.yml:#{job}", body} end)

    postgres_blocks = Map.new(verify_postgres ++ entry_postgres ++ post_publish_postgres)

    # Non-empty guard: broken regex cannot vacuously pass.
    # Current count: e2e (ci.yml) + four ci-verify.yml jobs + post-publish smoke = 6.
    assert map_size(postgres_blocks) >= 6,
           "expected >= 6 postgres jobs across ci.yml, ci-verify.yml, and " <>
             "post-publish-smoke.yml; regex may be broken"

    assert Map.has_key?(postgres_blocks, "post-publish-smoke.yml:smoke"),
           "FLAKE-01 scanner must include post-publish-smoke.yml:smoke so the " <>
             "post-publish registry attest cannot bypass fixed host-port enforcement"

    # Assert no ports: binding uses a host port in the ephemeral range (>= 32768).
    # GitHub runner ephemeral port range: 32768–60999 (Linux kernel default).
    # Port 55432 is in this range — the root cause of FLAKE-01 (run 27508317719).
    for {job, body} <- postgres_blocks do
      # Match `HOST:CONTAINER` fixed host-port binds, including quoted forms
      # (`- "55432:5432"`) and optional `/tcp` protocol suffix. A bare `- NNNN`
      # short form is intentionally NOT matched: it publishes the container port
      # to a *random* host port, which cannot reintroduce the FLAKE-01 fixed-bind
      # collision and would be a false positive if flagged.
      port_bindings = Regex.scan(~r/-\s*["']?(\d+):\d+(?:\/tcp)?["']?/, body)

      # Per-block non-empty guard: every postgres job here publishes an explicit
      # `5432:5432` bind, so a block yielding zero extractions means the regex
      # broke or an unrecognized mapping form slipped in — fail loud, not vacuously.
      assert port_bindings != [],
             "Job #{job}: no host:container port binding extracted — the FLAKE-01 " <>
               "ephemeral-port guard must not pass vacuously (regex broken or unknown form)"

      for [_full, host_port_str] <- port_bindings do
        host_port = String.to_integer(host_port_str)

        assert host_port < @ephemeral_range_min,
               "Job #{job}: host port #{host_port} is in the ephemeral range (>= 32768) — " <>
                 "use a port below 32768 to prevent kernel bind conflicts on GitHub runners"
      end
    end
  end

  test "e2e job in ci.yml has no TEMP diagnostic step" do
    ci_entry = File.read!(@ci_entry)
    refute ci_entry =~ "TEMP diagnose", "TEMP diagnostic step must be removed from ci.yml e2e job"
  end

  test "no test workflow step uses continue-on-error or a retry-action" do
    ci_verify = File.read!(@ci_verify)
    ci_entry = File.read!(@ci_entry)

    refute ci_verify =~ "continue-on-error",
           "ci-verify.yml must not use continue-on-error on any step (D-07 zero-retry policy)"

    refute ci_entry =~ "continue-on-error",
           "ci.yml must not use continue-on-error on any step (D-07 zero-retry policy)"

    # Retry-action wrappers banned on test workflows (not carve-out release/automerge workflows)
    refute ci_verify =~ "nick-fields/retry"
    refute ci_verify =~ "Wandalen/wretry"
    refute ci_entry =~ "nick-fields/retry"
    refute ci_entry =~ "Wandalen/wretry"
  end

  test "WARN-06 documents WarningRatchet maintainer commands" do
    operator_docs = File.read!(@operator_docs)

    assert operator_docs =~ "mix scoria.warning_ratchet.test"
    assert operator_docs =~ "mix scoria.warning_ratchet.check"
    assert length(Scoria.WarningRatchet.high_signal_wae_paths()) > 0
  end

  test "test job runs semantic lane after runtime_to_handoff" do
    ci_verify = File.read!(@ci_verify)
    blocks = job_blocks(ci_verify)
    test_body = Map.fetch!(blocks, "test")
    runtime_to_handoff = VerificationLanes.ci_command(:runtime_to_handoff)

    assert test_body =~ @semantic_lane
    assert index_of(test_body, runtime_to_handoff) < index_of(test_body, @semantic_lane)

    # full-suite: matrix job carries WAE (moved out of test: job)
    full_suite_body = Map.fetch!(job_blocks(ci_verify), "full-suite")
    assert full_suite_body =~ "mix test --warnings-as-errors"
    assert full_suite_body =~ "--partitions 4"

    # ratchet is a separate parallel job (not a step in test:)
    ratchet_body = Map.fetch!(blocks, "ratchet")
    assert ratchet_body =~ "needs: build"
    assert ratchet_body =~ "tmp_preflight_test.exs"
    refute test_body =~ "tmp_preflight_test.exs"
  end

  test "test job ends with semantic lane; full-suite is a parallel matrix job" do
    ci_verify = File.read!(@ci_verify)
    blocks = job_blocks(ci_verify)
    test_body = Map.fetch!(blocks, "test")

    refute test_body =~ "run: mix test --warnings-as-errors"
    refute test_body =~ "mix scoria.warning_ratchet.test --warnings-as-errors"
    full_suite_body = Map.fetch!(blocks, "full-suite")
    assert full_suite_body =~ "mix test --warnings-as-errors"
    assert full_suite_body =~ "--partitions 4"
    assert full_suite_body =~ "needs: build"

    # knowledge is a separate parallel job with needs: build
    knowledge_body = Map.fetch!(blocks, "knowledge")
    assert knowledge_body =~ "needs: build"
    assert knowledge_body =~ "mix test.knowledge --warnings-as-errors"
    # test: job does NOT contain the knowledge command
    refute test_body =~ "mix test.knowledge --warnings-as-errors"
  end

  test "full-suite job is a 4-way matrix with correct partition wiring and no DB name collision" do
    ci_verify = File.read!(@ci_verify)
    blocks = job_blocks(ci_verify)

    # Non-empty guard: broken job_blocks/1 regex can't vacuously pass
    assert map_size(blocks) > 0, "job_blocks/1 returned empty — regex may be broken"

    full_suite_body = Map.fetch!(blocks, "full-suite")

    # SC#1 — sharded invocation
    assert full_suite_body =~ "needs: build"
    assert full_suite_body =~ "mix test --warnings-as-errors"
    assert full_suite_body =~ "--partitions 4"
    assert full_suite_body =~ "MIX_TEST_PARTITION"
    assert full_suite_body =~ "${{ matrix.partition }}"
    assert full_suite_body =~ "partition: [1, 2, 3, 4]"
    assert full_suite_body =~ "fail-fast: false"
    refute full_suite_body =~ "continue-on-error"

    # SC#2 — DB isolation: absence of SCORIA_DB_NAME is load-bearing
    # config/test.exs: database: System.get_env("SCORIA_DB_NAME") || "scoria_test#{MIX_TEST_PARTITION}"
    # When SCORIA_DB_NAME is nil, the || resolves scoria_test1..4 per shard.
    refute full_suite_body =~ "SCORIA_DB_NAME"
    assert full_suite_body =~ "MIX_TEST_PARTITION: ${{ matrix.partition }}"
    assert full_suite_body =~ "services:"

    # SC#3 — Rem-completeness proof (filter_by_partition/3, Elixir 1.19.5):
    #   sorted_files |> Enum.with_index() |> Enum.filter(fn {_, i} -> rem(i, total) == partition - 1 end)
    #   For total=4, partitions {1,2,3,4} cover rem values {0,1,2,3} — a complete residue system.
    #   Union of 4 shards = full suite BY CONSTRUCTION. These two assertions keep --partitions N
    #   and matrix.partition list in sync; a mismatch (e.g., --partitions 3 + [1,2,3,4]) is caught.
    assert full_suite_body =~ "--partitions 4"
    assert full_suite_body =~ "partition: [1, 2, 3, 4]"
  end

  test "full-suite is explicitly wired into verify-summary fan-in (D-04 targeted pin)" do
    ci_verify = File.read!(@ci_verify)
    blocks = job_blocks(ci_verify)

    verify_summary_body = Map.fetch!(blocks, "verify-summary")

    assert verify_summary_body =~ "full-suite",
           "full-suite must be in verify-summary.needs — wiring it prevents a false-green fan-in"
  end

  test "connector lane is a parallel job with connector before gallery" do
    ci_verify = File.read!(@ci_verify)
    blocks = job_blocks(ci_verify)
    connector_body = Map.fetch!(blocks, "connector")
    connector_cmd = VerificationLanes.ci_command(:connector)
    gallery_cmd = VerificationLanes.ci_command(:support_copilot_gallery)

    assert connector_body =~ "needs: build"
    assert index_of(connector_body, connector_cmd) < index_of(connector_body, gallery_cmd)
    refute :connector in VerificationLanes.closeout_order()
  end

  test "gallery lane runs inside connector job after connector command" do
    ci_verify = File.read!(@ci_verify)
    blocks = job_blocks(ci_verify)
    connector_body = Map.fetch!(blocks, "connector")
    connector_cmd = VerificationLanes.ci_command(:connector)
    gallery_cmd = VerificationLanes.ci_command(:support_copilot_gallery)

    assert connector_body =~ gallery_cmd
    assert index_of(connector_body, connector_cmd) < index_of(connector_body, gallery_cmd)
    refute :support_copilot_gallery in VerificationLanes.closeout_order()
  end

  test "verify-summary fan-in wires every parallel verify lane (derived)" do
    ci_verify = File.read!(@ci_verify)
    blocks = job_blocks(ci_verify)

    # Derive: all top-level jobs (excluding policy, build, verify-summary) that have needs: build
    parallel_lanes =
      blocks
      |> Enum.filter(fn {name, body} ->
        name not in ["policy", "build", "verify-summary"] and body =~ "needs: build"
      end)
      |> Enum.map(fn {name, _} -> name end)
      |> MapSet.new()

    # Non-empty guard: a broken regex cannot vacuously pass
    assert MapSet.size(parallel_lanes) > 0,
           "expected at least one parallel verify lane with needs: build; regex may be broken"

    # Parse verify-summary.needs
    verify_summary_body = Map.fetch!(blocks, "verify-summary")
    needs_match = Regex.run(~r/needs:\s*\[([^\]]+)\]/, verify_summary_body)

    verify_summary_needs =
      case needs_match do
        [_, needs_str] ->
          needs_str |> String.split(",") |> Enum.map(&String.trim/1) |> MapSet.new()

        nil ->
          flunk("verify-summary job has no needs: [...] block")
      end

    # Subset assertion: every parallel lane is wired into verify-summary
    assert MapSet.subset?(parallel_lanes, verify_summary_needs),
           "unwired lanes: #{inspect(MapSet.difference(parallel_lanes, verify_summary_needs))}"
  end

  test "verify-summary fan-in fails on any non-success lane (if: always + skipped-as-failure)" do
    ci_verify = File.read!(@ci_verify)
    body = Map.fetch!(job_blocks(ci_verify), "verify-summary")

    # Runs even when a lane is skipped — otherwise a skipped lane would let the gate pass.
    assert body =~ "if: always()"
    # Aggregates every lane's result, not a hardcoded subset.
    assert body =~ "join(needs.*.result"
    # Load-bearing skipped-as-failure guard: anything other than "success" fails the gate.
    assert body =~ ~s|!= "success"|
    assert body =~ "exit 1"
  end

  test "topology docs stay in lockstep: stale heading gone, branch-protection gate name unchanged" do
    # Docs-drift guard: the pre-parallel "Test job closeout" heading must stay removed
    # from every adopter/maintainer-facing doc.
    refute File.read!(@maintainer_docs) =~ "Test job closeout"
    refute File.read!(@operator_docs) =~ "Test job closeout"

    # Branch-protection gate name is unchanged: ci.yml still exposes the `ci-gate` required
    # check, so the parallel restructure did not silently rename the protected status.
    assert File.read!(@ci_entry) =~ "ci-gate"
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

  test "cache keys include MIX_ENV segment to prevent dev/test collision" do
    ci_verify = File.read!(@ci_verify)
    ci_entry = File.read!(@ci_entry)

    assert ci_verify =~ ~r/key:.*-test-mix-/
    assert ci_entry =~ ~r/key:.*-dev-mix-/
    refute ci_verify =~ ~r/key: \$\{\{ runner\.os \}\}-mix-/
    refute ci_entry =~ ~r/key: \$\{\{ runner\.os \}\}-mix-/
  end

  test "build job exists in policy-side slice, needs policy, and has no services block" do
    ci_verify = File.read!(@ci_verify)
    [policy_section, _test_section] = split_jobs(ci_verify)

    assert policy_section =~ "\n  build:"
    assert policy_section =~ "needs: policy"
    assert policy_section =~ "mix compile --warnings-as-errors"
    assert policy_section =~ "upload-artifact"
    refute policy_section =~ "services:"
  end

  test "build job uploads artifact and test job downloads it" do
    ci_verify = File.read!(@ci_verify)
    [policy_section, test_section] = split_jobs(ci_verify)

    assert policy_section =~ "upload-artifact"
    assert test_section =~ "download-artifact"
  end

  test "test job needs build, not policy directly" do
    ci_verify = File.read!(@ci_verify)
    [_policy_section, test_section] = split_jobs(ci_verify)

    assert test_section =~ "needs: build"
    refute test_section =~ "needs: policy"
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
    assert ci_verify =~ "# ratchet:"
    assert ci_verify =~ "# knowledge:"
    assert ci_verify =~ "# connector:"
    assert ci_verify =~ "# full-suite:"
    assert ci_verify =~ "# verify-summary:"
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
    assert gate_map =~ "Parallel verify jobs"
    assert gate_map =~ "ratchet"
    assert gate_map =~ "knowledge"
    assert gate_map =~ "connector"
    assert gate_map =~ "full-suite"
    assert gate_map =~ "verify-summary"
    assert gate_map =~ "Local parity"
    assert gate_map =~ "Ratchet is maintainer-only"
    assert gate_map =~ "When CI fails, run the matching maintainer command next"
    assert gate_map =~ "mix compile --warnings-as-errors"

    refute gate_map =~
             "Policy: compile WAE failed → `MIX_ENV=test mix compile --warnings-as-errors`"
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

  test "policy job runs ci_policy_contract_test and Docker DX doc contract in lane-contract step" do
    ci_verify = File.read!(@ci_verify)
    [policy_section, _test_section] = split_jobs(ci_verify)
    lane_step = lane_contract_step(policy_section)

    assert lane_step =~ @ci_policy_contract
    assert lane_step =~ @docker_dx_doc_contract
    assert lane_step =~ @lane_contract
    assert index_of(lane_step, @ci_policy_contract) < index_of(lane_step, @docker_dx_doc_contract)
    assert index_of(lane_step, @docker_dx_doc_contract) < index_of(lane_step, @lane_contract)
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

  test "Dockerfile.dev keeps cache-optimal COPY layer order (deps -> config -> source)" do
    df = File.read!("Dockerfile.dev")
    i_lock = index_of(df, "COPY mix.exs mix.lock")
    i_config = index_of(df, "COPY config")
    i_lib = index_of(df, "COPY lib")
    assert i_lock < i_config, "COPY mix.exs mix.lock must precede COPY config"
    assert i_config < i_lib, "COPY config must precede COPY lib"

    assert df =~ @layer_invariant_marker,
           "Dockerfile.dev must contain the boundary invariant comment (#{inspect(@layer_invariant_marker)})"
  end

  test "Dockerfile.dev preserves BuildKit caches for cold rebuilds" do
    df = File.read!("Dockerfile.dev")

    assert df =~ "--mount=type=cache,target=/var/cache/apt"
    assert df =~ "--mount=type=cache,target=/var/lib/apt/lists"
    assert df =~ "--mount=type=cache,target=/root/.hex"
    assert df =~ "--mount=type=cache,target=/root/.cache/rebar3"
  end

  test "compose.yml keeps Docker dev services namespaced and collision-resistant" do
    compose = File.read!(@compose_file)
    db = service_section(compose, "db")
    web = service_section(compose, "web")

    refute compose =~ ~r/^name:\s/m
    refute compose =~ ~r/^\s+container_name:\s/m
    refute db =~ ~r/^\s+ports:\s/m

    assert web =~ ~s("127.0.0.1::4000")
    assert compose =~ "proxy:\n    external: true"

    assert web =~
             "traefik.http.routers.${COMPOSE_PROJECT_NAME:-scoria}.rule=Host(`${SCORIA_HOST:-scoria.localhost}`)"

    assert web =~ "traefik.http.routers.${COMPOSE_PROJECT_NAME:-scoria}.entrypoints=web"

    assert web =~
             "traefik.http.routers.${COMPOSE_PROJECT_NAME:-scoria}.service=${COMPOSE_PROJECT_NAME:-scoria}"

    assert web =~
             "traefik.http.services.${COMPOSE_PROJECT_NAME:-scoria}.loadbalancer.server.port=4000"

    assert web =~ "scoria.local-dev.host=${SCORIA_HOST:-scoria.localhost}"
  end

  test "compose.yml preserves Docker dev cache volumes" do
    compose = File.read!(@compose_file)
    web = service_section(compose, "web")
    shots = service_section(compose, "shots")

    assert web =~ "deps:/app/deps"
    assert web =~ "build:/app/_build"
    assert web =~ "hex:/root/.hex"
    assert web =~ "mix:/root/.mix"
    assert shots =~ "shots_node_modules:/app/priv/dev/node_modules"
    assert shots =~ "shots_npm_cache:/root/.npm"
    assert compose =~ "\n  shots_npm_cache:"
  end

  test "compose.yml keeps critique API key out of Compose interpolation" do
    compose = File.read!(@compose_file)
    critique = service_section(compose, "critique")

    assert critique =~ "secrets:"
    assert compose =~ "anthropic_api_key:\n    environment: ANTHROPIC_API_KEY"
    assert critique =~ "cat /run/secrets/anthropic_api_key"
    refute compose =~ "ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY"
  end

  test "dev entrypoint banner points to diagnostics and safe critique command" do
    entrypoint = File.read!("docker/dev-entrypoint.sh")

    assert entrypoint =~ "make url | make fleet | make doctor"
    assert entrypoint =~ "op run --env-file"
    assert entrypoint =~ "Compose secret"
    refute entrypoint =~ "docker compose --profile shots run --rm critique     # + LLM critique"
  end

  test "Playwright image tag tracks the dev package version" do
    compose = File.read!(@compose_file)
    package = File.read!(@playwright_package)
    [_, declared] = Regex.run(~r/"@playwright\/test":\s*"([^"]+)"/, package)
    version = declared |> then(&Regex.run(~r/\d+\.\d+\.\d+/, &1)) |> List.first()

    assert compose =~ "mcr.microsoft.com/playwright:v#{version}-noble"
  end

  test "Makefile defaults to checkout-specific instances and no-build daily startup" do
    makefile = File.read!("Makefile")

    assert makefile =~ "WORKTREE_ID"
    assert makefile =~ "INSTANCE ?= $(APP)-$(if $(BRANCH),$(BRANCH),local)-$(WORKTREE_ID)"
    assert makefile =~ "docker compose up --no-build"
    assert makefile =~ "docker compose up --build"
    assert makefile =~ "docker ps --filter label=traefik.enable=true"
    assert makefile =~ "doctor:"
    assert makefile =~ "SCORIA_DB_PORT ?= 55432"
    assert makefile =~ "SCORIA_DB_POOL_SIZE ?= 5"
    assert makefile =~ "NATIVE_PROJECT_NAME ?= $(COMPOSE_PROJECT_NAME)-native"
    assert makefile =~ "docker compose -p $(NATIVE_PROJECT_NAME) -f dev/pgvector-compose.yml"
    assert makefile =~ "native-db-down:"
    refute makefile =~ "--filter name=scoria-"
  end

  test "native DB helper and configs avoid default host Postgres" do
    native_compose = File.read!("dev/pgvector-compose.yml")
    dev_config = File.read!("config/dev.exs")
    test_config = File.read!("config/test.exs")

    assert native_compose =~ "127.0.0.1:${SCORIA_DB_PORT:-55432}:5432"
    assert native_compose =~ "-p <instance>-native"
    assert dev_config =~ ~s|System.get_env("SCORIA_DB_PORT", "55432")|
    assert test_config =~ ~s|System.get_env("SCORIA_DB_PORT", "55432")|
    assert test_config =~ "SCORIA_TEST_DB_POOL_SIZE"
  end

  test ".dockerignore keeps generated dev artifacts and local secrets out of image context" do
    dockerignore = File.read!(@dockerignore)

    for entry <- [
          "_build/",
          "deps/",
          "priv/dev/node_modules/",
          "priv/dev/package-lock.json",
          "priv/dev/test-results/",
          "priv/dev/e2e/test-results/",
          "priv/dev/e2e/playwright-report/",
          "priv/shots/",
          ".env",
          ".envrc",
          ".env.op"
        ] do
      assert dockerignore =~ entry
    end
  end

  test ".env.example documents a collision-resistant instance example" do
    env_example = File.read!(".env.example")

    assert env_example =~ "scoria-myfeature-a1b2c3d4",
           ".env.example should keep one concrete instance identity example for bare docker compose users"
  end

  defp lane_contract_step(policy_section) do
    case Regex.run(
           ~r/- name: Verify lane-contract tests with warnings as errors\n(?:\s+env:\n(?:\s+.+\n)+?)?\s+run: (.+)/,
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

  defp job_blocks(content) do
    # Match all top-level job names (2-space indent, word chars + hyphens, followed by colon)
    job_names =
      Regex.scan(~r/^  ([\w-]+):/m, content)
      |> Enum.map(&Enum.at(&1, 1))

    Enum.reduce(Enum.zip(job_names, tl(job_names) ++ [nil]), %{}, fn {job, next_job}, acc ->
      start_marker = "\n  #{job}:"
      end_marker = if next_job, do: "\n  #{next_job}:", else: nil

      body =
        case :binary.match(content, start_marker) do
          {start, _} ->
            slice = String.slice(content, start, byte_size(content))

            if end_marker do
              case :binary.match(slice, end_marker) do
                {stop, _} -> String.slice(slice, 0, stop)
                :nomatch -> slice
              end
            else
              slice
            end

          :nomatch ->
            ""
        end

      Map.put(acc, job, body)
    end)
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

  defp service_section(content, service) do
    marker = "\n  #{service}:"

    case :binary.match(content, marker) do
      {start, _length} ->
        content
        |> String.slice(start + 1, byte_size(content))
        |> String.split(~r/\n  [a-zA-Z0-9_-]+:/, parts: 2)
        |> List.first()

      :nomatch ->
        flunk("expected service #{inspect(service)} in compose file")
    end
  end
end
