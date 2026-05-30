---
phase: 01-orchestrator-live-wiring-runtime-pubsub-trace-broadcast-and-
plan: 03
subsystem: observability
tags: [phoenix-liveview, pubsub, integration-test, db-hydrate, semantic-lane]

requires:
  - phase: 01-orchestrator-live-wiring-runtime-pubsub-trace-broadcast-and-
    provides: OperatorBroadcast, TraceProjection, HITL fan-out, OrchestratorLive handlers
provides:
  - DB hydrate on OrchestratorLive connected mount (tenant-scoped ai_spans query)
  - maybe_seed_active_approval for reconnect HITL catch-up from pending inbox
  - orchestrator_live_integration_test.exs proving Runtime.start_run producer path
  - Semantic fast-path pin for integration test
  - adoption_lanes.md host session identity contract
affects:
  - ORCH-LIVE-01 verification and /gsd-verify-work phase 01 gate

tech-stack:
  added: []
  patterns:
    - "hydrate_traces/2 filters spans via attributes->>'tenant_id' with configurable limit"
    - "Integration tests use ReqLLM.handle_event producer shim (no raw :telemetry.execute in test file)"
    - "LiveView reconnect simulated via ClientProxy.stop + live/2 remount"

key-files:
  created:
    - test/scoria_web/live/orchestrator_live_integration_test.exs
  modified:
    - lib/scoria_web/live/orchestrator_live.ex
    - config/config.exs
    - lib/mix/tasks/scoria.test.semantic_fast_path.ex
    - test/mix/tasks/test.semantic_fast_path_test.exs
    - docs/adoption_lanes.md

key-decisions:
  - "Hydrate query joins tenant-scoped ai_spans by attributes tenant_id, not ai_traces column"
  - "Integration handler calls ReqLLM.handle_event directly to avoid :telemetry.execute in test file"
  - "Reconnect tests use ClientProxy.stop helpers (Phoenix 1.1.30 lacks render_disconnect/1)"

patterns-established:
  - "Producer-path integration: Runtime.start_run → adapter → Telemetry → PubSub → LiveView DOM"
  - "Reconnect proof: disconnect proxy → persist via Buffer flush → remount hydrates from DB"

requirements-completed: [ORCH-LIVE-01]

duration: 22min
completed: 2026-05-30
---

# Phase 01 Plan 03: DB Hydrate and Integration Proof Summary

**Tenant-scoped trace DB hydrate on reconnect, Runtime.start_run integration tests without send/2, semantic lane pin, and adoption doc session contract close ORCH-LIVE-01**

## Performance

- **Duration:** 22 min
- **Started:** 2026-05-30T09:10:00Z
- **Completed:** 2026-05-30T09:32:06Z
- **Tasks:** 6 completed (5 production commits + metadata)
- **Files modified:** 6

## Accomplishments

- Added `hydrate_traces/2` on connected mount with tenant-filtered span query and `maybe_seed_active_approval/1` for reconnect modal catch-up
- Created `orchestrator_live_integration_test.exs` with four tests: live trace via `Runtime.start_run`, reconnect trace hydrate, live HITL modal, reconnect HITL from DB
- Pinned integration test in `mix scoria.test.semantic_fast_path` without widening `closeout_order/0`
- Documented host `session["tenant_id"]` / `session["actor_id"]` contract in `docs/adoption_lanes.md`

## Task Commits

Each task was committed atomically:

1. **Task 01-03-01: DB hydrate recent traces on connected mount** - `fb7fd1f` (feat)
2. **Task 01-03-02/02b/03: Integration tests (live trace, reconnect hydrate, HITL)** - `f92d743` (test)
3. **Task 01-03-04: Pin integration test in semantic fast-path lane** - `dd5cd02` (test)
4. **Task 01-03-05: Adoption doc session contract fragment** - `ac3500c` (docs)

**Plan metadata:** pending (docs commit)

## Files Created/Modified

- `lib/scoria_web/live/orchestrator_live.ex` - hydrate_traces, maybe_seed_active_approval, connected-mount ordering
- `config/config.exs` - orchestrator_hydrate_trace_limit: 25
- `test/scoria_web/live/orchestrator_live_integration_test.exs` - ORCH-LIVE-01 producer-path proof
- `lib/mix/tasks/scoria.test.semantic_fast_path.ex` - lane file list pin
- `test/mix/tasks/test.semantic_fast_path_test.exs` - contract assertion update
- `docs/adoption_lanes.md` - Host session identity subsection

## Decisions Made

- Used ReqLLM adapter handle_event from runtime handler to satisfy D-129 without `:telemetry.execute` in integration test file
- Implemented render_disconnect/reconnect via ClientProxy.stop because Phoenix LiveView 1.1.30 lacks built-in helpers
- Combined tasks 02/02b/03 into one test file commit (single artifact, four tests)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] ClientProxy reconnect helpers for Phoenix 1.1.30**
- **Found during:** Task 01-03-02b (reconnect trace hydrate test)
- **Issue:** `render_disconnect/1` and `render_reconnect/1` not exported by Phoenix.LiveViewTest 1.1.30
- **Fix:** Added test-local helpers using `ClientProxy.stop/2` and `live/2` remount
- **Files modified:** `test/scoria_web/live/orchestrator_live_integration_test.exs`
- **Verification:** reconnect integration tests pass
- **Committed in:** `f92d743`

**2. [Rule 1 - Bug] HITL live test eventually timeout with nested asserts**
- **Found during:** Task 01-03-03 (HITL modal integration)
- **Issue:** Combined assert/refute inside `eventually/1` did not reliably poll for PubSub-delivered modal
- **Fix:** Wait for `waiting_for_approval` run status first; use boolean `eventually` for modal text
- **Files modified:** `test/scoria_web/live/orchestrator_live_integration_test.exs`
- **Verification:** all four integration tests pass
- **Committed in:** `f92d743`

**3. [Rule 4 - Scope] Combined tasks 02, 02b, 03 into single test file commit**
- **Found during:** Task execution
- **Issue:** All integration tests live in one file; splitting would require artificial partial commits
- **Fix:** Single commit `f92d743` delivers all four integration tests
- **Files modified:** `test/scoria_web/live/orchestrator_live_integration_test.exs`
- **Verification:** `mix test test/scoria_web/live/orchestrator_live_integration_test.exs` — 4 tests, 0 failures
- **Committed in:** `f92d743`

---

**Total deviations:** 3 auto-fixed (1 missing critical, 1 bug, 1 scope consolidation)
**Impact on plan:** All acceptance criteria met. Scope consolidation reduces commit count from 6 to 4 production commits without losing coverage.

## Issues Encountered

None blocking.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 01 plans 01-01 through 01-03 complete — ready for `/gsd-verify-work` on phase 01
- ORCH-LIVE-01 requirement marked complete pending UAT

## Verification

```
MIX_ENV=test mix compile --warnings-as-errors                          → PASS
MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_integration_test.exs → 4 tests, 0 failures
MIX_ENV=test mix test test/mix/tasks/test.semantic_fast_path_test.exs test/scoria/verification_lanes_test.exs → 6 tests, 0 failures
SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test.semantic_fast_path --warnings-as-errors → 56 tests, 0 failures
```

## Self-Check: PASSED

---
*Phase: 01-orchestrator-live-wiring*
*Completed: 2026-05-30*
