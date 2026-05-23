---
phase: 38-replay-safe-execution-tool-modes
plan: 3
subsystem: api
tags: [elixir, ecto, replay, approvals, runtime, dto]
requires:
  - phase: 38-02
    provides: replay-safe seam truth on runs, approvals, checkpoints, and events
provides:
  - replay posture fields on runtime summary/detail DTOs
  - seam-level replay evidence on runtime detail projections
  - operator-facing approval inbox and lineage projections with replay provenance
affects: [phase-39-ui, runtime-detail, operator-approval-inbox, replay-evidence]
tech-stack:
  added: []
  patterns: [projection-first DTO mapping, replay provenance surfaced at read boundaries]
key-files:
  created: [lib/scoria/workflows/remote_approval_projection.ex, test/scoria/workflows/remote_approval_projection_test.exs]
  modified: [lib/scoria/runtime/run_summary.ex, lib/scoria/runtime/run_detail.ex, test/scoria/runtime_view_test.exs]
key-decisions:
  - "Kept run summary execution_mode as run intent only while adding separate replay posture fields."
  - "Projected replay provenance directly from durable approval rows instead of UI-side boolean inference."
patterns-established:
  - "Runtime DTOs expose replay posture and seam evidence through curated maps rather than raw workflow structs."
  - "Operator approval reads consume a dedicated projection module that preserves replay_allowed as compatibility only."
requirements-completed: [RPLY-02]
duration: 8min
completed: 2026-05-23
---

# Phase 38 Plan 3: Replay-Safe Execution Tool Modes Summary

**Replay posture now projects through runtime DTOs and operator approval reads with seam-level provenance intact**

## Performance

- **Duration:** 8 min
- **Started:** 2026-05-23T09:47:00Z
- **Completed:** 2026-05-23T09:55:31Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Extended `Scoria.Runtime.RunSummary` and `RunDetail` so replay intent, allowlist posture, and seam-level replay evidence are visible through public runtime reads.
- Added `Scoria.Workflows.RemoteApprovalProjection` for operator inbox and lineage reads that surface `replay_disposition`, `replay_scope`, source lineage IDs, and `executed_live`.
- Locked the replay-safe read contract with targeted runtime and approval projection regressions plus the existing integration lane.

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend runtime DTOs with replay posture and seam evidence** - `b03babe` (test), `a6e1aa4` (feat)
2. **Task 2: Extend approval projections and add projection regressions for replay-safe evidence** - `32f12f3` (feat)

_Note: Task 1 used the required TDD red/green flow._

## Files Created/Modified

- `lib/scoria/runtime/run_summary.ex` - Adds replay intent, replay posture, allowlist, and executed-live summary fields.
- `lib/scoria/runtime/run_detail.ex` - Projects checkpoint, event, and approval replay evidence into curated runtime detail items.
- `test/scoria/runtime_view_test.exs` - Verifies runtime summary/detail replay projections through public APIs.
- `lib/scoria/workflows/remote_approval_projection.ex` - Adds operator-facing pending approval and approval lineage projections.
- `test/scoria/workflows/remote_approval_projection_test.exs` - Verifies replay provenance is available directly at the approval projection boundary.

## Decisions Made

- Kept `summary.execution_mode` as `live | replay` and introduced `replay_posture` instead of reintroducing a fake run-wide seam outcome.
- Computed `any_seam_executed_live` only from loaded durable events and approvals so plain summary reads stay safe when associations are not preloaded.
- Exposed replay approval provenance from the projection module directly, keeping `replay_allowed` for compatibility while making `replay_scope` and `replay_disposition` authoritative.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Hardened new runtime projection helpers against unloaded associations and unsafe key conversion**
- **Found during:** Task 1 (Extend runtime DTOs with replay posture and seam evidence)
- **Issue:** Initial DTO helpers could crash on unloaded Ecto associations and used unsafe atom conversion while curating replay evidence.
- **Fix:** Added explicit unloaded-association guards in `RunSummary` and switched detail map lookups to `String.to_existing_atom/1` fallback logic.
- **Files modified:** `lib/scoria/runtime/run_summary.ex`, `lib/scoria/runtime/run_detail.ex`
- **Verification:** `mix test test/scoria/runtime_view_test.exs`
- **Committed in:** `a6e1aa4`

**2. [Rule 3 - Blocking] Created the missing approval projection module and regression file referenced by the plan**
- **Found during:** Task 2 (Extend approval projections and add projection regressions for replay-safe evidence)
- **Issue:** `lib/scoria/workflows/remote_approval_projection.ex` and its test file did not exist in the worktree, but `Scoria.Workflows` already depended on that projection boundary.
- **Fix:** Implemented the missing projection module and added replay-safe inbox/lineage regression coverage.
- **Files modified:** `lib/scoria/workflows/remote_approval_projection.ex`, `test/scoria/workflows/remote_approval_projection_test.exs`
- **Verification:** `mix test test/scoria/workflows/remote_approval_projection_test.exs test/scoria/workflows/integration_test.exs`
- **Committed in:** `32f12f3`

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking)
**Impact on plan:** Both auto-fixes were required to complete the planned read surfaces correctly. No scope creep.

## Issues Encountered

- The worktree base check referenced full commit `0f55a9f8572f03b44e9f9f7b2cd4791e99d4ca08`, but the local worktree already sat on `HEAD` `0f55a9fa18099f134254ba590fcca298261bff1e`. Execution proceeded without reset after confirming the repository state matched the intended short base prefix.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 39 can render replay posture, allowlist state, executed-live facts, and approval provenance directly from runtime and approval DTO reads.
- No shared orchestrator artifacts were modified in this worktree.

## Self-Check: PASSED

- Found `.planning/phases/38-replay-safe-execution-tool-modes/38-03-SUMMARY.md`
- Found commits `b03babe`, `a6e1aa4`, and `32f12f3` in git history

---
*Phase: 38-replay-safe-execution-tool-modes*
*Completed: 2026-05-23*
