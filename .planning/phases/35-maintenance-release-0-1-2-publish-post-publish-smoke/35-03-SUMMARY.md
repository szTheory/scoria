---
phase: 35-maintenance-release-0-1-2-publish-post-publish-smoke
plan: 03
subsystem: release
tags: [hex, post-publish-smoke, registry, recovery]

requires:
  - phase: 35-02
    provides: PR #3 merged as release commit 26eb9a5e686fe4957196dfa5c6654121bda65c03.
provides:
  - Hex lists `scoria` `0.1.2` as live and latest.
  - Post-publish registry smoke passed for `SCORIA_REGISTRY_VERSION=0.1.2`.
  - Fresh install and previous-live registry upgrade proofs both passed against live Hex.
  - Recovery actions were classified and bounded; no `0.1.1` publish/backfill occurred.
affects: [release, hex, post-publish-smoke, host-app-proof]

tech-stack:
  added: []
  patterns:
    - Visible-package smoke failures are classified before rerun; only smoke reruns after Hex is live.
    - Registry proof harness assertions cover the exact generated-host steps executed by the proof.

key-files:
  created:
    - .planning/phases/35-maintenance-release-0-1-2-publish-post-publish-smoke/35-03-SUMMARY.md
  modified:
    - .github/workflows/post-publish-smoke.yml
    - test/scoria/ci_policy_contract_test.exs
    - test/scoria/host_app_registry_upgrade_proof_test.exs
    - test/scoria/host_app_proof_architecture_test.exs
    - test/support/scoria/host_app_proof/generator.ex
    - test/support/scoria/host_app_proof/runner.ex

key-decisions:
  - "The canceled post-merge Release Please run was classified as uncertain publish recovery because the GitHub release existed but Hex did not list 0.1.2."
  - "After Hex listed 0.1.2, all further recovery was smoke-only; no additional publish workflow was dispatched."
  - "The final recovery classification is visible transient smoke rerun: setup/harness failures were fixed, then live registry smoke passed."

patterns-established:
  - "Post-publish smoke prepares the root Scoria test database before generated-host registry proof."
  - "Registry upgrade proof uses an explicit long ExUnit timeout and registry-specific expected overlay steps."

requirements-completed: [REL-01, REL-02, REL-03]

duration: 48 min
completed: 2026-06-19
status: complete
---

# Phase 35 Plan 03: Publish and Post-Publish Smoke Summary

**`scoria` `0.1.2` is live on Hex, latest in the registry, and verified by the post-publish smoke.**

## Performance

- **Started:** 2026-06-19T14:53:30Z
- **Completed:** 2026-06-19T15:41:19Z
- **Tasks:** 3 completed
- **Files modified:** 6

## Accomplishments

- Observed the post-merge Release Please run `27832832253` cancel after creating GitHub release `v0.1.2`; Hex did not list `0.1.2` at that point.
- Classified state as `uncertain publish recovery` and dispatched the existing publish recovery workflow with exact inputs `tag=v0.1.2` and `release_version=0.1.2`.
- Recovery run `27833277108` published to Hex successfully. Publish job: `https://github.com/szTheory/scoria/actions/runs/27833277108/job/82376529152`.
- Verified Hex visibility:
  - `mix hex.info scoria 0.1.2` reported `Released: 2026-06-19`, docs at `https://hexdocs.pm/scoria/0.1.2`, and publisher `sztheory`.
  - Hex API reported `latest_version: "0.1.2"` and releases `["0.1.2", "0.1.0"]`.
- Fixed the post-publish smoke setup after the chained recovery attest failed before proof because the root Scoria test DB was not migrated.
- Fixed two registry-proof harness issues exposed after Hex was visible: default ExUnit timeout on the slow upgrade proof and expected-step construction for registry overlays.
- Final post-publish smoke run `27834739958` succeeded. Job: `https://github.com/szTheory/scoria/actions/runs/27834739958/job/82379938042`.
- Current `main` CI for final harness commit `dd00cf9` passed, including `ci-gate`. Run: `https://github.com/szTheory/scoria/actions/runs/27834737160`.

## Task Commits

1. `2c1c667` - `fix(35-03): prepare post-publish smoke database`
2. `3d4f5cd` - `ci(35-03): extend registry upgrade smoke timeout`
3. `dd00cf9` - `ci(35-03): align registry upgrade smoke expectations`

## Recovery Classification

