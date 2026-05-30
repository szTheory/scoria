---
gsd_state_version: 1.0
milestone: v2.11
milestone_name: Orchestrator Live Wiring
status: executing
last_updated: "2026-05-30T11:16:39.816Z"
last_activity: 2026-05-30 -- Phase 01.1 planning complete
progress:
  total_phases: 2
  completed_phases: 1
  total_plans: 6
  completed_plans: 3
  percent: 50
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-30)

**Core value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

**Current focus:** Phase 01.1 tech debt follow-ups

## Current Position

Phase: 01.1
Plan: Not started
Status: Ready to execute
Last activity: 2026-05-30 -- Phase 01.1 planning complete

## Performance Metrics

- **Active milestone:** `v2.11 Orchestrator Live Wiring` (ORCH-LIVE-01)
- **Latest Shipped Milestone:** `v2.10 Hex Consumer Proof & Upgrade Smoke` on 2026-05-30
- **Hex release:** `0.1.0` at git tag `v0.1.0` — https://hex.pm/packages/scoria
- **v2.10 archive:** `.planning/milestones/v2.10-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`, `.planning/milestones/v2.10-phases/`

## Accumulated Context

### Roadmap Evolution

- **v2.11 (executing):** Phase 01 all plans complete — ORCH-LIVE-01 ready for UAT.
- **v2.10 (shipped):** Tarball consumer proof; content-revision upgrade; registry attest; DOCS-HEX-01 drift guards. See `v2.10-MILESTONE-AUDIT.md`.
- **v2.9 (shipped):** SupportJourney SSOT, host-proof overlay, support_copilot gallery.
- Phase 01.1 inserted after Phase 1: Address tech debt: orchestrator live wiring follow-ups (URGENT)

### Decisions

- HexConsumerContract separate from AdopterDocContract (D-95)
- `adopter_doc_surfaces/0` scopes README + adoption_lanes only; maintainer gate map in ci_policy_contract_test (D-96, D-98)
- DOCS-HEX-01 Complete only after drift guards + audit (D-112)
- v2.10 archive: move phases 78–82 to `v2.10-phases/` — no silent deletion (D-108)
- ETS `insert_new` per trace_id for trace_opened dedup on OperatorBroadcast (plan 01-01)
- Telemetry `buffer_span/1` strips broadcast-only keys before Buffer cast (plan 01-01)
- RemoteApprovalProjection exposes arguments_preview only — never raw arguments in operator UI (plan 01-02)
- Hybrid HITL: modal when focus matches or no active modal; inbox highlight otherwise (plan 01-02)
- stream_insert trace on token flush so LiveComponents inside stream receive token_previews (plan 01-02)
- DB hydrate filters ai_spans by attributes tenant_id; maybe_seed_active_approval on reconnect (plan 01-03)
- Integration tests use Runtime.start_run + ReqLLM adapter shim; semantic lane pin only (plan 01-03)

### Evidence

- `.planning/phases/01-orchestrator-live-wiring-runtime-pubsub-trace-broadcast-and-/01-03-SUMMARY.md` — plan 01-03 verification (56 semantic lane tests, 4 integration tests)
- `.planning/phases/01-orchestrator-live-wiring-runtime-pubsub-trace-broadcast-and-/01-02-SUMMARY.md` — plan 01-02 verification (46 tests, 0 failures)
- `.planning/milestones/v2.10-MILESTONE-AUDIT.md` — v2.10 audit passed

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| v2.11 | ORCH-LIVE-01 orchestrator live wiring | Phase 01 plans complete — UAT next |
| v2.12 | LANE-DEMO-01 gallery lane expansion | queued |
| Tech debt | Registry semver upgrade leg at 0.1.1+ | latent (from v2.10 audit) |

## Operator Next Steps

- `/gsd-verify-work` — conversational UAT for phase 01
- `/gsd-progress` — view roadmap and milestone status
