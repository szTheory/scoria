---
phase: 10
slug: wire-production-sre-telemetry-and-fix-default-verification-bootstrap
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-12
---

# Phase 10 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix test runner |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/scoria/sre/telemetry_test.exs -x` |
| **Full suite command** | `MIX_ENV=test mix test` for the core lane, plus an explicit knowledge/full lane command or alias added by this phase |
| **Estimated runtime** | ~20 seconds |

---

## Sampling Rate

- **After every task commit:** Run the smallest smoke command for the touched seam, keeping the task-sampling slice under ~30 seconds.
- **After every plan wave:** Run the focused suite for that plan, then `MIX_ENV=test mix test` plus the explicit knowledge/full lane command once it exists.
- **Before `$gsd-verify-work`:** Both CI lanes must be green: core/SRE default and knowledge/full
- **Max feedback latency:** 20 seconds for task smoke, 30 seconds for plan-level smoke, with the full two-lane run deferred to wave close because it intentionally exercises the complete bootstrap contract

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 10-01-01 | 01 | 1 | SRE-04 | T-10-01-01 / T-10-01-02 | Canonical identity labels stay low-cardinality and keep correlation refs out of grouping keys | unit | `MIX_ENV=test mix test test/scoria/sre/telemetry_test.exs -x` | ✅ | ⬜ pending |
| 10-01-02 | 01 | 1 | SRE-04 | T-10-01-02 / T-10-01-03 | Runtime and MCP seams emit live telemetry from real execution outcomes | integration | `MIX_ENV=test mix test test/scoria/workflows/runtime_telemetry_test.exs test/scoria/mcp/executor_telemetry_test.exs -x` | ❌ W0 | ⬜ pending |
| 10-02-01 | 02 | 2 | SRE-04 | T-10-02-01 / T-10-02-02 | Incident lifecycle telemetry emits only after durable incident state commits and stays distinct from runtime telemetry | integration | `MIX_ENV=test mix test test/scoria/sre/incident_telemetry_test.exs -x` | ❌ W0 | ⬜ pending |
| 10-02-02 | 02 | 2 | SRE-04 | T-10-02-03 | Parapet translation preserves canonical labels/refs and namespace separation | unit | `MIX_ENV=test mix test test/scoria/sre/parapet_translation_test.exs -x` | ❌ W0 | ⬜ pending |
| 10-03-01 | 03 | 1 | SRE-08 | T-10-03-01 / T-10-03-02 | Lane-specific migration routing preserves compatibility for both fresh core-only and already-migrated knowledge environments | bootstrap + integration | `MIX_ENV=test mix test test/scoria/bootstrap/migration_lane_compatibility_test.exs -x` | ❌ W0 | ⬜ pending |
| 10-03-02 | 03 | 1 | SRE-08 | T-10-03-03 | Ordinary `mix test` uses the boring core-only bootstrap path while knowledge remains explicit | bootstrap | `MIX_ENV=test mix test test/scoria/sre_test.exs -x` | ✅ | ⬜ pending |
| 10-04-01 | 04 | 2 | SRE-08 | T-10-04-01 / T-10-04-02 | Backend default-lane suites stop using `ensure_*` schema patchwork | integration | `MIX_ENV=test mix test test/scoria/mcp/executor_test.exs test/scoria/workflows/integration_test.exs test/scoria/workflows/runtime_test.exs test/scoria/sre/audit_outbox_test.exs test/scoria/sre/incident_test.exs test/scoria/sre/relay_test.exs -x` | ✅ | ⬜ pending |
| 10-04-02 | 04 | 2 | SRE-08 | T-10-04-02 / T-10-04-03 | LiveView default-lane suites stop using local schema helpers and the explicit knowledge lane stays continuously proven without becoming the default path | integration | `MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_sre_test.exs test/scoria_web/live/orchestrator_live_test.exs -x && MIX_ENV=test mix test.knowledge` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Default core-lane bootstrap that migrates core/SRE schema without pgvector
- [ ] Explicit knowledge/full lane command or alias that checks/bootstrap pgvector before running knowledge migrations/tests
- [ ] Compatibility coverage for an environment where migration version `20260511000300` is already recorded
- [ ] Removal of remaining default-lane `ensure_*` DDL helpers from core/SRE and LiveView suites
- [ ] Runtime and MCP tests expanded to assert live SRE telemetry emission, not only business outcomes

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Review telemetry namespace naming and low-cardinality label shape for operator readability | SRE-04 | Automated tests can prove presence and metadata shape, but not whether the public seam reads clearly for downstream operators | Inspect emitted runtime and incident event names plus Parapet translation output after the focused telemetry suite passes |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [x] Task smoke feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
