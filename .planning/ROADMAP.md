# Roadmap: Scoria

**Milestone:** v2.11 Orchestrator Live Wiring
**Last updated:** 2026-05-30 (phase 01.1 complete)

## Overview

Wire orchestrator live trace broadcast and HITL approval modal from real runtime events — the first milestone after Hex consumer proof closed the adopter-trust gap.

**Requirements:** 1 (ORCH-LIVE-01) | **Phases:** 2 (1 complete + 1 inserted) | **Coverage:** 100% mapped

## Phases

### Phase 01: Orchestrator live wiring

**Goal:** Wire runtime→PubSub trace broadcast and HITL approval modal from real workflow/runtime events (close HOLLOW_PROP on OrchestratorLive).

**Requirements:** ORCH-LIVE-01

**Depends on:** v2.10 shipped (Hex consumer proof)

**Canonical refs:** `.planning/phases/01-orchestrator-live-wiring-runtime-pubsub-trace-broadcast-and-/01-CONTEXT.md`, `prompts/phoenix-ai-lib-deep-research.md`

**Success criteria:**
1. `Scoria.Observe.OperatorBroadcast` fans out span/trace deltas to `scoria:runs:{tenant_id}` from telemetry (not test `send/2`).
2. `Workflows.mark_waiting_for_approval/3` fans out HITL projection to tenant topic; modal opens from real approval pause.
3. OrchestratorLive hydrates recent traces + pending approvals on mount; PubSub merges live deltas.
4. `orchestrator_live_integration_test.exs` proves ORCH-LIVE-01 without `send/2`; pinned in semantic fast-path lane.
5. `VerificationLanes.closeout_order/0` unchanged.

**Plans:** 3/3 plans complete

**Status:** Complete (2026-05-30) — ready for `/gsd-verify-work`

---

### Phase 01.1: Address tech debt: orchestrator live wiring follow-ups (INSERTED)

**Goal:** Harden ORCH-LIVE-01 trust paths — delta/hydrate redaction, approval decision integration proof, token delta coalesce proof (01-REVIEW + v2.11 audit follow-ups).

**Requirements:** ORCH-LIVE-01 (hardening; no new REQ-ID)
**Depends on:** Phase 01
**Plans:** 3/3 plans complete

Plans:
- [x] **01.1-01** Redaction defense-in-depth (delta telemetry + DB hydrate) — Wave 1
- [x] **01.1-02** Approval approve/reject integration tests — Wave 2
- [x] **01.1-03** `emit_span_delta/1` + token coalesce E2E + timer cancel — Wave 3

**Cross-cutting constraints:**
- Redact → broadcast → buffer ordering preserved on all telemetry egress paths (D-118, D-133)
- Integration tests use `Runtime.start_run/2` producer path — no `send/2` (D-129)
- `VerificationLanes.closeout_order/0` unchanged

**Status:** Complete (2026-05-30) — ready for `/gsd-verify-work`

---

## Phase map

| Phase | Name | Requirements | Status |
|-------|------|--------------|--------|
| 01 | Orchestrator live wiring | ORCH-LIVE-01 | Complete (2026-05-30) |
| 01.1 | 3/3 | Complete    | 2026-05-30 |

## Completed milestones

- ✅ **v2.10 Hex Consumer Proof & Upgrade Smoke** — Phases 78–82 (shipped 2026-05-30) — `.planning/milestones/v2.10-*`
- ✅ **v2.9 Adoption Journey & Reference Demo** — Phases 74–77.2 (shipped 2026-05-29) — `.planning/milestones/v2.9-*`
- ✅ **v2.8 CI Hardening & Post-Ship Hygiene** — Phase 73 — `.planning/milestones/v2.8-*`
- ✅ **v2.7 OSS Release + Docs Truth** — Phases 70–72 — `.planning/milestones/v2.7-*`
- ✅ **v2.6 Warning Ratchet** — Phases 66–69 — `.planning/milestones/v2.6-*`

## Next milestone queue

- **v2.11:** Orchestrator live wiring (ORCH-LIVE-01) — **current, UAT pending**
- **v2.12:** Optional lane journeys in gallery (LANE-DEMO-01)
