---
gsd_state_version: 1.0
milestone: v2.11
milestone_name: Orchestrator Live Wiring
status: Context gathered — run `/gsd-plan-phase 1`
last_updated: "2026-05-30T01:37:19.276Z"
last_activity: 2026-05-30 -- Phase 01 discuss complete (D-113–D-131 locked)
progress:
  total_phases: 1
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-30)

**Core value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

**Current focus:** v2.11 — Orchestrator live wiring (ORCH-LIVE-01)

## Current Position

Phase: 01 — Orchestrator live wiring
Plan: —
Status: Context gathered — run `/gsd-plan-phase 1`
Last activity: 2026-05-30 -- Phase 01 discuss complete (D-113–D-131 locked)

## Performance Metrics

- **Active milestone:** `v2.11 Orchestrator Live Wiring` (ORCH-LIVE-01)
- **Latest Shipped Milestone:** `v2.10 Hex Consumer Proof & Upgrade Smoke` on 2026-05-30
- **Hex release:** `0.1.0` at git tag `v0.1.0` — https://hex.pm/packages/scoria
- **v2.10 archive:** `.planning/milestones/v2.10-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`, `.planning/milestones/v2.10-phases/`

## Accumulated Context

### Roadmap Evolution

- **v2.11 (planning):** Phase 01 context locked — OperatorBroadcast, trace deltas, HITL fan-out, integration tests (ORCH-LIVE-01).
- **v2.10 (shipped):** Tarball consumer proof; content-revision upgrade; registry attest; DOCS-HEX-01 drift guards. See `v2.10-MILESTONE-AUDIT.md`.
- **v2.9 (shipped):** SupportJourney SSOT, host-proof overlay, support_copilot gallery.

### Decisions

- HexConsumerContract separate from AdopterDocContract (D-95)
- `adopter_doc_surfaces/0` scopes README + adoption_lanes only; maintainer gate map in ci_policy_contract_test (D-96, D-98)
- DOCS-HEX-01 Complete only after drift guards + audit (D-112)
- v2.10 archive: move phases 78–82 to `v2.10-phases/` — no silent deletion (D-108)

### Evidence

- `.planning/milestones/v2.10-MILESTONE-AUDIT.md` — v2.10 audit passed
- `.planning/milestones/v2.10-phases/82-docs-truth-milestone-closeout/82-VERIFICATION.md` — Phase 82 verification
- `.planning/milestones/v2.10-ROADMAP.md` — archived v2.10 roadmap
- `.planning/milestones/v2.10-REQUIREMENTS.md` — archived v2.10 requirements (4/4 Complete)

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| v2.11 | ORCH-LIVE-01 orchestrator live wiring | Phase 01 context done — `/gsd-plan-phase 1` |
| v2.12 | LANE-DEMO-01 gallery lane expansion | queued |
| Tech debt | Registry semver upgrade leg at 0.1.1+ | latent (from v2.10 audit) |

## Operator Next Steps

- `/gsd-plan-phase 1` — plan Phase 01 from locked context (recommended next)
- `/gsd-discuss-phase 1` — re-open context if decisions change
- `/gsd-progress` — view roadmap and milestone status
