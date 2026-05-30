---
gsd_state_version: 1.0
milestone: v2.15
milestone_name: Connector Adoption Lane
status: planning
last_updated: "2026-05-30T18:30:00.000Z"
last_activity: 2026-05-30 — v2.15 milestone initialized; phases 05–07 planned
progress:
  total_phases: 3
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-30)

**Core value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

**Current focus:** v2.15 Connector Adoption Lane — `mix test.connector` named proof task

## Current Position

Phase: 05 — Lane contract + Mix task (implementation in progress)
Plan: —
Status: Defining requirements / executing phase 05
Last activity: 2026-05-30 — v2.15 milestone init + connector lane scaffold

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
