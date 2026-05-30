---
gsd_state_version: 1.0
milestone: v2.14
milestone_name: Maintenance Release & Registry Upgrade Proof
status: complete
last_updated: "2026-05-30T18:00:00.000Z"
last_activity: 2026-05-30 — v2.13/v2.14 closeout; ready for v2.15 + 0.1.1 publish
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-30)

**Core value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

**Current focus:** v2.15 Connector Adoption Lane (planning) / publish 0.1.1 via release-please

## Current Position

Phase: Not started (v2.15 milestone pending init)
Plan: —
Status: v2.13/v2.14 closed; release-please 0.1.1 ready; v2.15 queued
Last activity: 2026-05-30 — v2.13/v2.14 bookkeeping complete

## Performance Metrics

- **Latest Shipped Milestone:** `v2.14 Maintenance Release` on 2026-05-30 (version bump; publish pending)
- **Previous:** `v2.12 Adoption Confidence & Reference Demo` on 2026-05-30
- **Hex release:** `0.1.1` prepared (manifest bumped; publish via release-please)
- **Gallery lane:** `mix scoria.test.support_copilot` — 9 gallery tests + drift guards green

## Accumulated Context

### Roadmap Evolution

- **v2.14 (shipped prep):** `0.1.1` bump, CHANGELOG, release-please manifest.
- **v2.13 (shipped):** MAINTAINERS split, Hex metadata, README session keys.
- **v2.12 (shipped):** SupportJourney.Handlers, gallery lane journeys, orchestrator smoke.
- **Queue:** v2.15 connector adoption lane (`mix test.connector`).

### Decisions

- Demo-first before full docs persona split — v2.13 shipped with v2.12 (2026-05-30)
- LiveView producer path > browser for CI closeout (2026-05-30)
- Publish 0.1.1 before v2.15 execution (2026-05-30)

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| v2.15 | Named connector adoption lane | queued |
| Release | Publish 0.1.1 via release-please + registry semver upgrade smoke | ready |
| Tech debt | ReqLLM streaming adapter | deferred |

## Operator Next Steps

- Publish 0.1.1: merge to main → release-please PR → CI green → merge
- `/gsd-new-milestone` for v2.15 connector lane
