---
gsd_state_version: 1.0
milestone: none
milestone_name: null
status: ready_for_next_milestone
last_updated: 2026-05-29
last_activity: 2026-05-29 -- Archived v2.9 milestone
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
stopped_at: null
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-29)

**Core value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

**Current focus:** Planning next milestone — run `/gsd-new-milestone` for v2.10

## Current Position

Phase: none
Plan: none
Status: Ready for next milestone
Last activity: 2026-05-29 — v2.9 milestone archived

## Performance Metrics

- **Latest Shipped Milestone:** `v2.9 Adoption Journey & Reference Demo` on 2026-05-29
- **Hex release:** `0.1.0` at git tag `v0.1.0` — https://hex.pm/packages/scoria
- **Active milestone:** none (start v2.10 via `/gsd-new-milestone`)

## Accumulated Context

### Roadmap Evolution

- **v2.9 (shipped):** SupportJourney SSOT, host-proof overlay expansion, `examples/support_copilot/` gallery, advisory `mix scoria.test.support_copilot`, phases 77.1/77.2 audit closure.
- **v2.8 (shipped):** Semantic lane WAE, knowledge WAE, inventory baseline policy gate.
- **v2.7 (shipped):** Docs truth → release infra → Hex publish + README flip.

### Evidence

- `.planning/milestones/v2.9-ROADMAP.md` — archived roadmap
- `.planning/milestones/v2.9-REQUIREMENTS.md` — archived requirements
- `.planning/milestones/v2.9-MILESTONE-AUDIT.md` — passed audit (2026-05-29)

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| v2.10+ | Hex consumer proof | queued |
| v2.11+ | Orchestrator live wiring | queued |
| v2.9 tech debt | `lookup_support_ticket` unused in overlay/gallery | backlog |
| v2.9 tech debt | Gallery browser quick-start not automated | backlog |
| v2.9 tech debt | Optional Nyquist VALIDATION.md for phases 74–77.2 | optional |

## Operator Next Steps

- `/gsd-new-milestone` — start v2.10 (Hex consumer proof recommended first in PROJECT.md queue)
