# Phase 35 Research: Maintenance release - 0.1.2 publish + post-publish smoke

**Researched:** 2026-06-18T23:51:08Z
**Scope:** unblock Release Please PR #3, publish `0.1.2`, and prove live Hex install/upgrade smoke.
**Confidence:** HIGH for codebase/workflow findings; MEDIUM for live remote state because PR and registry state can change after the recorded timestamp.

## Summary

Phase 35 should be a narrow release unblock, not a release-system refactor. The current blocker is the release PR branch bumping `mix.exs` to `0.1.2` while `test/scoria/package_surface_test.exs` still requires the README commented GitHub fallback tag to match `HexConsumerContract.published_version/0`; the latest failed PR log shows the test expected `tag: "v0.1.2"` while README still says `tag: "v0.1.1"`. [VERIFIED: gh run log 27709940743/job 81968281525, 2026-06-18T23:51:08Z] [VERIFIED: test/scoria/package_surface_test.exs:55-62] [VERIFIED: README.md:56-65]

The correct unblock is to change the contract semantics on `main`: keep README Hex-primary, keep exactly one active Hex dependency, keep the commented GitHub fallback as fork/pinned-patch guidance, but stop tying that fallback tag to the pending release version. [VERIFIED: .planning/phases/35-maintenance-release-0-1-2-publish-post-publish-smoke/35-CONTEXT.md:D-14-D-19] Do not add README to Release Please `extra-files` or to the release PR automerge allowed-file list. [VERIFIED: .planning/phases/35-maintenance-release-0-1-2-publish-post-publish-smoke/35-CONTEXT.md:D-17-D-19] [VERIFIED: .github/workflows/release-pr-automerge.yml:119-150]