- Initial post-merge run: `uncertain publish recovery`
  - GitHub release `v0.1.2` existed at `https://github.com/szTheory/scoria/releases/tag/v0.1.2`.
  - Target commit: `26eb9a5e686fe4957196dfa5c6654121bda65c03`.
  - Published at: `2026-06-19T14:53:41Z`.
  - Hex did not list `0.1.2`, so the existing `hex-publish.yml` recovery workflow was used.
- After publish: `visible transient smoke rerun`
  - Hex listed `0.1.2`; no further publish workflow was dispatched.
  - Smoke failures were setup/harness failures, not package artifact failures.
  - Final smoke run passed.

## Remote Evidence

- Canceled post-merge Release Please run: `https://github.com/szTheory/scoria/actions/runs/27832832253`.
- Hex publish recovery run: `https://github.com/szTheory/scoria/actions/runs/27833277108`.
- Recovery publish job success: `https://github.com/szTheory/scoria/actions/runs/27833277108/job/82376529152`.
- Recovery chained attest setup failure: `https://github.com/szTheory/scoria/actions/runs/27833277108/job/82376844721`.
- First smoke-only rerun after DB prep: `https://github.com/szTheory/scoria/actions/runs/27834032241` (reached proof; exposed default timeout).
- Second smoke-only rerun after timeout fix: `https://github.com/szTheory/scoria/actions/runs/27834385743` (proof completed; exposed expected-step harness mismatch).
- Final smoke-only rerun success: `https://github.com/szTheory/scoria/actions/runs/27834739958`.
- Final smoke job success: `https://github.com/szTheory/scoria/actions/runs/27834739958/job/82379938042`.

## Verification

- `mix hex.info scoria 0.1.2` - live package found; `Config: {:scoria, "~> 0.1.2"}`; `Released: 2026-06-19`; publisher `sztheory`.
- `curl -fsS https://hex.pm/api/packages/scoria | jq '{latest_version, releases: [.releases[].version]}'` - `{latest_version: "0.1.2", releases: ["0.1.2", "0.1.0"]}`.
- Final smoke logs:
  - `Hex.pm lists scoria 0.1.2`.
  - `==> Post-publish registry attest for 0.1.2`.
  - Fresh install path ran `deps.get`, `scoria.install`, `ecto.create`, `ecto.migrate`, and route/runtime overlay smokes.
  - Upgrade path ran baseline install/check, `deps.clean scoria`, `deps.get`, dry-run/check, upgraded `scoria.install`, `ecto.migrate`, final check, and route/runtime overlay smokes.
  - `2 tests, 0 failures`.
- `SCORIA_LANE_CONTRACT_ONLY=true MIX_ENV=test mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs` - 58 tests, 0 failures after DB-prep workflow fix.
- `MIX_ENV=test mix test --no-start --warnings-as-errors test/scoria/host_app_proof_architecture_test.exs` - 3 tests, 0 failures after expected-step fix.
- `MIX_ENV=test mix test --no-start --warnings-as-errors --exclude registry_upgrade test/scoria/host_app_registry_upgrade_proof_test.exs` - proof file loaded; 1 live test excluded, 0 failures.
- Push CI for `dd00cf9` - success, `ci-gate` job `82381286428`.

## Deviations from Plan

- The normal post-merge Release Please path was canceled after GitHub release creation and before publish, so the existing `hex-publish.yml` recovery path was used.
- The chained recovery attest failed before registry proof due missing root DB migration; fixed the workflow setup and reran smoke only.
- Two smoke-only reruns were needed after Hex was visible to fix harness issues: upgrade proof timeout and expected-step construction.

**Total deviations:** 3 auto-fixed.
**Impact on plan:** Hex mutation remained bounded to the single classified publish recovery. After `0.1.2` became visible, only post-publish smoke was rerun.

## Issues Encountered

No remaining package artifact failures. Final live registry smoke passed.

## User Setup Required

None.

## Self-Check: PASSED

- `0.1.2` is live and latest on Hex.
- Post-publish registry smoke passed for `SCORIA_REGISTRY_VERSION=0.1.2`.
- Upgrade leg was not skipped and proved live-lineage `0.1.0` to `0.1.2`.
- No `0.1.1` publish/backfill path was used.

---
*Phase: 35-maintenance-release-0-1-2-publish-post-publish-smoke*
*Completed: 2026-06-19*
