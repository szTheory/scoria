---
phase: 01-orchestrator-live-wiring-runtime-pubsub-trace-broadcast-and-
plan: 02
subsystem: observability
tags: [pubsub, hitl, phoenix-liveview, trace-projection, token-preview]

requires:
  - phase: 01-orchestrator-live-wiring-runtime-pubsub-trace-broadcast-and-
    provides: OperatorBroadcast tenant fan-out, TraceProjection, telemetry broadcast hook
provides:
  - RemoteApprovalProjection arguments_preview + connector_label for inbox/modal
  - Real OperatorBroadcast hitl_request/approval_decided tenant fan-out
  - Workflows not_pending guard and approval_decided broadcast on approve/3
  - OrchestratorLive incremental trace_opened/trace_span merge
  - Hybrid HITL modal with focus-aware inbox highlight
  - Per-span_id token preview coalesce on TraceTreeComponent LLM rows
affects:
  - 01-03 DB hydrate on mount and integration tests

tech-stack:
  added: []
  patterns:
    - "Dual broadcast preserved: run-scoped workflow topic + tenant hitl_request"
    - "Hybrid HITL: modal when focus matches or no active modal; inbox highlight otherwise"
    - "Per-span token_buffers with 75ms coalesce and 256-chunk backpressure cap"
    - "stream_insert on token flush to re-render LiveComponents inside trace stream"

key-files:
  created: []
  modified:
    - lib/scoria/workflows/remote_approval_projection.ex
    - lib/scoria/observe/operator_broadcast.ex
    - lib/scoria/workflows.ex
    - lib/scoria_web/live/orchestrator_live.ex
    - lib/scoria_web/components/approval_inbox_component.ex
    - lib/scoria_web/components/trace_tree_component.ex
    - config/config.exs
    - test/scoria/workflows/remote_approval_projection_test.exs
    - test/scoria/observe/operator_broadcast_test.exs
    - test/scoria/workflows_test.exs
    - test/scoria_web/live/orchestrator_live_test.exs

key-decisions:
  - "Modal and inbox share RemoteApprovalProjection map; raw arguments never in DOM"
  - "approval_matches_focus? treats runtime_query string as session_id or workflow_run_id match"
  - "stream_insert trace on token flush so LiveComponents inside phx-update=stream receive token_previews"

patterns-established:
  - "Stale approve/3 returns :not_pending with operator-friendly flash in OrchestratorLive"
  - "Dismiss ('Decide later') clears active_approval without calling approve/3"

requirements-completed: [ORCH-LIVE-01]

duration: 18min
completed: 2026-05-30
---

# Phase 01 Plan 02: HITL Fan-Out and OrchestratorLive Live Handlers Summary

**Tenant-scoped HITL projection fan-out, hybrid approval modal/inbox UX, incremental trace merge, and per-span LLM token previews wired into OrchestratorLive**

## Performance

- **Duration:** 18 min
- **Started:** 2026-05-30T09:09:00Z
- **Completed:** 2026-05-30T09:27:04Z
- **Tasks:** 5 completed
- **Files modified:** 11

## Accomplishments

- Extended `RemoteApprovalProjection` with redacted `arguments_preview` and `connector_label`; removed raw arguments from operator projection
- Replaced `OperatorBroadcast` HITL stubs with real `hitl_request/2` and `approval_decided/3`; wired dual broadcast from `mark_waiting_for_approval/3` and `approve/3` with `:not_pending` guard
- Added OrchestratorLive handlers for `{:trace_opened,_}`, `{:trace_span,_,_}`, `{:trace_delta,_}` with idempotent span upsert and depth decoration
- Implemented hybrid HITL UX: focus-aware modal, inbox row highlight, dismiss without approve, stale-decision flash, `approval_decided` sync
- Replaced global `#token-stream` with per-span 75ms coalesced previews on LLM rows in `TraceTreeComponent`

## Task Commits

Each task was committed atomically:

