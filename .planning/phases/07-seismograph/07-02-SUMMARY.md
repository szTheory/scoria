---
phase: 07-seismograph
plan: 02
subsystem: sre
tags: [budgeting, hammer, workflows, mcp, runtime]
requires:
  - phase: 07-06
    provides: durable budget policies, reservations, and breaker persistence helpers
provides:
  - runtime budget reservation and loop-guard enforcement before external execution
  - mcp reservation reconciliation for success timeout and crash paths
  - budget engine policy lookup, short-window checks, and durable reserve/reconcile helpers
affects: [workflows, mcp, sre, operator-evidence]
tech-stack:
  added: []
  patterns: [reserve-before-effect, durable reservation reconciliation, seam-level loop guards]
key-files:
  created:
    - lib/scoria/sre/budget_engine.ex
    - test/scoria/sre/budget_engine_test.exs
    - .planning/phases/07-seismograph/07-02-SUMMARY.md
  modified:
    - lib/scoria/workflows/runtime.ex
    - lib/scoria/mcp/executor.ex
    - test/scoria/workflows/runtime_test.exs
    - test/scoria/mcp/executor_test.exs
    - lib/scoria/sre.ex
key-decisions:
  - "Budget windows accumulate per tenant/resource/policy/actor so warn and trip thresholds reflect real short-window spend, not per-run isolation."
  - "Runtime and MCP preserve their existing success and failure contracts while reconciling durable reservations in the background path."
patterns-established:
  - "Reserve before task launch, then reconcile the same reservation row after completion timeout or crash."
  - "Attach reservation identifiers to result or telemetry metadata so later operator tooling can trace execution back to durable evidence."
requirements-completed: [SRE-01, SRE-02, SRE-08]
duration: 9m
completed: 2026-05-11
---

# Phase 7 Plan 02: Budget Enforcement Summary

**Budget reservations and loop guards now block risky workflow and MCP execution before side effects, with durable reconciliation evidence on every outcome path.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-05-11T18:32:00Z
- **Completed:** 2026-05-11T18:41:18Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- Added `Scoria.SRE.BudgetEngine` with policy lookup, Hammer-backed short-window checks, warn/trip thresholds, and explicit loop guards.
- Enforced runtime preflight before `Task.Supervisor.async_nolink/2`, failing budget-tripped steps before handler side effects run.
- Enforced MCP reservation and reconciliation across normal completion, timeout, and crash paths while preserving existing return contracts.

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement the Budget Engine** - `5f2987c` (test), `ae7fd63` (feat)
2. **Task 2: Enforce Runtime and MCP Preflight Budgets** - `b6427e8` (test), `6ba1d5f` (feat)

## Files Created/Modified
- `lib/scoria/sre/budget_engine.ex` - Budget policy loading, Hammer windows, loop guards, reservation persistence, and reconciliation helpers.
- `lib/scoria/workflows/runtime.ex` - Runtime preflight, fail-fast budget envelopes, and reconciliation hooks around step execution.
- `lib/scoria/mcp/executor.ex` - MCP reservation, telemetry metadata enrichment, and reconciliation on completion/timeout/crash.
- `test/scoria/sre/budget_engine_test.exs` - Budget engine coverage for warn/trip thresholds and loop guards.
- `test/scoria/workflows/runtime_test.exs` - Runtime guard coverage proving blocked steps do not execute side effects.
- `test/scoria/mcp/executor_test.exs` - MCP timeout/crash reconciliation coverage against durable reservation rows.
- `lib/scoria/sre.ex` - Narrow nil-snapshot fix required for reservation persistence.

## Decisions Made

- Kept budget enforcement optional and context-driven at the execution seams so existing unbudgeted tests and call sites continue to work.
- Reconciled timeout and crash outcomes with zero actual usage instead of releasing the reservation, preserving durable evidence for later operator review.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed nil policy snapshot handling in `Scoria.SRE`**
- **Found during:** Task 1 (Implement the Budget Engine)
- **Issue:** `Scoria.SRE.reserve_usage/1` crashed when no explicit `policy_snapshot` was passed, which blocked all budget reservation writes.
- **Fix:** Normalized nil snapshots to `%{}` before building the persisted policy snapshot.
- **Files modified:** `lib/scoria/sre.ex`
- **Verification:** `MIX_ENV=test mix test test/scoria/sre/budget_engine_test.exs`
- **Committed in:** `ae7fd63`

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Necessary for correctness. No scope expansion beyond the live reservation path.

## Issues Encountered

- Hammer’s ETS-backed limiter required process lifecycle handling inside `BudgetEngine` because the limiter is not globally pre-supervised in this slice.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Runtime and MCP now emit durable reservation evidence that later incidenting and operator UX slices can consume.
- No blocker remains for breaker, alerting, or evidence-surface follow-up work in Phase 7.
