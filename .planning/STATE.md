---
gsd_state_version: 1.0
milestone: v2.10
milestone_name: Hex Consumer Proof & Upgrade Smoke
status: planning
last_updated: "2026-05-29T19:31:52.555Z"
last_activity: 2026-05-29 — Milestone v2.10 roadmap created
progress:
  total_phases: 5
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-29)

**Core value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

**Current focus:** Milestone v2.10 — Hex consumer proof & upgrade smoke (Phases 78–82)

## Current Position

Phase: 78 (context gathered)
Plan: —
Status: Ready for `/gsd-plan-phase 78`
Last activity: 2026-05-29 — Phase 78 discuss-phase complete

## Performance Metrics

- **Active milestone:** `v2.10 Hex Consumer Proof & Upgrade Smoke` (5 phases, 4 requirements)
- **Latest Shipped Milestone:** `v2.9 Adoption Journey & Reference Demo` on 2026-05-29
- **Hex release:** `0.1.0` at git tag `v0.1.0` — https://hex.pm/packages/scoria

## Accumulated Context

### Roadmap Evolution

- **v2.10 (planning):** Tarball consumer proof in adoption closeout; upgrade smoke; post-publish registry gate; HexConsumerContract docs alignment.
- **v2.9 (shipped):** SupportJourney SSOT, host-proof overlay expansion, `examples/support_copilot/` gallery, advisory `mix scoria.test.support_copilot`, phases 77.1/77.2 audit closure.
- **v2.8 (shipped):** Semantic lane WAE, knowledge WAE, inventory baseline policy gate.
- **v2.7 (shipped):** Docs truth → release infra → Hex publish + README flip.

### Evidence

- `.planning/REQUIREMENTS.md` — v2.10 requirements (HEX-CONSUMER-01, HEX-UPGRADE-01, HEX-REGISTRY-01, DOCS-HEX-01)
- `.planning/ROADMAP.md` — Phases 78–82
- `.planning/milestones/v2.9-MILESTONE-AUDIT.md` — passed audit (2026-05-29)

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| v2.11+ | Orchestrator live wiring | queued |
| v2.12+ | Optional lane journeys in gallery | queued |
| v2.9 tech debt | `lookup_support_ticket` unused in overlay/gallery | backlog |
| v2.9 tech debt | Gallery browser quick-start not automated | backlog |
| v2.9 tech debt | Optional Nyquist VALIDATION.md for phases 74–77.2 | optional |

## Operator Next Steps

- `/gsd-plan-phase 78` — plan Hex consumer contract foundation (context in `78-CONTEXT.md`)
- `/gsd-plan-phase 78 --skip-research` — plan without research pass
