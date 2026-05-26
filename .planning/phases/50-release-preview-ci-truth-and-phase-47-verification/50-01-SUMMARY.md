---
phase: 50-release-preview-ci-truth-and-phase-47-verification
plan: 01
subsystem: infra
tags: [github-actions, ci, docs, exunit, release-preview]
requires:
  - phase: 49-support-truth-and-adoption-closeout
    provides: Maintainer-facing release-preview command contract and closeout wording
provides:
  - CI release-preview step pinned to the supported dev environment
  - Operator guide wording that keeps `mix scoria.release_preview` canonical
  - Adoption-surface assertions that reject a test-env release-preview closeout contract
affects: [phase-47-verification, release-preview-lane, operator-docs, adoption-surface-tests]
tech-stack:
  added: []
  patterns:
    - Step-scoped CI env overrides for dev-only maintainer proof lanes
    - Source assertions that reject unsupported command variants in public docs
key-files:
  created:
    - .planning/phases/50-release-preview-ci-truth-and-phase-47-verification/50-01-SUMMARY.md
  modified:
    - .github/workflows/ci.yml
    - docs/operator_verification.md
    - test/scoria/adoption_surface_test.exs
key-decisions:
  - "Keep `mix scoria.release_preview` as the canonical maintainer command while forcing only the CI step to `MIX_ENV=dev`."
  - "Reject `MIX_ENV=test mix scoria.release_preview` at the adoption-surface test layer instead of broadening ExDoc into the test environment."
patterns-established:
  - "Public maintainer commands stay unprefixed even when CI needs an explicit environment override."
  - "Release-preview drift is caught by source assertions before broader support-truth changes regress."
requirements-completed: [ADPT-03, ADPT-04]
duration: ~1 min
completed: 2026-05-26
---

# Phase 50 Plan 01: Release-preview CI truth Summary

**Release-preview CI now runs in `MIX_ENV=dev` while maintainer docs and source assertions keep plain `mix scoria.release_preview` as the only supported closeout command**

## Performance

- **Duration:** ~1 min
- **Started:** 2026-05-26T13:16:04Z
- **Completed:** 2026-05-26T13:16:53Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Re-scoped the GitHub Actions release-preview step to `MIX_ENV=dev` without changing the job-wide `MIX_ENV=test` contract for database prep and test lanes.
- Updated the operator guide to explain the CI env boundary while preserving plain `mix scoria.release_preview` as the maintainer-facing proof command.
- Extended adoption-surface assertions so the docs must include `mix scoria.release_preview` and must not drift back to a test-env-prefixed release-preview contract.

## Task Commits

Each task was committed atomically:

1. **Task 1: Re-scope the CI release-preview step to the supported env** - `5c24c78` (fix)
2. **Task 2: Lock the maintainer command contract in docs and source assertions** - `be552b0` (fix)

## Files Created/Modified

- `.github/workflows/ci.yml` - Forces only the release-preview step to run in `MIX_ENV=dev`.
- `docs/operator_verification.md` - Documents the canonical maintainer lane and explains the CI-only dev env override.
- `test/scoria/adoption_surface_test.exs` - Guards the operator guide against drifting back to a test-env release-preview contract.
- `.planning/phases/50-release-preview-ci-truth-and-phase-47-verification/50-01-SUMMARY.md` - Records execution evidence for this plan.

## Decisions Made

- Kept the public maintainer command unprefixed and repaired CI instead of widening ExDoc into the test environment.
- Added a negative assertion for `MIX_ENV=test mix scoria.release_preview` so wording regressions fail at the source-test seam.

## Verification

- `rg -n "Run release preview lane|MIX_ENV=dev mix scoria.release_preview" .github/workflows/ci.yml` — PASS
- `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs --trace` — PASS (`8 tests, 0 failures`)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first doc rewrite accidentally embedded the rejected test-env release-preview command literally, which caused the focused adoption-surface test to fail. The wording was tightened to describe the unsupported job-wide test env without restating the rejected command.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 50 plan 02 can now rebuild Phase 47 verification evidence from a CI-safe release-preview lane.
- The broader `mix test.adoption` timeout issue remains outside this plan and should stay with Phase 51.

## Self-Check

PASSED

- Summary file exists on disk.
- Task commits `5c24c78` and `be552b0` are present in `git log --oneline --all`.
- No stub or placeholder patterns were found in the files created or modified by this plan.

---
*Phase: 50-release-preview-ci-truth-and-phase-47-verification*
*Completed: 2026-05-26*
