---
phase: 07-seismograph
plan: 03
subsystem: infra
tags: [fuse, telemetry, sre, parapet, workflows, mcp]
requires:
  - phase: 07-seismograph
    provides: "Budget preflight and reconciliation at runtime and MCP seams"
provides:
  - "Integration-scoped breaker registry for external-effect seams"
  - "Reason-coded SLI telemetry helpers with safe metadata labels"
  - "Parapet-friendly translation maps derived from telemetry envelopes"
affects: [sre, workflows, mcp, telemetry, incidents]
tech-stack:
  added: [fuse, telemetry]
  patterns: ["Explicit external-effect breaker contexts", "Telemetry-first Parapet translation"]
key-files:
  created:
    - lib/scoria/sre/breaker_registry.ex
    - lib/scoria/sre/telemetry.ex
    - lib/scoria/sre/adapters/parapet.ex
    - test/scoria/sre/telemetry_test.exs
  modified:
    - lib/scoria/workflows/runtime.ex
    - lib/scoria/mcp/executor.ex
    - test/scoria/workflows/runtime_test.exs
    - test/scoria/mcp/executor_test.exs
key-decisions:
  - "Breaker guards only activate when runtime or MCP context explicitly identifies an external integration."
  - "Parapet integration stays dependency-free by translating telemetry envelopes instead of coupling to DB structs."
patterns-established:
  - "Breaker keys are stable integration identifiers such as provider refs and remote MCP endpoints, never run-scoped IDs."
  - "SRE telemetry publishes low-cardinality labels separately from deep-link refs such as trace and run IDs."
requirements-completed: [SRE-03, SRE-04, SRE-08]
duration: 8 min
completed: 2026-05-11
---

# Phase 7 Plan 03: External breaker gating and telemetry-first SLI envelopes

**Fuse-backed external breaker guards for workflow and MCP seams, plus safe SLI telemetry and Parapet-friendly translation helpers**

## Performance

- **Duration:** 8 min
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments
- Added `Scoria.SRE.BreakerRegistry` and routed workflow runtime plus MCP execution through stable external-integration breaker keys only.
- Kept local workflow handlers and local tools unwrapped unless the execution context explicitly marks them as external.
- Added `Scoria.SRE.Telemetry` and `Scoria.SRE.Adapters.Parapet` to emit reason-coded SLI envelopes with version refs and safe labels.

## Task Commits

1. **Task 1: Wrap External Effects in Integration-Scoped Breakers** - `7f9447e` (`feat`)
2. **Task 2: Emit Reason-Coded SLI Telemetry and Parapet Helper Envelopes** - `4c22b85` (`feat`)

## Files Created/Modified
- `lib/scoria/sre/breaker_registry.ex` - Fuse-backed helper that resolves stable integration keys, blocks open circuits, and records breaker trips.
- `lib/scoria/workflows/runtime.ex` - Breaker-gates only explicit external workflow handlers while leaving local handlers unwrapped.
- `lib/scoria/mcp/executor.ex` - Distinguishes breaker-open failures from timeouts and crash paths at the MCP seam.
- `lib/scoria/sre/telemetry.ex` - Emits latency, cost, quality, tool reliability, budget burn, and breaker-state telemetry with safe metadata allowlists.
- `lib/scoria/sre/adapters/parapet.ex` - Translates telemetry events into dependency-free Parapet-facing maps with labels and refs split cleanly.
- `test/scoria/workflows/runtime_test.exs` - Covers external-only breaker trips and confirms local handlers stay unwrapped.
- `test/scoria/mcp/executor_test.exs` - Covers remote breaker-open behavior separately from timeout and local tool behavior.
- `test/scoria/sre/telemetry_test.exs` - Verifies incident keys, reason codes, and scorer/baseline refs survive telemetry emission and translation.

## Decisions Made
- Used explicit `breaker_context` / integration metadata to avoid over-wrapping local pure code paths.
- Kept telemetry metadata on a small allowlist so Parapet-facing consumers receive low-cardinality labels plus deep-link refs without raw payload leakage.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Supplemented Fuse with a short-lived open-state table**
- **Found during:** Task 1
- **Issue:** Fuse’s default melt semantics did not reliably block the very next call after the first qualifying external failure, which violated the plan’s fail-fast requirement.
- **Fix:** Added a tiny named ETS open-state table inside `Scoria.SRE.BreakerRegistry` so qualifying failures immediately short-circuit subsequent calls on the same stable integration key while still using Fuse for install/run behavior.
- **Files modified:** `lib/scoria/sre/breaker_registry.ex`, `test/scoria/workflows/runtime_test.exs`, `test/scoria/mcp/executor_test.exs`
- **Verification:** `mix test test/scoria/workflows/runtime_test.exs test/scoria/mcp/executor_test.exs`
- **Committed in:** `7f9447e`

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Required for correctness. Scope stayed inside the owned breaker slice.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Breaker and telemetry seams now expose stable reason-coded evidence for later alerting and incident slices.
- No blockers found in the owned workspace slice.

## Self-Check: PASSED
- Verified files exist: `lib/scoria/sre/breaker_registry.ex`, `lib/scoria/sre/telemetry.ex`, `lib/scoria/sre/adapters/parapet.ex`, `test/scoria/sre/telemetry_test.exs`
- Verified commits exist: `7f9447e`, `4c22b85`

---
*Phase: 07-seismograph*
*Completed: 2026-05-11*