The second required fix is release-lineage correctness for REL-02. Hex currently lists only `0.1.0`, so the live upgrade proof for this release is `0.1.0 -> 0.1.2`, not arithmetic previous patch `0.1.1 -> 0.1.2`. [VERIFIED: curl https://hex.pm/api/packages/scoria, 2026-06-18T23:51:08Z] [VERIFIED: .planning/phases/35-maintenance-release-0-1-2-publish-post-publish-smoke/35-CONTEXT.md:D-08-D-13]

## Recommended Plan Slices

### Slice 1 - Main-branch release contract fix

Edit only the release contract code/tests needed to make the release PR green after Release Please refreshes it. [VERIFIED: .planning/phases/35-maintenance-release-0-1-2-publish-post-publish-smoke/35-CONTEXT.md:D-16-D-19]

Touch:
- `test/scoria/package_surface_test.exs`: keep the active Hex dependency assertions, keep `refute readme =~ "until the first Hex publish lands"`, and replace the exact `github_fallback_snippet(published_version())` assertion with a shape/intent assertion for a commented fallback line such as `# Fork or pinned patch only: {:scoria, github: "szTheory/scoria", tag: "v0.1.x"}`. [VERIFIED: test/scoria/package_surface_test.exs:55-79]
- `lib/scoria/hex_consumer_contract.ex`: replace pure patch arithmetic for registry upgrade baselines with previous-live registry release semantics; keep unit tests deterministic and offline. [VERIFIED: lib/scoria/hex_consumer_contract.ex:155-191]
- `test/scoria/hex_consumer_contract_test.exs`: assert `registry_upgrade_pair("0.1.2") == %{from: "0.1.0", to: "0.1.2"}` and name the behavior "previous live registry release." [VERIFIED: test/scoria/hex_consumer_contract_test.exs:64-74]
- Optional but useful: update failure/example text in `test/scoria/host_app_registry_upgrade_proof_test.exs` and `lib/mix/tasks/scoria.post_publish_smoke.ex` from `0.1.1` examples to `0.1.2` examples so maintainer output matches this release. [VERIFIED: test/scoria/host_app_registry_upgrade_proof_test.exs:10-24] [VERIFIED: lib/mix/tasks/scoria.post_publish_smoke.ex:18-22]

Recommended implementation shape:

```elixir
# In Scoria.HexConsumerContract
@previous_live_registry_release_overrides %{
  "0.1.2" => "0.1.0"
}

def previous_live_registry_release(version) when is_binary(version) do
  Map.get(@previous_live_registry_release_overrides, version, previous_patch_with_floor(version))
end

def registry_upgrade_pair(current_version) when is_binary(current_version) do
  %{from: previous_live_registry_release(current_version), to: current_version}
end
```

Keep the previous-patch helper private or explicitly named as fallback logic, not as the semantic source of truth. [VERIFIED: .planning/phases/35-maintenance-release-0-1-2-publish-post-publish-smoke/35-CONTEXT.md:D-10-D-13]

### Slice 2 - Local release preflight

Run the local release-surface checks before refreshing/merging PR #3. [VERIFIED: .planning/phases/35-maintenance-release-0-1-2-publish-post-publish-smoke/35-CONTEXT.md:D-20-D-24]

```bash
MIX_ENV=dev mix docs --warnings-as-errors
MIX_ENV=dev mix scoria.release_preview
MIX_ENV=test mix test --warnings-as-errors \
  test/scoria/package_surface_test.exs \
  test/scoria/hex_consumer_contract_test.exs \
  test/scoria/ci_policy_contract_test.exs \
  test/mix/tasks/scoria.release_preview_test.exs
rg -n "55432" .github/workflows/post-publish-smoke.yml
```

Expected `rg` result is zero hits; Phase 34 already changed post-publish smoke to `5432:5432` and `SCORIA_DB_PORT: 5432`. [VERIFIED: .github/workflows/post-publish-smoke.yml:51-63] [VERIFIED: rg command, 2026-06-18T23:51:08Z]

### Slice 3 - Refresh and merge Release PR #3

After the main-branch fix lands, refresh PR #3 through Release Please, not by hand-editing the release branch. [VERIFIED: .planning/phases/35-maintenance-release-0-1-2-publish-post-publish-smoke/35-CONTEXT.md:D-18]

Use:

```bash
gh workflow run release-please.yml --ref main
gh pr view 3 --json number,title,state,headRefName,headRefOid,mergeStateStatus,files,statusCheckRollup,url
gh pr checks 3 --watch
```

The refreshed PR must still show only `.release-please-manifest.json`, `CHANGELOG.md`, and `mix.exs` in its diff. [VERIFIED: gh pr view 3, 2026-06-18T23:51:08Z] [VERIFIED: .github/workflows/release-pr-automerge.yml:119-150] Merge authority is the latest release PR head SHA with `ci-gate` success, not stale local proof. [VERIFIED: .planning/phases/35-maintenance-release-0-1-2-publish-post-publish-smoke/35-CONTEXT.md:D-24]

### Slice 4 - Publish and post-publish proof

Let the existing automation publish after the release PR merges. The normal path is: Release PR Auto-Merge merges PR #3, dispatches CI on `main`, dispatches Release Please, Release Please creates the tag/release, waits for `ci-gate`, publishes to Hex, then calls `post-publish-smoke.yml`. [VERIFIED: .github/workflows/release-pr-automerge.yml:189-204] [VERIFIED: .github/workflows/release-please.yml:116-277]

Post-publish verification:

```bash
mix hex.info scoria 0.1.2
curl -fsS https://hex.pm/api/packages/scoria | jq '.latest_version, [.releases[].version]'
```

Then verify the chained `Post Publish Smoke / Registry consumer attest` job passed for `0.1.2`; if the chained job did not run or needs a transient rerun, dispatch the reusable smoke manually with:

```bash
gh workflow run post-publish-smoke.yml -f version=0.1.2
```

The smoke task must run with `SCORIA_REGISTRY_VERSION=0.1.2`, prove exact-pinned fresh install, and prove the upgrade leg from previous live registry release `0.1.0` to `0.1.2`. [VERIFIED: .github/workflows/post-publish-smoke.yml:116-129] [VERIFIED: lib/mix/tasks/scoria.post_publish_smoke.ex:39-52] [VERIFIED: test/scoria/host_app_registry_upgrade_proof_test.exs:23-41]

## Source Findings

- At 2026-06-18T23:51:08Z, PR #3 was open, non-draft, from `release-please--branches--main` to `main`, titled `chore(main): release 0.1.2`, and `UNSTABLE`. [VERIFIED: gh pr view 3, 2026-06-18T23:51:08Z]
- At that same check, PR #3 changed only `.release-please-manifest.json`, `CHANGELOG.md`, and `mix.exs`. [VERIFIED: gh pr view 3, 2026-06-18T23:51:08Z]
- The latest visible failing checks were `verify / full-suite (3/4)`, `verify / verify-summary`, and `ci-gate`; the failing test was `Scoria.PackageSurfaceTest` expecting a `v0.1.2` GitHub fallback snippet while README contains `v0.1.1`. [VERIFIED: gh pr view 3 statusCheckRollup, 2026-06-18T23:51:08Z] [VERIFIED: gh run log 27709940743/job 81968281525]
- Hex live registry state at 2026-06-18T23:51:08Z was `latest_version: "0.1.0"` with releases `["0.1.0"]`. [VERIFIED: curl https://hex.pm/api/packages/scoria, 2026-06-18T23:51:08Z]
- Local `main` has `mix.exs` and `.release-please-manifest.json` at `0.1.1`; PR #3 is the release branch that bumps the release files to `0.1.2`. [VERIFIED: mix.exs:4] [VERIFIED: .release-please-manifest.json:1-3] [VERIFIED: .planning/phases/35-maintenance-release-0-1-2-publish-post-publish-smoke/35-CONTEXT.md:D-01]
- `post-publish-smoke.yml` currently uses `5432:5432` and `SCORIA_DB_PORT: 5432`; local `rg -n "55432" .github/workflows/post-publish-smoke.yml` returned zero hits. [VERIFIED: .github/workflows/post-publish-smoke.yml:51-63] [VERIFIED: rg command, 2026-06-18T23:51:08Z]
- `release-pr-automerge.yml` rejects release PR files outside `.release-please-manifest.json`, `CHANGELOG.md`, and `mix.exs`. [VERIFIED: .github/workflows/release-pr-automerge.yml:119-150]
- `release-please.yml` already performs publish idempotency, dry-run publish, real `mix hex.publish --yes`, Hex index wait, and chained post-publish attest. [VERIFIED: .github/workflows/release-please.yml:236-277]
- `hex-publish.yml` is a manual recovery workflow with exact `tag` and `release_version` inputs; it is not the normal path when Release Please publish completes. [VERIFIED: .github/workflows/hex-publish.yml:1-24] [VERIFIED: .github/workflows/hex-publish.yml:121-197]
- Local CLI availability for execution planning: Elixir 1.19.5/OTP 28, Mix 1.19.5, GitHub CLI 2.94.0, `jq` 1.7.1, and `curl` 8.7.1 are installed. [VERIFIED: local CLI probe, 2026-06-18T23:51:08Z]

## Risks and Footguns

- Do not "fix" PR #3 by adding README to Release Please managed files or to the automerge allowlist; that broadens the release PR policy to solve a test semantics bug. [VERIFIED: .planning/phases/35-maintenance-release-0-1-2-publish-post-publish-smoke/35-CONTEXT.md:D-16-D-19]
- Do not hand-patch `release-please--branches--main` with source/test changes; put source/test fixes on `main`, then let Release Please refresh the release branch so PR #3 remains release-file-only. [VERIFIED: .planning/phases/35-maintenance-release-0-1-2-publish-post-publish-smoke/35-CONTEXT.md:D-18]
- Do not publish or backfill `0.1.1`; Phase 35's locked path is direct `0.1.2` publish from the current live registry baseline. [VERIFIED: .planning/phases/35-maintenance-release-0-1-2-publish-post-publish-smoke/35-CONTEXT.md:D-08-D-09]
- Do not reintroduce patch arithmetic for registry upgrades; it fails exactly when a prepared release was skipped. [VERIFIED: lib/scoria/hex_consumer_contract.ex:162-181] [VERIFIED: .planning/phases/35-maintenance-release-0-1-2-publish-post-publish-smoke/35-CONTEXT.md:D-09-D-13]
- Do not call Hex from unit tests. The live registry belongs to `post-publish-smoke.yml` and `mix scoria.post_publish_smoke`; local contract tests should stay deterministic and offline. [VERIFIED: .planning/phases/35-maintenance-release-0-1-2-publish-post-publish-smoke/35-CONTEXT.md:199-200]
- Do not merge based on stale checks, skipped checks, or local-only green runs; merge authority is the latest PR head SHA with `ci-gate` success. [VERIFIED: .planning/phases/35-maintenance-release-0-1-2-publish-post-publish-smoke/35-CONTEXT.md:D-24] [VERIFIED: .github/workflows/release-pr-automerge.yml:66-92]
- Do not blind-rerun publish if smoke fails after Hex visibility. First classify whether the failure is index lag, runner network, Postgres service, uncertain publish completion, or a real bad artifact. [VERIFIED: .planning/phases/35-maintenance-release-0-1-2-publish-post-publish-smoke/35-CONTEXT.md:D-27-D-28]
- Do not treat README's current release prose as registry truth; Phase 35 already locks Hex as the source of truth for live package state. [VERIFIED: .planning/phases/35-maintenance-release-0-1-2-publish-post-publish-smoke/35-CONTEXT.md:D-02]
- Do not touch unrelated surfaces: no CI topology changes, no required-check rename, no `VerificationLanes.closeout_order/0` change, no Docker fleet work, no UI polish, no broad docs rewrite. [VERIFIED: .planning/phases/35-maintenance-release-0-1-2-publish-post-publish-smoke/35-CONTEXT.md:20] [VERIFIED: .planning/STATE.md:52-63]

Files the planner should not touch for this phase:
- `README.md` for release-version synchronization or fallback-tag churn. [VERIFIED: .planning/phases/35-maintenance-release-0-1-2-publish-post-publish-smoke/35-CONTEXT.md:D-14-D-19]
- `.github/workflows/release-pr-automerge.yml` allowed-file policy. [VERIFIED: .github/workflows/release-pr-automerge.yml:119-150]
- `release-please-config.json` for README `extra-files`. [VERIFIED: release-please-config.json:1-13]
- `.github/workflows/ci.yml`, `.github/workflows/ci-verify.yml`, `.github/workflows/release-please.yml`, `.github/workflows/hex-publish.yml`, and `.github/workflows/post-publish-smoke.yml` unless execution uncovers a release automation defect outside the current known blocker. [VERIFIED: .planning/phases/35-maintenance-release-0-1-2-publish-post-publish-smoke/35-CONTEXT.md:D-19-D-28]
- `CHANGELOG.md`, `mix.exs`, and `.release-please-manifest.json` by hand on `main`; those remain Release Please-owned release PR files. [VERIFIED: gh pr view 3, 2026-06-18T23:51:08Z]

## Verification Strategy

REL-01 local pre-merge:
```bash
MIX_ENV=dev mix docs --warnings-as-errors
MIX_ENV=dev mix scoria.release_preview
MIX_ENV=test mix test --warnings-as-errors \
  test/scoria/package_surface_test.exs \
  test/scoria/hex_consumer_contract_test.exs \
  test/scoria/ci_policy_contract_test.exs \
  test/mix/tasks/scoria.release_preview_test.exs
```
[VERIFIED: .planning/phases/35-maintenance-release-0-1-2-publish-post-publish-smoke/35-CONTEXT.md:D-21]

REL-03 port guard:
```bash
rg -n "55432" .github/workflows/post-publish-smoke.yml
```
Expected: zero hits. [VERIFIED: .planning/phases/35-maintenance-release-0-1-2-publish-post-publish-smoke/35-CONTEXT.md:D-22] [VERIFIED: rg command, 2026-06-18T23:51:08Z]

Remote PR gate:
```bash
gh workflow run release-please.yml --ref main
gh pr view 3 --json headRefOid,mergeStateStatus,files,statusCheckRollup,url
gh pr checks 3 --watch
```
Expected: latest head SHA, release-file-only diff, and `ci-gate` success. [VERIFIED: .github/workflows/release-pr-automerge.yml:66-92] [VERIFIED: .github/workflows/release-pr-automerge.yml:119-150]

REL-01 publish proof:
```bash
gh run list --workflow release-please.yml --limit 5
gh run view <release-please-run-id> --json jobs,conclusion,url
```
Expected release workflow jobs: `CI Verify`, `Verify CI green on release SHA`, `Publish to Hex.pm`, and `Post-publish registry attest` all successful or publish skipped only because `0.1.2` is already visible. [VERIFIED: .github/workflows/release-please.yml:116-277]

REL-02 live registry proof:
```bash
mix hex.info scoria 0.1.2
curl -fsS https://hex.pm/api/packages/scoria | jq '.latest_version, [.releases[].version]'
```
Expected: `0.1.2` visible and latest. [VERIFIED: .planning/phases/35-maintenance-release-0-1-2-publish-post-publish-smoke/35-CONTEXT.md:D-25]

REL-02 smoke proof:
```bash
gh workflow run post-publish-smoke.yml -f version=0.1.2
```
Use this only if the chained attest needs a manual rerun; otherwise record the chained `post-publish-attest` run URL. [VERIFIED: .github/workflows/post-publish-smoke.yml:8-29] [VERIFIED: .github/workflows/release-please.yml:271-277]

## Open Questions / None

None. Recheck PR #3 and Hex live state immediately before execution because both are remote mutable state after the 2026-06-18T23:51:08Z snapshot. [VERIFIED: gh pr view 3 and curl hex.pm API, 2026-06-18T23:51:08Z]
