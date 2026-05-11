---
phase: 07-seismograph
plan: 08
subsystem: infra
tags: [otp, ecto, relay, audit, alerts, threadline, chimeway, mailglass]
requires:
  - phase: 07-04
    provides: durable audit outbox rows, incidents, and notification deliveries
provides:
  - supervised durable relay worker for audit and notification fanout
  - optional Threadline audit adapter with dependency-free no-op default
  - optional Chimeway and Mailglass alert adapters with sink-kind routing
affects: [sre, application-runtime, audit-export, notifications]
tech-stack:
  added: []
  patterns: [supervised durable row claiming, sink-kind adapter routing, dependency-free optional dispatchers]
key-files:
  created:
    - lib/scoria/sre/relay.ex
    - lib/scoria/sre/adapters/threadline.ex
    - lib/scoria/sre/adapters/chimeway.ex
    - lib/scoria/sre/adapters/mailglass.ex
    - test/scoria/sre/relay_test.exs
  modified:
    - lib/scoria/application.ex
key-decisions:
  - "Started the relay in the real application tree and disabled automatic polling only in test so the worker remains supervised without fighting the SQL sandbox."
  - "Routed notification deliveries by durable sink_kind values instead of introducing a broader alert-routing layer."
  - "Kept first-party adapters dependency-free by shaping envelopes locally and delegating only through optional configured dispatchers."
patterns-established:
  - "Relay claims pending and failed rows transactionally, increments attempt counts before fanout, and persists last-error state locally."
  - "Optional sink adapters return successful no-op envelopes when unconfigured so core Scoria remains installable without vendor dependencies."
requirements-completed: [SRE-06, SRE-08]
duration: 5 min
completed: 2026-05-11
---

# Phase 7 Plan 08: Relay Runtime Summary

**Supervised durable SRE relay with retryable audit fanout and optional Threadline, Chimeway, and Mailglass adapters**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-11T19:11:00Z
- **Completed:** 2026-05-11T19:16:00Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Added `Scoria.SRE.Relay` as a supervised application child that drains durable audit and notification rows without requiring Oban.
- Persisted retry attempt state and durable last-error metadata for failed audit deliveries so retries remain inspectable and idempotent.
- Added first-party Threadline, Chimeway, and Mailglass adapters that stay no-op by default and preserve envelope-oriented payloads.

## Task Commits

1. **Task 1: Supervise a Durable Relay Worker** - `b0dbc1c` (test), `fa3eab0` (feat)
2. **Task 2: Implement Optional First-Party Sink Adapters** - `2fb9c23` (test), `6f75ffc` (feat)

## Files Created/Modified
- `lib/scoria/application.ex` - Starts the relay under the real OTP supervision tree.
- `lib/scoria/sre/relay.ex` - Claims pending and failed durable rows, delivers through configured sinks, and persists retry state.
- `lib/scoria/sre/adapters/threadline.ex` - Shapes audit envelopes for optional Threadline delivery with a no-op default.
- `lib/scoria/sre/adapters/chimeway.ex` - Shapes review and page alert envelopes for optional Chimeway delivery.
- `lib/scoria/sre/adapters/mailglass.ex` - Shapes review and page alert envelopes for optional Mailglass delivery.
- `test/scoria/sre/relay_test.exs` - Covers supervision wiring, durable retry behavior, no-op adapter defaults, and sink-kind routing.

## Decisions Made
- Started the relay in every normal app boot, including tests, but suppressed timer-driven polling in `MIX_ENV=test` so the child remains present without stealing sandbox-owned DB connections.
- Used `NotificationDelivery.sink_kind` as the routing key for Chimeway and Mailglass instead of widening `Scoria.SRE` with a new routing API.
- Stored audit delivery errors in durable metadata because `AuditOutboxEvent` already exposes a stable map field without requiring extra schema churn in this slice.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Disabled automatic relay polling in test while keeping supervision active**
- **Found during:** Task 1 (Supervise a Durable Relay Worker)
- **Issue:** Starting timer-driven relay polling under `MIX_ENV=test` caused SQL sandbox ownership errors before tests could check out connections.
- **Fix:** Kept `Scoria.SRE.Relay` supervised in the real application tree but gated automatic polling off in test; manual `drain_once/0` still exercises the real durable delivery path.
- **Files modified:** `lib/scoria/sre/relay.ex`
- **Verification:** `MIX_ENV=test mix test test/scoria/sre/relay_test.exs`
- **Committed in:** `fa3eab0`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The auto-fix was required for reliable verification and did not widen runtime scope.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Durable relay fanout is in place for later operator-facing evidence and notification UX.
- Optional adapter dispatch can now be wired to real downstream services without changing the core relay contract.

## Self-Check: PASSED

- Summary file created at `.planning/phases/07-seismograph/07-08-SUMMARY.md`
- Task commits present: `b0dbc1c`, `fa3eab0`, `2fb9c23`, `6f75ffc`

---
*Phase: 07-seismograph*
*Completed: 2026-05-11*
