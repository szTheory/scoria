---
phase: 52-runtime-to-handoff-example-contract
plan: 01
subsystem: planning
tags: [runtime, handoff, docs, projected-context]

requires: []
provides:
  - Phase 52 runtime-to-handoff example shape decision
  - Public facade API boundary for downstream implementation plans
  - Baseline docs/source quick verification result
affects: [phase-52, runtime-to-handoff-example, bounded-handoffs]

tech-stack:
  added: []
  patterns:
    - Public Scoria facade first for adopter examples
    - Host-owned escalation policy with bounded projected context

key-files:
  created:
    - .planning/phases/52-runtime-to-handoff-example-contract/52-EXAMPLE-SHAPE.md
    - .planning/phases/52-runtime-to-handoff-example-contract/52-01-SUMMARY.md
  modified:
    - .planning/phases/52-runtime-to-handoff-example-contract/52-EXAMPLE-SHAPE.md

key-decisions:
  - "No new public runtime API is required for Phase 52."
  - "The Phase 52 example starts with Scoria.start_run/2, escalates through Scoria.start_handoff_run/3, and reads delegated detail through Scoria.get_run_detail/1."
  - "The host app owns escalation policy; Scoria owns durable execution, projected-context rejection, and curated readback."

patterns-established:
  - "Decision-record gate: downstream plans execute against 52-EXAMPLE-SHAPE.md before changing docs or implementation."
  - "Projected-context contract: accepted payloads are empty or narrow host-controlled maps; unsafe runtime-state keys are rejected."

requirements-completed: [EXMP-01, EXMP-02]

duration: 2m04s
completed: 2026-05-27
---

# Phase 52 Plan 01: Example Shape Decision Summary

**Runtime-to-handoff example contract using the existing Scoria public facade, with projected-context safety boundaries and a passing docs/source baseline.**

## Performance

- **Duration:** 2m04s
- **Started:** 2026-05-27T06:43:45Z
- **Completed:** 2026-05-27T06:45:49Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Created `52-EXAMPLE-SHAPE.md` as the executor-facing decision record for Phase 52.
- Captured the exact public API surface: `Scoria.identity/1`, `Scoria.start_run/2`, `Scoria.start_handoff_run/3`, and `Scoria.get_run_detail/1`.
- Recorded the host-owned escalation boundary, `session_id` versus `run_id` distinction, accepted projected-context shapes, rejected unsafe keys, and explicit exclusions.
- Ran and recorded the baseline docs/source quick verification before Phase 52 implementation.

## Task Commits

Each task was committed atomically:

1. **Task 1: Record the Phase 52 example shape decision** - `0bac502` (docs)
2. **Task 2: Verify the existing source-alignment lane still runs before implementation** - `373b315` (docs)

## Files Created/Modified

- `.planning/phases/52-runtime-to-handoff-example-contract/52-EXAMPLE-SHAPE.md` - Decision record for the smallest Phase 52 adopter-facing example shape.
- `.planning/phases/52-runtime-to-handoff-example-contract/52-01-SUMMARY.md` - Plan execution summary.

## Decisions Made

- No new public runtime API is required for Phase 52.
- Downstream Phase 52 work must start from the default run lane before any bounded handoff call.
- Host `session_id` is continuity; Scoria `run_id` is the durable execution handle.
- Projected context remains an explicit bounded payload with rejected unsafe runtime-state keys.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Verification

- `test -f .planning/phases/52-runtime-to-handoff-example-contract/52-EXAMPLE-SHAPE.md` - passed.
- Task 1 acceptance greps for `Scoria.start_run/2`, `Scoria.start_handoff_run/3`, `Scoria.get_run_detail(handoff_run.run_id)`, `No direct Scoria.Workflows calls`, and `No raw workflow table readback` - passed.
- Task 2 acceptance greps for `## Baseline Quick Verification` and the exact quick-lane command - passed.
- Plan-level command `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/handoff_example_source_test.exs` - passed, 9 tests, 0 failures.

## Known Stubs

None.

## Threat Flags

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 52-02 can implement the example against the recorded shape without adding public runtime API, a sample Phoenix app, semantic/knowledge prerequisites, pgvector setup, direct `Scoria.Workflows` calls, or raw workflow table readback.

---
*Phase: 52-runtime-to-handoff-example-contract*
*Completed: 2026-05-27*

## Self-Check: PASSED

- Found `.planning/phases/52-runtime-to-handoff-example-contract/52-EXAMPLE-SHAPE.md`.
- Found `.planning/phases/52-runtime-to-handoff-example-contract/52-01-SUMMARY.md`.
- Found task commit `0bac502`.
- Found task commit `373b315`.
