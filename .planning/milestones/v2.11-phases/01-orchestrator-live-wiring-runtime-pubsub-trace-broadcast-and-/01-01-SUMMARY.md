---
phase: 01-orchestrator-live-wiring-runtime-pubsub-trace-broadcast-and-
plan: 01
subsystem: observability
tags: [pubsub, telemetry, elixir, phoenix, trace-projection]

requires: []
provides:
  - Scoria.Observe.TraceProjection for UI-safe span maps and depth decoration
  - Scoria.Observe.OperatorBroadcast tenant fan-out on scoria:runs:{tenant_id}
  - Telemetry redact → broadcast → buffer hook with span delta attach
  - ReqLLM and Jido adapter metadata enrichment (tenant_id, parent_id, workflow_run_id)
affects:
  - 01-02 HITL tenant fan-out and OrchestratorLive handler updates
  - 01-03 DB hydrate and integration tests

tech-stack:
  added: []
  patterns:
    - "Redact → broadcast → buffer ordering in Observe.Telemetry"
    - "Fail-closed tenant_id guard in OperatorBroadcast"
    - "ETS per-node trace_id dedup for trace_opened emission"

key-files:
  created:
    - lib/scoria/observe/trace_projection.ex
    - lib/scoria/observe/operator_broadcast.ex
    - test/scoria/observe/trace_projection_test.exs
    - test/scoria/observe/operator_broadcast_test.exs
  modified:
    - lib/scoria/observe/telemetry.ex
    - lib/scoria/observe/adapters/req_llm.ex
    - lib/scoria/observe/adapters/jido.ex
    - test/scoria/observe/telemetry_test.exs

key-decisions:
  - "ETS insert_new per trace_id tracks first-span-on-node for trace_opened (not module attribute)"
  - "Telemetry strips broadcast-only top-level keys before Buffer.cast_span/1 to preserve Span schema insert_all"

patterns-established:
  - "OperatorBroadcast is sole Observe-layer tenant PubSub fan-out module"
  - "TraceProjection never exposes raw attributes — attributes_preview capped at 10 keys / 512 chars"

requirements-completed: [ORCH-LIVE-01]

duration: 10min
completed: 2026-05-30
---

# Phase 01 Plan 01: Observe-Layer Tenant PubSub Bridge Summary

**Tenant-scoped trace delta fan-out from telemetry via OperatorBroadcast and TraceProjection, with redact-before-broadcast hook and adapter metadata enrichment**

## Performance

- **Duration:** 10 min
- **Started:** 2026-05-30T09:09:00Z
- **Completed:** 2026-05-30T09:19:10Z
- **Tasks:** 4 completed
- **Files modified:** 8

## Accomplishments

- Created `Scoria.Observe.TraceProjection` with `span_view/1`, `trace_header/1`, `with_depths/1`, and capped `attributes_preview`
- Created `Scoria.Observe.OperatorBroadcast` as sole tenant fan-out to `scoria:runs:{tenant_id}` with fail-closed tenant_id guard
- Wired telemetry hook: redact → `OperatorBroadcast.span_stopped/1` → `Buffer.cast_span/1`; attached `[:scoria, :observe, :span, :delta]`
- Enriched ReqLLM and Jido adapters with `tenant_id`, `parent_id`, `workflow_run_id`, `session_id` on span stop

## Task Commits

Each task was committed atomically:

1. **Task 01-01-01: Create Scoria.Observe.TraceProjection** - `583be0f` (feat)
2. **Task 01-01-02: Create Scoria.Observe.OperatorBroadcast** - `ea6e8ae` (feat)
3. **Task 01-01-03: Wire Telemetry broadcast hook and delta attach** - `9793643` (feat)
4. **Task 01-01-04: Enrich adapter span metadata contract** - `a71798d` (feat)

**Plan metadata:** pending (docs commit)

## Files Created/Modified

- `lib/scoria/observe/trace_projection.ex` - UI-safe span/trace projection with depth decoration
- `lib/scoria/observe/operator_broadcast.ex` - Tenant PubSub fan-out for trace_opened/trace_span/trace_delta
- `lib/scoria/observe/telemetry.ex` - Broadcast hook before buffer; delta handler attached
- `lib/scoria/observe/adapters/req_llm.ex` - Span stop metadata enriched with tenant context
- `lib/scoria/observe/adapters/jido.ex` - Span stop metadata enriched with tenant context
- `test/scoria/observe/trace_projection_test.exs` - Projection redaction, cap, depth tests
- `test/scoria/observe/operator_broadcast_test.exs` - Tenant drop, message shape, dedup tests
- `test/scoria/observe/telemetry_test.exs` - Immediate broadcast + buffer durability tests

## Decisions Made

- Used ETS `:scoria_observe_operator_broadcast_trace_seen` with `insert_new/2` for per-node `trace_opened` dedup
- Added `buffer_span/1` in Telemetry to strip broadcast-only top-level keys before Buffer cast (prevents insert_all failure when adapters add tenant_id)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Strip broadcast-only fields before Buffer.cast_span/1**
- **Found during:** Task 01-01-03 (Telemetry broadcast hook)
- **Issue:** Top-level `tenant_id` in span metadata caused Buffer `insert_all` ArgumentError on unknown field
- **Fix:** Added `buffer_span/1` in Telemetry to pass only Span schema fields to Buffer while full redacted map goes to OperatorBroadcast
- **Files modified:** `lib/scoria/observe/telemetry.ex`
- **Verification:** `MIX_ENV=test mix test test/scoria/observe/telemetry_test.exs` passes
- **Committed in:** `9793643`

---

**Total deviations:** 1 auto-fixed (1 missing critical)
**Impact on plan:** Required for adapter metadata enrichment (Task 04) to work without breaking buffer durability path. No scope creep.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 01-02 ready: HITL tenant fan-out via `OperatorBroadcast.hitl_request/2` and `approval_decided/3` stubs can be replaced
- OrchestratorLive handlers for `{:trace_opened, _}`, `{:trace_span, _, _}`, `{:trace_delta, _}` still needed in 01-02
- DB hydrate on mount deferred to 01-03

## Verification

```
MIX_ENV=test mix compile --warnings-as-errors          → PASS
MIX_ENV=test mix test test/scoria/observe/operator_broadcast_test.exs \
  test/scoria/observe/trace_projection_test.exs \
  test/scoria/observe/telemetry_test.exs               → 12 tests, 0 failures
MIX_ENV=test mix test test/scoria/verification_lanes_test.exs → 5 tests, 0 failures
(closeout_order/0 unchanged — no VerificationLanes edits)
```

## Self-Check: PASSED

---
*Phase: 01-orchestrator-live-wiring*
*Completed: 2026-05-30*
