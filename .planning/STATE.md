---
gsd_state_version: 1.0
milestone: v2.11
milestone_name: Orchestrator Live Wiring
status: executing
last_updated: "2026-05-30T09:19:23.372Z"
last_activity: 2026-05-30
progress:
  total_phases: 1
  completed_phases: 0
  total_plans: 3
  completed_plans: 1
  percent: 33
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-30)

**Core value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

**Current focus:** Phase 01 — orchestrator-live-wiring-runtime-pubsub-trace-broadcast-and-

## Current Position

Phase: 01 (orchestrator-live-wiring-runtime-pubsub-trace-broadcast-and-) — EXECUTING
Plan: 2 of 3 (01-01 complete)
Status: Executing Phase 01 — ready for plan 01-02
Last activity: 2026-05-30 — Completed plan 01-01 (Observe-layer PubSub bridge)

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
- ETS `insert_new` per trace_id for trace_opened dedup on OperatorBroadcast (plan 01-01)
- Telemetry `buffer_span/1` strips broadcast-only keys before Buffer cast (plan 01-01)

### Evidence

- `.planning/milestones/v2.10-MILESTONE-AUDIT.md` — v2.10 audit passed
- `.planning/milestones/v2.10-phases/82-docs-truth-milestone-closeout/82-VERIFICATION.md` — Phase 82 verification
- `.planning/milestones/v2.10-ROADMAP.md` — archived v2.10 roadmap
- `.planning/milestones/v2.10-REQUIREMENTS.md` — archived v2.10 requirements (4/4 Complete)

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| v2.11 | ORCH-LIVE-01 orchestrator live wiring | Phase 01 plan 01-01 complete — execute 01-02 |
| v2.12 | LANE-DEMO-01 gallery lane expansion | queued |
| Tech debt | Registry semver upgrade leg at 0.1.1+ | latent (from v2.10 audit) |

## Operator Next Steps

- Execute plan 01-02 — HITL tenant fan-out + OrchestratorLive handler updates
- `/gsd-progress` — view roadmap and milestone status
