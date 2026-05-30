---
phase: 01
slug: orchestrator-live-wiring-runtime-pubsub-trace-broadcast-and-
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-30
validated: 2026-05-30
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
| 01-01-* | 01-01 | 1 | ORCH-LIVE-01 | T-01-01 | Drop broadcast when tenant_id missing | unit | `MIX_ENV=test mix test test/scoria/observe/operator_broadcast_test.exs` | ✅ | ✅ green |
| 01-01-* | 01-01 | 1 | ORCH-LIVE-01 | T-01-02 | Redacted span_view previews only | unit | `MIX_ENV=test mix test test/scoria/observe/trace_projection_test.exs` | ✅ | ✅ green |
| 01-01-* | 01-01 | 1 | ORCH-LIVE-01 | T-01-03 | Broadcast before buffer cast | unit | `MIX_ENV=test mix test test/scoria/observe/telemetry_test.exs` | ✅ | ✅ green |
| 01-02-* | 01-02 | 2 | ORCH-LIVE-01 | T-01-04 | arguments_preview redacted in projection | unit | `MIX_ENV=test mix test test/scoria/workflows/remote_approval_projection_test.exs` | ✅ | ✅ green |
| 01-02-* | 01-02 | 2 | ORCH-LIVE-01 | T-01-05 | not_pending + approval_decided fan-out | unit | `MIX_ENV=test mix test test/scoria/observe/operator_broadcast_test.exs test/scoria/workflows_test.exs` | ✅ | ✅ green |
| 01-03-* | 01-03 | 3 | ORCH-LIVE-01 | T-01-06 | Real runtime → LiveView without send/2 | integration | `MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_integration_test.exs` | ✅ | ✅ green |
| 01-03-* | 01-03 | 3 | ORCH-LIVE-01 | T-01-07 | Reconnect hydrate from DB | integration | same integration file | ✅ | ✅ green |
| 01-03-* | 01-03 | 3 | ORCH-LIVE-01 | — | Semantic lane pin contract | contract | `MIX_ENV=test mix test test/mix/tasks/test.semantic_fast_path_test.exs` | ✅ | ✅ green |
| 01-03-* | 01-03 | 3 | ORCH-LIVE-01 | — | closeout_order unchanged | contract | `MIX_ENV=test mix test test/scoria/verification_lanes_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/scoria/observe/operator_broadcast_test.exs` — tenant drop + message shapes
- [x] `test/scoria/observe/trace_projection_test.exs` — redaction + with_depths/1
- [x] `test/scoria_web/live/orchestrator_live_integration_test.exs` — ORCH-LIVE-01 producer path
- [x] Extend `test/scoria/observe/telemetry_test.exs` — broadcast-before-buffer ordering
- [x] Extend `test/mix/tasks/test.semantic_fast_path_test.exs` — integration file pin

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Host session tenant_id contract | D-130 | Adoption doc fragment; host-specific auth | Verify adoption doc lists session keys |

*All core ORCH-LIVE-01 behaviors have automated verification targets.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-05-30

---

## Validation Audit 2026-05-30

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

**Evidence:** All mapped test files exist. Wave 1–3 commands run green (16 + 24 + 10 tests, 0 failures). Wave 0 checklist complete. One manual-only item (D-130 adoption doc) remains by design.
