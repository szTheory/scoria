---
phase: 01
slug: orchestrator-live-wiring-runtime-pubsub-trace-broadcast-and-
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-30
---

# Phase 01 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` test aliases; `Scoria.IntegrationCase` |
| **Quick run command** | `MIX_ENV=test mix test test/scoria/observe/operator_broadcast_test.exs test/scoria/observe/trace_projection_test.exs test/scoria/observe/telemetry_test.exs` |
| **Full suite command** | `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test.semantic_fast_path --warnings-as-errors` |
| **Estimated runtime** | ~60–120 seconds (integration + semantic lane) |

---

## Sampling Rate

- **After every task commit:** Run wave-appropriate quick run command from RESEARCH.md sampling table
- **After every plan wave:** Run wave full command (observe / workflows / integration)
- **Before `/gsd-verify-work`:** Semantic fast-path lane must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01-01-* | 01-01 | 1 | ORCH-LIVE-01 | T-01-01 | Drop broadcast when tenant_id missing | unit | `MIX_ENV=test mix test test/scoria/observe/operator_broadcast_test.exs` | ❌ W0 | ⬜ pending |
| 01-01-* | 01-01 | 1 | ORCH-LIVE-01 | T-01-02 | Redacted span_view previews only | unit | `MIX_ENV=test mix test test/scoria/observe/trace_projection_test.exs` | ❌ W0 | ⬜ pending |
| 01-01-* | 01-01 | 1 | ORCH-LIVE-01 | T-01-03 | Broadcast before buffer cast | unit | `MIX_ENV=test mix test test/scoria/observe/telemetry_test.exs` | ❌ extend | ⬜ pending |
| 01-02-* | 01-02 | 2 | ORCH-LIVE-01 | T-01-04 | arguments_preview redacted in projection | unit | `MIX_ENV=test mix test test/scoria/workflows_test.exs` | ✅ extend | ⬜ pending |
| 01-02-* | 01-02 | 2 | ORCH-LIVE-01 | T-01-05 | not_pending + approval_decided fan-out | unit | targeted workflows approval tests | ✅ extend | ⬜ pending |
| 01-03-* | 01-03 | 3 | ORCH-LIVE-01 | T-01-06 | Real runtime → LiveView without send/2 | integration | `MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_integration_test.exs` | ❌ W0 | ⬜ pending |
| 01-03-* | 01-03 | 3 | ORCH-LIVE-01 | T-01-07 | Reconnect hydrate from DB | integration | same integration file | ❌ W0 | ⬜ pending |
| 01-03-* | 01-03 | 3 | ORCH-LIVE-01 | — | Semantic lane pin contract | contract | `MIX_ENV=test mix test test/mix/tasks/test.semantic_fast_path_test.exs` | ✅ extend | ⬜ pending |
| 01-03-* | 01-03 | 3 | ORCH-LIVE-01 | — | closeout_order unchanged | contract | `MIX_ENV=test mix test test/scoria/verification_lanes_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/scoria/observe/operator_broadcast_test.exs` — tenant drop + message shapes
- [ ] `test/scoria/observe/trace_projection_test.exs` — redaction + with_depths/1
- [ ] `test/scoria_web/live/orchestrator_live_integration_test.exs` — ORCH-LIVE-01 producer path
- [ ] Extend `test/scoria/observe/telemetry_test.exs` — broadcast-before-buffer ordering
- [ ] Extend `test/mix/tasks/test.semantic_fast_path_test.exs` — integration file pin

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Host session tenant_id contract | D-130 | Adoption doc fragment; host-specific auth | Verify adoption doc lists session keys |

*All core ORCH-LIVE-01 behaviors have automated verification targets.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
