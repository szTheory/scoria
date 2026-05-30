---
gsd_state_version: 1.0
milestone: v2.11
milestone_name: Orchestrator Live Wiring
status: Awaiting next milestone
last_updated: "2026-05-30T11:39:01.838Z"
last_activity: 2026-05-30 — Milestone v2.11 completed and archived
progress:
  total_phases: 2
  completed_phases: 2
  total_plans: 6
  completed_plans: 6
  percent: 100
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-30)

**Core value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

**Current focus:** Planning next milestone (v2.12)

## Current Position

Phase: Milestone v2.11 complete
Plan: —
Status: Awaiting next milestone
Last activity: 2026-05-30 — Milestone v2.11 completed and archived

## Performance Metrics

- **Latest Shipped Milestone:** `v2.11 Orchestrator Live Wiring` on 2026-05-30
- **v2.11 archive:** `.planning/milestones/v2.11-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`, `.planning/milestones/v2.11-phases/`
- **Hex release:** `0.1.0` at git tag `v0.1.0` — https://hex.pm/packages/scoria
- **v2.10 archive:** `.planning/milestones/v2.10-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`, `.planning/milestones/v2.10-phases/`

## Accumulated Context

### Roadmap Evolution

- **v2.11 (shipped):** ORCH-LIVE-01 — OperatorBroadcast, HITL producer path, hydrate, 01.1 hardening. See `v2.11-MILESTONE-AUDIT.md`.
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
- Span-delta telemetry: Redactor.redact → scrub_text on chunk → OperatorBroadcast.span_delta (D-133, plan 01.1-01)
- Hydrate path: Redactor.redact on span.attributes before TraceProjection.span_view (D-134, plan 01.1-01)
- Redactor.scrub_text/1 replaces deny-list key=value patterns in streaming chunk strings (plan 01.1-01)
- Approval integration tests use render_click on producer path; boolean eventually/1 for polling (D-135–D-136, plan 01.1-02)
- Public `Telemetry.emit_span_delta/1` for delta emit; integration tests must not use raw delta `:telemetry.execute` (D-139, plan 01.1-03)
- `maybe_clear_token_preview/2` cancels `token_timers` and clears `token_buffers` on span complete (D-141, plan 01.1-03)
- Token coalesce E2E: active LLM span + handler `emit_span_delta` → `"Hello world"` in DOM after 75ms coalesce (D-140, plan 01.1-03)

### Evidence

- `.planning/milestones/v2.11-phases/01.1-address-tech-debt-orchestrator-live-wiring-follow-ups/01.1-03-SUMMARY.md` — plan 01.1-03 verification (integration 8 tests, semantic fast path)
- `.planning/milestones/v2.11-phases/01.1-address-tech-debt-orchestrator-live-wiring-follow-ups/01.1-02-SUMMARY.md` — plan 01.1-02 verification (integration 7 tests, unit 18 tests)
- `.planning/milestones/v2.11-phases/01.1-address-tech-debt-orchestrator-live-wiring-follow-ups/01.1-01-SUMMARY.md` — plan 01.1-01 verification (telemetry 4 tests, integration 5 tests, compile WAE)
- `.planning/milestones/v2.11-phases/01-orchestrator-live-wiring-runtime-pubsub-trace-broadcast-and-/01-03-SUMMARY.md` — plan 01-03 verification (56 semantic lane tests, 4 integration tests)
- `.planning/milestones/v2.11-phases/01-orchestrator-live-wiring-runtime-pubsub-trace-broadcast-and-/01-02-SUMMARY.md` — plan 01-02 verification (46 tests, 0 failures)
- `.planning/milestones/v2.10-MILESTONE-AUDIT.md` — v2.10 audit passed

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| v2.12 | LANE-DEMO-01 gallery lane expansion | queued |
| Tech debt | Registry semver upgrade leg at 0.1.1+ | latent (from v2.10 audit) |
| Tech debt | Phase 01.1 missing Nyquist VALIDATION.md | optional `/gsd-validate-phase 01.1` |
| Tech debt | ReqLLM streaming adapter (D-125/D-128) | deferred to v2.12+ |

## Operator Next Steps

- Start the next milestone with `/gsd-new-milestone`
