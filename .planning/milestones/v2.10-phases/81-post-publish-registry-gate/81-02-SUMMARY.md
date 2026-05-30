---
phase: 81-post-publish-registry-gate
plan: 02
subsystem: testing
tags: [hex, registry, host-app-proof, post-publish-smoke, exunit]

requires:
  - phase: 81-post-publish-registry-gate
    plan: 01
    provides: HexConsumerContract registry APIs and Generator :hex_registry mode
  - phase: 80-upgrade-smoke-in-adoption-lane
    provides: run_upgrade_proof!/2 orchestration and expected_upgrade_steps/1
provides:
  - run_registry_proof!/1 and expected_registry_steps/1 on HostAppProof Runner
  - Registry bump dispatch in run_upgrade_proof!/2 via {:registry, from:, to:}
  - host_app_registry_proof_test.exs and host_app_registry_upgrade_proof_test.exs
  - mix scoria.post_publish_smoke maintainer entrypoint
affects: [81-03, post-publish-smoke.yml, release-please.yml]

tech-stack:
  added: []
  patterns:
    - "Registry fresh-install proof is 6 fixed steps — route+runtime overlay subset only (D-69, D-71)"
    - "Registry upgrade reuses Phase 80 orchestration with bump: {:registry, from:, to:} (D-84)"
    - "overlay_from_dep!/1 runs after deps.get in baseline and upgrade registry legs"
    - "Failure MANIFEST and triage include dep_mode and registry_version for :hex_registry hosts (D-76)"

key-files:
  created:
    - test/scoria/host_app_registry_proof_test.exs
    - test/scoria/host_app_registry_upgrade_proof_test.exs
    - lib/mix/tasks/scoria.post_publish_smoke.ex
  modified:
    - test/support/scoria/host_app_proof/runner.ex

key-decisions:
  - "Registry upgrade overlay steps use host.overlay_tests for both baseline and upgrade — not upgrade_overlay_tests full depth"
  - "maybe_overlay_from_dep!/1 shared helper runs after deps.get in registry baseline, upgrade, and fresh-install paths"
  - "preserve replay tags: registry_proof and registry_upgrade for :hex_registry hosts"

patterns-established:
  - "SCORIA_REGISTRY_VERSION env gates all registry proof modules and Mix task"
  - "post_publish_smoke conditionally includes upgrade test when semver_upgrade_eligible?/1"

requirements-completed: [HEX-REGISTRY-01]

duration: 18min
completed: 2026-05-30
---

# Phase 81 Plan 02: Runner Registry Proof + ExUnit + Mix Task Summary

**Live Hex registry fresh-install and semver upgrade proof paths on HostAppProof Runner with maintainer `mix scoria.post_publish_smoke` entrypoint isolated from adoption lane**

## Performance

- **Duration:** 18 min
- **Started:** 2026-05-30T01:00:00Z
- **Completed:** 2026-05-30T01:18:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added `run_registry_proof!/1` and `expected_registry_steps/1` executing the 6-step registry subset (deps_get → install → migrate → route+runtime smokes)
- Extended `run_upgrade_proof!/2` with `bump: {:registry, from:, to:}` dispatch via `bump_registry_dep!/2` and `overlay_from_dep!/1` refresh
- Extended triage and MANIFEST with `dep_mode: hex_registry` and `registry_version` for registry hosts
- Created `:registry_proof` and `:registry_upgrade` ExUnit modules plus `mix scoria.post_publish_smoke` maintainer task

## Task Commits

Each task was committed atomically:

1. **Task 81-02-01: Add Runner registry proof and upgrade bump dispatch** - `a21ee31` (feat)
2. **Task 81-02-02: Add registry ExUnit modules and post_publish_smoke Mix task** - `1ff841d` (feat)

## Files Created/Modified

- `test/support/scoria/host_app_proof/runner.ex` - Registry proof runner, bump dispatch, MANIFEST/triage extensions
- `test/scoria/host_app_registry_proof_test.exs` - Fresh-install live Hex registry ExUnit proof
- `test/scoria/host_app_registry_upgrade_proof_test.exs` - Conditional semver upgrade ExUnit proof
- `lib/mix/tasks/scoria.post_publish_smoke.ex` - Maintainer release attest Mix entrypoint

## Decisions Made

- Registry upgrade `expected_upgrade_steps/1` uses `host.overlay_tests` for upgrade overlay atoms — registry subset stays route+runtime, not full tarball depth
- Shared `maybe_overlay_from_dep!/1` after `deps.get` in baseline, upgrade, and fresh-install registry paths
- Preserve replay commands tag `:registry_proof` / `:registry_upgrade` for registry hosts

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required for code delivery. Full smoke requires live Hex + Postgres (manual/CI in 81-03).

## Next Phase Readiness

- Ready for 81-03: `workflow_call` post-publish-smoke.yml refactor, blocking release attest jobs, operator gate map stub
- `mix scoria.post_publish_smoke` and ExUnit modules ready for CI wiring

## Self-Check: PASSED

- `[ -f test/scoria/host_app_registry_proof_test.exs ]` — PASS
- `[ -f lib/mix/tasks/scoria.post_publish_smoke.ex ]` — PASS
- `mix help scoria.post_publish_smoke` — PASS
- `rg -n 'host_app_registry_proof' lib/mix/tasks/test.adoption.ex` — no match (PASS)
- `rg -n 'def run_registry_proof!' test/support/scoria/host_app_proof/runner.ex` — PASS
- `rg -n 'def expected_registry_steps' test/support/scoria/host_app_proof/runner.ex` — PASS
- `MIX_ENV=test mix compile --warnings-as-errors` — PASS
- `git log --oneline --grep="81-02"` — 2 commits found

---
*Phase: 81-post-publish-registry-gate*
*Completed: 2026-05-30*
