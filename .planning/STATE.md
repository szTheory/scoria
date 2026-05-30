---
gsd_state_version: 1.0
milestone: v2.15
milestone_name: Connector Adoption Lane
status: Awaiting next milestone
last_updated: "2026-05-30T13:07:50.348Z"
last_activity: 2026-05-30 — Milestone v2.15 completed and archived
progress:
  total_phases: 4
  completed_phases: 4
  total_plans: 1
  completed_plans: 1
  percent: 100
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-30 after v2.15 archive)

**Core value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

**Current focus:** Planning next milestone

## Current Position

Phase: Milestone v2.15 complete
Plan: —
Status: Awaiting next milestone
Last activity: 2026-05-30 — Milestone v2.15 archived

## Performance Metrics

- **Latest Shipped:** `v2.15 Connector Adoption Lane` (2026-05-30)
- **Previous Shipped:** `v2.14 Maintenance Release` (2026-05-30)
- **Hex release:** `0.1.1` prepared; publish via release-please pending CI green

## Accumulated Context

### Roadmap Evolution

- **v2.15 (shipped):** Named connector adoption lane — PR WAE after knowledge, not in closeout.
- **v2.14 (shipped prep):** `0.1.1` bump, CHANGELOG, release-please manifest.
- **v2.12–v2.13 (shipped):** Gallery lanes, MAINTAINERS split, docs truth.
- Phase 07.1 inserted after Phase 07: retroactive VERIFICATION ledgers for phases 05–07.

### Decisions

- Connector lane CI posture: **PR WAE** (like semantic/knowledge), not advisory — 2026-05-30
- `closeout_order/0` unchanged; connector stays optional escalation lane — 2026-05-30
- LiveView/integration proof in core repo; gallery connector journey remains advisory — 2026-05-30

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| Release | Publish 0.1.1 via release-please + registry semver upgrade smoke | in_progress |
| Tech debt | ReqLLM streaming adapter | deferred |
| Tech debt | Local `mix test.connector` migrate_core! ordering on fresh DB | deferred |

## Operator Next Steps

- `/gsd-new-milestone` — start next milestone (questioning → research → requirements → roadmap)
- Merge release-please PR when main CI green
