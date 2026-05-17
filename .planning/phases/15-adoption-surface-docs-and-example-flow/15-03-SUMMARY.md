---
phase: 15-adoption-surface-docs-and-example-flow
plan: 03
subsystem: docs
tags: [verification, installer, operator, phoenix, knowledge-lane]
requires:
  - phase: 15-adoption-surface-docs-and-example-flow
    provides: runtime-first README and Phoenix example guide
provides:
  - default Phoenix verification guide for core runtime proof
  - installer next-step copy aligned to the same default lane
affects: [adoption, onboarding, operator-verification, installer]
tech-stack:
  added: []
  patterns: [boring core lane first, optional knowledge lane second]
key-files:
  created: [docs/operator_verification.md]
  modified: [README.md, lib/mix/tasks/scoria.install.ex]
key-decisions:
  - "Kept the first-run proof centered on install, one real run, readback, and operator evidence."
  - "Positioned `mix scoria.test.knowledge` strictly as an optional expansion after the default lane."
patterns-established:
  - "README and installer copy point to the same operator verification story."
  - "Core success never implies pgvector or knowledge tables."
requirements-completed: [ADOP-03]
duration: 14min
completed: 2026-05-15
---

# Phase 15-03 Summary

**Adoption docs and installer output now share one default Phoenix verification lane: install, migrate, test, run once, read back by `run_id`, and inspect operator evidence before any optional knowledge work.**

## Performance

- **Duration:** 14 min
- **Started:** 2026-05-15T21:43:00Z
- **Completed:** 2026-05-15T21:44:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added `docs/operator_verification.md` with a concrete core-lane proof path for adopters.
- Tightened the README verification section so it points at the operator guide and makes the readback requirement explicit.
- Updated installer next-step copy to keep the default Phoenix lane first and the knowledge lane optional.

## Task Commits

No commits created in this execution. The repository already had unrelated in-progress changes, so the plan was executed as working-tree edits only.

## Files Created/Modified

- `docs/operator_verification.md` - Core verification walkthrough with optional knowledge expansion
- `README.md` - Verification summary aligned to the deeper operator guide
- `lib/mix/tasks/scoria.install.ex` - Installer next-step copy aligned to the same verification story

## Decisions Made

- Used one real runtime run plus `/scoria/workflows/:run_id` as the user-facing proof instead of relying on tests alone.
- Preserved `mix test` and `mix scoria.test.knowledge` as maintainer closeout lanes while keeping the latter explicitly non-default.

## Deviations from Plan

None.

## Issues Encountered

None.

## User Setup Required

None.

## Next Phase Readiness

Phase 15 now has README, example, and verification coverage aligned to the shipped public runtime surface. Remaining milestone bookkeeping outside this phase still includes the separate roadmap/state reconciliation for Phases 12 and 13.
