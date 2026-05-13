---
phase: 10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap
plan: 01
subsystem: infra
tags: [telemetry, sre, workflows, mcp, exunit]
requires:
  - phase: 07-seismograph
    provides: runtime budget and breaker seams consumed by live telemetry
provides:
  - Canonical runtime telemetry identity helpers with explicit label/ref separation
  - Workflow runtime telemetry emission on completed, timeout, and breaker-open outcomes
  - MCP executor telemetry emission on completed, access-denied, and breaker-open outcomes
affects: [sre, workflows, mcp, telemetry]
tech-stack:
  added: []
  patterns: [canonical telemetry identity, runtime namespace telemetry, execution-seam regression tests]
key-files:
  created: [.planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-01-SUMMARY.md]
  modified:
    - lib/scoria/sre/telemetry_identity.ex
    - lib/scoria/sre/telemetry.ex
    - lib/scoria/workflows/runtime.ex
    - lib/scoria/mcp/executor.ex
    - test/scoria/sre/telemetry_test.exs
    - test/scoria/workflows/runtime_telemetry_test.exs
    - test/scoria/mcp/executor_telemetry_test.exs
key-decisions:
  - "Live SRE execution telemetry now emits under [:scoria, :sre, :runtime, ...] while incident lifecycle remains separate."
  - "Workflow and MCP producers share TelemetryIdentity labels/refs and never group by run_id or trace_id."
  - "Budget telemetry for MCP completed executions unwraps {:ok, payload} results before computing actual usage."
patterns-established:
  - "Execution seams emit latency, reliability, breaker, and budget signals directly from real runtime outcomes."
  - "Telemetry helper tests assert identity contract shape independently from downstream adapter translation."
requirements-completed: [SRE-04]
duration: 5 min
completed: 2026-05-13
---

# Phase 10 Plan 01: Wire Production SRE Telemetry and Fix Default Verification Bootstrap Summary

**Canonical runtime telemetry now emits from workflow and MCP execution seams with shared identity keys, low-cardinality labels, and result-based budget signals.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-12T21:46:58-04:00
- **Completed:** 2026-05-13T01:52:05Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments
- Exposed `TelemetryIdentity.labels/1` and `refs/1`, then composed runtime and incident metadata from that canonical contract.
- Switched live SRE helper emission to the runtime namespace and wired workflow/MCP execution outcomes through the shared contract.
- Added focused regression coverage for completed, timeout, breaker-open, and access-denied execution paths, including budget and burn telemetry.

## Task Commits

1. **Task 1: Define the Canonical Runtime Telemetry Identity Contract**
- `fbe98c2` `test(10-01): add failing canonical telemetry identity spec`
- `6f2832c` `feat(10-01): expose canonical telemetry identity contract`

2. **Task 2: Emit Live Runtime and MCP Telemetry from Real Execution Outcomes**
- `186fd24` `test(10-01): add runtime and mcp telemetry seam specs`
- `e82e934` `feat(10-01): emit canonical runtime telemetry from execution seams`
- `d32b975` `test(10-01): align helper telemetry spec with runtime namespace`

## Files Created/Modified
- `lib/scoria/sre/telemetry_identity.ex` - publishes canonical telemetry labels/refs and shared metadata composition
- `lib/scoria/sre/telemetry.ex` - emits live SRE helper events under the runtime namespace
- `lib/scoria/workflows/runtime.ex` - sends workflow outcome telemetry with result-based budget usage
- `lib/scoria/mcp/executor.ex` - sends MCP outcome telemetry and unwraps successful payloads for actual usage
- `test/scoria/sre/telemetry_test.exs` - verifies runtime helper identity shape and runtime namespace events
- `test/scoria/workflows/runtime_telemetry_test.exs` - covers workflow completed, timeout, and breaker-open telemetry
- `test/scoria/mcp/executor_telemetry_test.exs` - covers MCP completed, access-denied, and breaker-open telemetry

## Decisions Made

- Runtime telemetry moved to `[:scoria, :sre, :runtime, ...]` so execution signals remain distinct from incident lifecycle telemetry.
- Canonical identity grouping remains on stable operational dimensions plus `identity_key`; `trace_id` and `run_id` stay in correlation refs only.
- Helper-level tests no longer depend on downstream Parapet translation to verify the runtime contract.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Unwrapped MCP success payloads for actual budget usage**
- **Found during:** Task 2
- **Issue:** MCP completed telemetry calculated `cost` and `budget_burn` from the estimated units because successful tool results arrived as `{:ok, payload}` tuples.
- **Fix:** Added tuple unwrapping in `Scoria.MCP.Executor.actual_units/3` so completed MCP telemetry reflects actual payload usage.
- **Files modified:** `lib/scoria/mcp/executor.ex`
- **Verification:** `MIX_ENV=test mix test test/scoria/workflows/runtime_telemetry_test.exs test/scoria/mcp/executor_telemetry_test.exs`
- **Committed in:** `e82e934`

**2. [Rule 3 - Blocking] Adjusted stale verify commands for the installed Mix version**
- **Found during:** Task 1 and Task 2 verification
- **Issue:** The plan’s `mix test ... -x` commands are not accepted by the current Mix task implementation.
- **Fix:** Ran the same focused test files without `-x`.
- **Files modified:** none
- **Verification:** `MIX_ENV=test mix test test/scoria/sre/telemetry_test.exs`; `MIX_ENV=test mix test test/scoria/workflows/runtime_telemetry_test.exs test/scoria/mcp/executor_telemetry_test.exs`
- **Committed in:** not applicable

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking)
**Impact on plan:** Both adjustments were required to verify the planned behavior without expanding scope.

## Issues Encountered

- Task 2 budget-path assertions initially failed before reaching telemetry emission because runtime and MCP reservations require active budget policies. The tests now seed the minimum policy rows they need.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Workflow and MCP live telemetry now share one canonical execution contract and are ready for downstream incident-lifecycle integration.
- Phase metadata files outside the owned set were intentionally not updated in this task.

## Self-Check: PASSED

---
*Phase: 10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap*
*Completed: 2026-05-13*
