---
phase: 09-restore-audited-approval-and-incident-delivery-wiring
plan: 02
subsystem: sre
tags: [sre, incidents, relay, notifications]
requires:
  - phase: 09-restore-audited-approval-and-incident-delivery-wiring
    provides: "Workflow-owned approval audit boundary"
provides:
  - "Transactional `NotificationDelivery` production from live incident routing"
  - "Delivery dedupe and review-to-page escalation rules proven in producer tests"
  - "Relay coverage against producer-shaped delivery rows"
affects: [sre, relay]
tech-stack:
  added: []
  patterns:
    - "Incident creation and delivery intent rows commit in the same `Ecto.Multi`."
    - "Delivery rows carry explicit local routing and transport evidence before relay fanout."
key-files:
  created: []
  modified:
    - lib/scoria/sre/incident_manager.ex
    - test/scoria/sre/incident_test.exs
    - test/scoria/sre/relay_test.exs
key-decisions:
  - "Review incidents default to `chimeway`/`reviews`; page incidents default to `mailglass`/`ops@example.com`."
  - "Producer metadata records `transport_mode` as `configured`, `unconfigured`, or `noop` without sending in-transaction."
patterns-established:
  - "Deduped repeats do not emit extra delivery rows unless incident routing escalates to `page`."
requirements-completed: [SRE-06]
duration: 45m
completed: 2026-05-12
---

# Phase 9 Plan 02 Summary

**Incident routing now writes durable notification intent rows in the same transaction as incident, alert, and incident-event records, giving relay a real producer path to drain.**

## Accomplishments
- Added `NotificationDelivery` production to `Scoria.SRE.IncidentManager.record_alert_event/1`.
- Kept delivery creation transactional with incident graph writes and limited new rows to first-open plus review-to-page escalation.
- Stored producer-side routing and transport evidence directly on delivery rows so noop or unconfigured transport semantics remain locally inspectable before relay runs.
- Updated incident tests to prove delivery row shape, dedupe behavior, and escalation behavior.
- Updated relay tests to consume deliveries produced by `Scoria.SRE.record_alert_event/1` instead of relying only on hand-seeded fixtures.

## Task Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1-2 | `3e6ecf1730ee83a33566558bc6f24a1b9f05613c` | Produce durable delivery rows and align relay verification with producer-shaped deliveries |

## Deviations from Plan

None - plan executed within the intended seam and verification scope.

## Verification

- `MIX_ENV=test mix test test/scoria/sre/incident_test.exs test/scoria/sre/relay_test.exs`

## Next Phase Readiness

Relay and the operator notebook can now consume real delivery rows produced from live incident routing instead of seeded placeholders.
