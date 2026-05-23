---
phase: 38-replay-safe-execution-tool-modes
plan: 2
subsystem: runtime
tags: [replay, approvals, mcp, connectors, auditing, workflows]
requires:
  - phase: 38-replay-safe-execution-tool-modes
    provides: replay-safe schema columns and replay disposition resolver contract
provides:
  - replay-scoped approval truth and immutable replay allowlists
  - replay gating at workflow runtime, connector invocation, and MCP execution seams
  - seam-level regression coverage for blocked, stubbed, and replay-live deduped paths
affects: [replay, approvals, workflows, mcp, connectors, operator-evidence]
tech-stack:
  added: []
  patterns: [fail-closed replay gating, replay-scoped audit dedupe, immutable replay overrides]
key-files:
  created:
    - lib/scoria/connectors/invocation.ex
    - lib/scoria/workflows/event_compactor.ex
    - lib/scoria_web/views/error_view.ex
    - priv/repo/migrations/20260523000200_repair_replay_safe_execution_truth.exs
    - test/scoria/connectors/invocation_test.exs
  modified:
    - lib/scoria/workflows.ex
    - lib/scoria/workflows/run.ex
    - lib/scoria/workflows/runtime.ex
    - lib/scoria/mcp/executor.ex
    - lib/scoria/sre.ex
    - test/scoria/workflows_test.exs
    - test/scoria/workflows/integration_test.exs
key-decisions:
  - "Added a repair migration because the replay-safe columns from 38-01 were absent in the actual database despite the earlier migration revision existing."
  - "Implemented replay gating in the real seams available in this worktree: workflow runtime, a new connector invocation boundary, and MCP execution."
  - "Handled replay-live audit dedupe by reusing an existing audit row on unique dedupe-key collisions."
patterns-established:
  - "Replay branches treat historical approvals as evidence only until a replay-scoped approval row is granted."
  - "Replay seam enforcement runs before live tool execution and returns typed blocked or historical-stub envelopes instead of falling through."
requirements-completed: [RPLY-02]
duration: 14 min
completed: 2026-05-23
---

# Phase 38 Plan 2: Replay-Safe Execution Tool Modes Summary

**Replay-scoped approvals, fail-closed connector/MCP gating, and retry-stable replay-live audit dedupe across workflow seams**

## Performance

- **Duration:** 14 min
- **Started:** 2026-05-23T09:33:00Z
- **Completed:** 2026-05-23T09:47:38Z
- **Tasks:** 3
- **Files modified:** 12

## Accomplishments
- Persisted replay-scoped approval evidence on workflow approvals, checkpoints, events, and audit rows while keeping replay allowlists immutable after replay start.
- Added replay gating before live execution in workflow runtime, a connector invocation seam, and the MCP executor, including historical stubs, blocked envelopes, and replay-live idempotency keys.
- Expanded regression coverage so replay branches prove blocked authority-expanding seams, exact-match stubbing, immutable allowlists, historical-approval non-authority, and deduped replay-live audit writes.

## Task Commits

1. **Task 1: Rework approval transitions around replay-scoped authority** - `e242c05` (feat)
2. **Task 2: Enforce replay disposition before connector and MCP live execution** - `2f8d805` (feat)
3. **Task 3: Expand seam tests for blocked, stubbed, and replay-live dedupe cases** - `72a62ae` (test)

## Files Created/Modified
- `lib/scoria/workflows.ex` - replay-scoped approval persistence and replay evidence fanout
- `lib/scoria/workflows/run.ex` - immutable replay `live_tool_allowlist` validation
- `lib/scoria/workflows/runtime.ex` - replay seam gating before handler execution
- `lib/scoria/connectors/invocation.ex` - replay-aware connector execution seam
- `lib/scoria/mcp/executor.ex` - replay gating and replay-live audit dedupe context
- `lib/scoria/sre.ex` - replay audit normalization and dedupe-row reuse
- `test/scoria/connectors/invocation_test.exs` - seam-level replay execution regressions
- `test/scoria/workflows_test.exs` - replay approval authority and resume protections
- `test/scoria/workflows/integration_test.exs` - replay runtime stub/block integration coverage

## Decisions Made

