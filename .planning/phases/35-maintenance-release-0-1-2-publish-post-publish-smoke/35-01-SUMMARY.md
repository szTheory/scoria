---
phase: 35-maintenance-release-0-1-2-publish-post-publish-smoke
plan: 01
subsystem: release
tags: [hex, release, registry, exunit]

requires:
  - phase: 34-docker-dx-drift-guard-ci-guard-extension
    provides: post-publish smoke port guard already fixed before release verification
provides:
  - Hex-primary README install contract no longer treats GitHub fallback tags as pending-release truth.
  - Registry upgrade lineage for the direct 0.1.2 publish resolves from previous live Hex release 0.1.0.
  - Offline contract tests pin the previous-live registry release wording and behavior.
affects: [release, hex, post-publish-smoke, package-surface]

tech-stack:
  added: []
  patterns:
    - Deterministic previous-live registry lineage override with patch fallback for unknown future versions.

key-files:
  created:
    - .planning/phases/35-maintenance-release-0-1-2-publish-post-publish-smoke/35-01-SUMMARY.md
  modified:
    - test/scoria/package_surface_test.exs
    - test/scoria/hex_consumer_contract_test.exs
    - lib/scoria/hex_consumer_contract.ex

key-decisions:
  - "README remains Hex-primary; the commented GitHub fallback is fork/pinned-patch guidance, not a release-candidate tag contract."
  - "registry_upgrade_pair(\"0.1.2\") uses previous live Hex release 0.1.0 instead of patch-minus-one arithmetic."

patterns-established:
  - "Previous-live registry overrides live in Scoria.HexConsumerContract and keep unit tests offline."

requirements-completed: [REL-01, REL-02]

duration: 14 min
completed: 2026-06-19
status: complete
---

# Phase 35 Plan 01: Main-Branch Release Contract Fix Summary

**Hex-primary install guidance and previous-live registry upgrade lineage are now encoded in offline release contract tests.**

## Performance

- **Duration:** 14 min
- **Started:** 2026-06-19T14:09:00Z
- **Completed:** 2026-06-19T14:23:09Z
- **Tasks:** 2 completed
- **Files modified:** 3

## Accomplishments

- Narrowed `Scoria.PackageSurfaceTest` so the active README dependency remains exactly `HexConsumerContract.hex_dep_snippet/0` while the commented GitHub fallback is checked only for fork/pinned-patch shape.
- Added an offline previous-live registry lineage test proving `registry_upgrade_pair("0.1.2") == %{from: "0.1.0", to: "0.1.2"}`.
- Implemented deterministic previous-live registry release lookup in `Scoria.HexConsumerContract`, with previous-patch behavior retained only as fallback for unknown versions.
- Confirmed README, Release Please config, release-pr automerge policy, and release workflow files were not modified by this plan.

## Task Commits

1. **Task 1: Narrow README fallback contract without changing README** - `d574d1b` (`test(35-01): narrow README fallback contract`)
2. **Task 2 RED: Add failing previous-live registry lineage test** - `e2477f1` (`test(35-01): add failing previous-live registry lineage test`)
3. **Task 2 GREEN: Encode previous-live registry lineage** - `fbb5e2d` (`fix(35-01): encode previous-live registry lineage`)

## Files Created/Modified

- `test/scoria/package_surface_test.exs` - Removed the fallback-tag equality check against `published_version/0`; added fallback shape assertions for fork/pinned-patch guidance.
- `test/scoria/hex_consumer_contract_test.exs` - Added previous-live registry release wording and `0.1.0 -> 0.1.2` assertion.
- `lib/scoria/hex_consumer_contract.ex` - Added `previous_live_registry_release/1` and switched `registry_upgrade_pair/1` to use it.
- `.planning/phases/35-maintenance-release-0-1-2-publish-post-publish-smoke/35-01-SUMMARY.md` - Plan close-out evidence.

## Verification

- `MIX_ENV=test mix test --warnings-as-errors test/scoria/package_surface_test.exs` - 4 tests, 0 failures.
- `MIX_ENV=test mix test --warnings-as-errors test/scoria/hex_consumer_contract_test.exs` - 12 tests, 0 failures.
- `MIX_ENV=test mix test --warnings-as-errors test/scoria/package_surface_test.exs test/scoria/hex_consumer_contract_test.exs` - 16 tests, 0 failures.
- `rg -n "github_fallback_snippet\\(HexConsumerContract\\.published_version\\(\\)\\)" test/scoria/package_surface_test.exs` - no matches.
- `rg -n "mix hex\\.info|curl -fsS https://hex\\.pm|hex\\.pm/api" lib/scoria/hex_consumer_contract.ex test/scoria/hex_consumer_contract_test.exs` - no matches.
- `git diff --name-only -- README.md release-please-config.json .github/workflows/release-pr-automerge.yml .github/workflows/release-please.yml .github/workflows/hex-publish.yml .github/workflows/post-publish-smoke.yml .github/workflows/ci.yml .github/workflows/ci-verify.yml` - no paths.
- `timeout 300 make build` - Docker build completed successfully.

## Decisions Made

- Kept README unchanged and Hex-primary.
- Kept release automation allowlists unchanged.
- Encoded the live-registry lineage exception for `0.1.2` locally so unit tests remain deterministic and offline.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope expansion.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for Plan 35-02: local release preflight, Release Please refresh, and latest-SHA green CI gate before merging PR #3.

## Self-Check: PASSED

- Key modified files exist on disk.
- Commits for `35-01` are present in git history.
- Focused tests and release-file no-diff guards passed.

---
*Phase: 35-maintenance-release-0-1-2-publish-post-publish-smoke*
*Completed: 2026-06-19*