1. **Task 01-02-01: Extend RemoteApprovalProjection with arguments_preview** - `b78061a` (feat)
2. **Task 01-02-02: Implement OperatorBroadcast HITL fan-out and Workflows multi-operator guards** - `eb7ba56` (feat)
3. **Task 01-02-03: OrchestratorLive incremental trace handlers** - `87579fb` (feat)
4. **Task 01-02-04: Hybrid HITL modal, inbox UX, and approval_decided handler** - `8cfec3a` (feat)
5. **Task 01-02-05: Per-span token coalesce and TraceTreeComponent preview slot** - `235484f` (feat)

**Plan metadata:** pending (docs commit)

## Files Created/Modified

- `lib/scoria/workflows/remote_approval_projection.ex` - Redacted arguments_preview and connector_label in projection map
- `lib/scoria/observe/operator_broadcast.ex` - Real HITL tenant broadcasts replacing stubs
- `lib/scoria/workflows.ex` - hitl_request fan-out, not_pending guard, approval_decided broadcast
- `lib/scoria_web/live/orchestrator_live.ex` - Trace handlers, hybrid HITL UX, per-span token coalesce
- `lib/scoria_web/components/approval_inbox_component.ex` - highlight_approval_id row styling
- `lib/scoria_web/components/trace_tree_component.ex` - token_previews on LLM span rows
- `config/config.exs` - live_token_coalesce_ms: 75
- Test files for projection, broadcast, workflows, and orchestrator live unit tier

## Decisions Made

- Used bracket-safe map access in HITL modal template so partial projection maps from tests do not raise KeyError
- Added flash rendering to OrchestratorLive dashboard for stale approval operator feedback
- Re-stream trace on token flush because LiveComponents inside `phx-update="stream"` do not re-render on sibling assign changes alone

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fix approve/3 transaction error shape for :not_pending rollback**
- **Found during:** Task 01-02-02 (Workflows HITL guards)
- **Issue:** `repo.rollback(:not_pending)` returns `{:error, :not_pending}` but case clause only handled 4-tuple form
- **Fix:** Added `{:error, :not_pending}` case clause in approve/3
- **Files modified:** `lib/scoria/workflows.ex`
- **Verification:** `MIX_ENV=test mix test test/scoria/workflows_test.exs` passes
- **Committed in:** `eb7ba56`

**2. [Rule 1 - Bug] Re-stream trace on token flush for LiveComponent updates**
- **Found during:** Task 01-02-05 (token preview)
- **Issue:** Token previews updated in assigns but TraceTreeComponent inside stream did not re-render
- **Fix:** `stream_insert(:traces, trace)` after flush when span belongs to trace
- **Files modified:** `lib/scoria_web/live/orchestrator_live.ex`
- **Verification:** token preview unit test passes
- **Committed in:** `235484f`

**3. [Rule 2 - Missing Critical] Add flash UI to OrchestratorLive for stale approval message**
- **Found during:** Task 01-02-04 (HITL UX tests)
- **Issue:** `put_flash/3` had no render target in dashboard template
- **Fix:** Added flash banner loop in render/1
- **Files modified:** `lib/scoria_web/live/orchestrator_live.ex`
- **Verification:** stale approval test passes
- **Committed in:** `8cfec3a`

---

**Total deviations:** 3 auto-fixed (2 bugs, 1 missing critical)
**Impact on plan:** All fixes required for acceptance criteria and test stability. No scope creep.

## Issues Encountered

None blocking — one flaky stale-approval test resolved by explicit `approval_decided` sync and flash UI.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 01-03 ready: DB hydrate on mount, integration tests without send/2, adoption doc fragment for session keys
- ORCH-LIVE-01 partially satisfied; integration lane and reconnect hydrate remain in 01-03

## Verification

```
MIX_ENV=test mix compile --warnings-as-errors          → PASS
MIX_ENV=test mix test test/scoria/observe/operator_broadcast_test.exs \
  test/scoria/workflows/remote_approval_projection_test.exs \
  test/scoria/workflows_test.exs \
  test/scoria_web/live/orchestrator_live_test.exs      → 46 tests, 0 failures
```

## Self-Check: PASSED

---
*Phase: 01-orchestrator-live-wiring*
*Completed: 2026-05-30*
