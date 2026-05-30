---
gsd_state_version: 1.0
milestone: v2.15
milestone_name: Connector Adoption Lane
status: executing
last_updated: "2026-05-30T12:58:27.729Z"
last_activity: 2026-05-30 -- Phase 07.1 planning complete
progress:
  total_phases: 4
  completed_phases: 0
  total_plans: 1
  completed_plans: 2
  percent: 0
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-30)

**Core value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

**Current focus:** v2.15 Connector Adoption Lane — `mix test.connector` named proof task

## Current Position

Phase: 07.1
Plan: —
Status: Ready to execute
Last activity: 2026-05-30 -- Phase 07.1 planning complete

## Performance Metrics

- **Active Milestone:** `v2.15 Connector Adoption Lane`
- **Previous Shipped:** `v2.14 Maintenance Release` (2026-05-30)
- **Hex release:** `0.1.1` prepared; publish via release-please pending CI green

## Accumulated Context

### Roadmap Evolution

- **v2.15 (active):** Named connector adoption lane — PR WAE after knowledge, not in closeout.
- **v2.14 (shipped prep):** `0.1.1` bump, CHANGELOG, release-please manifest.
- **v2.12–v2.13 (shipped):** Gallery lanes, MAINTAINERS split, docs truth.
- Phase 07.1 inserted after Phase 07: Close gap: VERIFICATION artifacts for v2.15 phases 05–07 (URGENT)

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

- `/gsd-plan-phase 07.1` — retroactive VERIFICATION.md for phases 05–07
- Merge release-please PR when main CI green