- Used a new `Scoria.Connectors.Invocation` boundary because the plan referenced a connector invocation file that does not exist in this repo.
- Reused the existing `ReplayDisposition` contract directly in runtime and MCP seams instead of inventing a second replay policy layer.
- Reused existing audit rows on dedupe-key collisions to make replay-live retries idempotent without duplicating tool-invocation audit writes.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Invalid required base hash was not present locally**
- **Found during:** executor startup
- **Issue:** The mandated full base hash `cc1739626b2f735dcddfe75e3a64d2a1a18ec730` was not a valid local object, although `HEAD` was already at `cc17396…`.
- **Fix:** Continued from the existing `HEAD` commit that matched the visible short prefix and recorded the deviation instead of resetting to a nonexistent object.
- **Files modified:** none
- **Verification:** `git rev-parse HEAD` returned `cc1739601483759d31513d662b9c399e9315f55f`
- **Committed in:** none

**2. [Rule 3 - Blocking] Workflow event insertion crashed because `EventCompactor` was missing**
- **Found during:** Task 1 verification
- **Issue:** `Scoria.Workflows.EventCompactor.maybe_enqueue_compaction/2` was referenced but the module did not exist, so basic workflow tests failed before replay changes could run.
- **Fix:** Added a no-op `Scoria.Workflows.EventCompactor` stub to unblock the workflow persistence lane.
- **Files modified:** `lib/scoria/workflows/event_compactor.ex`
- **Verification:** `mix test test/scoria/workflows_test.exs test/scoria/workflows/integration_test.exs`
- **Committed in:** `e242c05`

**3. [Rule 3 - Blocking] Replay-safe schema drift left required columns missing in the actual database**
- **Found during:** Task 1 verification
- **Issue:** `ai_approvals`, `ai_workflow_checkpoints`, `ai_workflow_events`, and `ai_audit_outbox_events` were missing the replay-safe columns even though the prior migration revision existed.
- **Fix:** Added an idempotent repair migration to install the missing columns and indexes on top of the live schema.
- **Files modified:** `priv/repo/migrations/20260523000200_repair_replay_safe_execution_truth.exs`
- **Verification:** `MIX_ENV=test mix ecto.migrate`
- **Committed in:** `e242c05`

**4. [Rule 3 - Blocking] Integration lane depended on missing UI/SRE stubs**
- **Found during:** Task 1 verification
- **Issue:** workflow LiveView tests expected `Scoria.ErrorView` and `Scoria.SRE.remote_invocation_evidence/1`, neither of which existed.
- **Fix:** Added minimal implementations so replay verification could exercise the durable workflow lane.
- **Files modified:** `lib/scoria_web/views/error_view.ex`, `lib/scoria/sre.ex`
- **Verification:** `mix test test/scoria/workflows_test.exs test/scoria/workflows/integration_test.exs`
- **Committed in:** `e242c05`

---

**Total deviations:** 4 auto-fixed (4 blocking)
**Impact on plan:** All deviations were required to make the planned replay seams executable in this worktree. No orchestrator-owned planning artifacts were changed.

## Issues Encountered

- The plan’s connector invocation path was stale relative to the repo, so the connector replay seam had to be implemented as a new module rather than patched in place.
- Replay-live audit dedupe initially surfaced unique-key collisions; this was resolved by reusing the existing audit row when a matching dedupe key already existed.

## Known Stubs

- `lib/scoria/workflows/event_compactor.ex:4` - `maybe_enqueue_compaction/2` is a no-op blocker fix, not a real compaction scheduler.
- `lib/scoria/sre.ex:147` - `remote_invocation_evidence/1` currently returns an empty approval projection stub to satisfy the workflow LiveView integration lane.
- `lib/scoria_web/views/error_view.ex:2` - minimal string-only error rendering exists solely to unblock LiveView error handling in tests.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Replay approval truth, connector gating, runtime seam gating, and replay-live audit dedupe are in place for downstream replay UX or provenance work.
- Remaining repo warnings are pre-existing and outside this plan’s scope.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/38-replay-safe-execution-tool-modes/38-02-SUMMARY.md`
- Task commits exist: `e242c05`, `2f8d805`, `72a62ae`
