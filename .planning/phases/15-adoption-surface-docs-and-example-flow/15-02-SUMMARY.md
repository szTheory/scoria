---
phase: 15-adoption-surface-docs-and-example-flow
plan: 02
subsystem: docs
tags: [phoenix, runtime, controller, session, approval]
requires:
  - phase: 15-adoption-surface-docs-and-example-flow
    provides: runtime-first README and stable public vocabulary
provides:
  - controller-triggered Phoenix integration guide aligned to public runtime semantics
affects: [adoption, docs, verification, phoenix-integration]
tech-stack:
  added: []
  patterns: [controller-first runtime start, exact run-id resume, session continuity]
key-files:
  created: [docs/phoenix_runtime_example.md]
  modified: []
key-decisions:
  - "Derived the guide directly from the runtime integration test instead of inventing a broader sample app."
  - "Kept `Scoria` as the normal entrypoint and treated `/scoria/workflows/:run_id` as operator evidence only."
patterns-established:
  - "Controller actions normalize edge state before `Scoria.start_run/2`."
  - "Docs repeat that later turns reuse `session_id` but create fresh `run_id` values."
requirements-completed: [ADOP-02]
duration: 12min
completed: 2026-05-15
---

# Phase 15-02 Summary

**A dedicated Phoenix guide now shows controller-triggered identity normalization, durable `run_id` storage, exact approval resume, and operator evidence routing through the public `Scoria` facade.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-05-15T21:42:00Z
- **Completed:** 2026-05-15T21:43:00Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Added a canonical Phoenix runtime guide at `docs/phoenix_runtime_example.md`.
- Documented the edge boundary from controller/session state into `Scoria.identity/1`.
- Showed the exact `run_id` persistence, same-session fresh-run model, approval resume, and `/scoria/workflows/:run_id` evidence route.

## Task Commits

No commits created in this execution. The repository already had unrelated in-progress changes, so the plan was executed as working-tree edits only.

## Files Created/Modified

- `docs/phoenix_runtime_example.md` - End-to-end controller-triggered adoption guide for the public runtime surface

## Decisions Made

- Used a controller action as the primary shape instead of LiveView-first or background-job-first examples.
- Kept `Scoria.Workflows` out of the normal teaching path to preserve the public facade boundary.

## Deviations from Plan

None.

## Issues Encountered

None.

## User Setup Required

None.

## Next Phase Readiness

The repo now has the public example needed for the final operator verification and installer-alignment pass in `15-03`.
