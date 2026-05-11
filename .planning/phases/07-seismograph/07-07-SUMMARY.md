---
phase: 07-seismograph
plan: 07
subsystem: database
tags: [ecto, postgres, sre, incidents, audit]
requires:
  - phase: 07-seismograph
    provides: "Budget policies, reservations, and breaker trip storage from 07-06"
provides:
  - "Additive alert, incident, notification-delivery, and audit-outbox tables"
  - "Explicit Ecto schemas for alert and incident durable nouns"
  - "Focused SRE tests covering stable incident keys and hashed audit refs"
affects: [incident-routing, audit-relay, operator-ui, notifications]
tech-stack:
  added: []
  patterns: ["Explicit binary-id Ecto schemas", "Append-only incident and audit evidence rows"]
key-files:
  created:
    - priv/repo/migrations/20260511171000_create_sre_incident_and_audit_tables.exs
    - lib/scoria/sre/alert_policy.ex
    - lib/scoria/sre/alert_event.ex
    - lib/scoria/sre/incident.ex
    - lib/scoria/sre/incident_event.ex
    - lib/scoria/sre/notification_delivery.ex
    - lib/scoria/sre/audit_outbox_event.ex
  modified:
    - test/scoria/sre_test.exs
key-decisions:
  - "Kept root rows optimistic-lock ready and append-only evidence rows explicit instead of hiding future routing state in maps."
  - "Stored redacted audit refs and payload hashes rather than raw approval/tool arguments to match the phase threat model."
patterns-established:
  - "Incident roots use stable `incident_key` plus dedupe metadata for later routing and review flows."
  - "Notification and audit rows track pending status and attempt counters so relays can claim work without reshaping storage."
requirements-completed: [SRE-01, SRE-08]
duration: 4m
completed: 2026-05-11
---

# Phase 7 Plan 7: Incident, Delivery, and Audit Durable Storage Summary

**Durable alert, incident, notification-delivery, and audit-outbox storage with stable incident keys and hashed audit references**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-11T18:32:30Z
- **Completed:** 2026-05-11T18:36:51Z
- **Tasks:** 1
- **Files modified:** 8

## Accomplishments
- Added the second SRE durable-storage migration covering alert policies/events, incidents/events, notification deliveries, and audit outbox rows.
- Added six explicit binary-id Ecto schemas with optimistic locking on root rows and append-only evidence fields on event rows.
- Extended `test/scoria/sre_test.exs` to verify stable incident keys, delivery attempt state, and hashed/redacted audit evidence.

## Task Commits

1. **Task 1: Create Incident, Delivery, and Audit Durable Tables** - `88b8843` (test), `644e98d` (feat)

## Files Created/Modified
- `priv/repo/migrations/20260511171000_create_sre_incident_and_audit_tables.exs` - additive storage for alert, incident, delivery, and audit nouns
- `lib/scoria/sre/alert_policy.ex` - root alert policy schema with routing and version refs
- `lib/scoria/sre/alert_event.ex` - append-only alert event evidence linked to incidents
- `lib/scoria/sre/incident.ex` - stable incident root schema with dedupe key and optimistic locking
- `lib/scoria/sre/incident_event.ex` - append-only incident evidence rows
- `lib/scoria/sre/notification_delivery.ex` - delivery queue state with attempt counters and payload hash
- `lib/scoria/sre/audit_outbox_event.ex` - audit export row with payload hash and redacted refs
- `test/scoria/sre_test.exs` - focused coverage for the new durable nouns

## Decisions Made
- Root records (`AlertPolicy`, `Incident`) carry `lock_version` so later routing logic can use optimistic locking without revisiting the storage shape.
- Audit export rows keep only `payload_hash`, `redacted_refs`, and linkage identifiers so sensitive payloads stay out of durable storage by default.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- Test-database migration initially failed on an earlier knowledge migration because the default local Postgres instance did not have the `vector` extension installed. Verification proceeded against the repo’s supported pgvector bootstrap service on `localhost:55432`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Incident routing, relay claiming, and operator projections can now build on concrete alert, incident, delivery, and audit schemas.
- No blockers remain in this slice beyond the existing pgvector prerequisite for any fresh local test database setup.

## Self-Check: PASSED

- Verified `.planning/phases/07-seismograph/07-07-SUMMARY.md` exists on disk.
- Verified task commits `88b8843` and `644e98d` exist in git history.

---
*Phase: 07-seismograph*
*Completed: 2026-05-11*
