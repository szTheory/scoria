---
gsd_state_version: 1.0
milestone: v2.15
milestone_name: Connector Adoption Lane
status: complete
last_updated: "2026-05-30T19:00:00.000Z"
last_activity: 2026-05-30 — v2.15 phases 05–07 implemented
progress:
  total_phases: 3
  completed_phases: 3
  total_plans: 0
  completed_plans: 0
  percent: 100
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-30)

**Core value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

**Current focus:** v2.15 Connector Adoption Lane — `mix test.connector` named proof task

## Current Position

Phase: Milestone v2.15 complete
Plan: —
Status: Release 0.1.1 via release-please pending CI + merge
Last activity: 2026-05-30 — mix test.connector lane shipped (phases 05–07)

## Performance Metrics

- **Active Milestone:** `v2.15 Connector Adoption Lane`
- **Previous Shipped:** `v2.14 Maintenance Release` (2026-05-30)
- **Hex release:** `0.1.1` prepared; publish via release-please pending CI green

## Accumulated Context

### Roadmap Evolution

- **v2.15 (active):** Named connector adoption lane — PR WAE after knowledge, not in closeout.
- **v2.14 (shipped prep):** `0.1.1` bump, CHANGELOG, release-please manifest.
- **v2.12–v2.13 (shipped):** Gallery lanes, MAINTAINERS split, docs truth.

### Decisions

- Connector lane CI posture: **PR WAE** (like semantic/knowledge), not advisory — 2026-05-30
- `closeout_order/0` unchanged; connector stays optional escalation lane — 2026-05-30
- LiveView/integration proof in core repo; gallery connector journey remains advisory — 2026-05-30

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| Release | Publish 0.1.1 via release-please + registry semver upgrade smoke | in_progress |
| Tech debt | ReqLLM streaming adapter | deferred |

## Operator Next Steps

- `/gsd-plan-phase 05` or continue phase 05 implementation
- Merge release-please PR when main CI green
