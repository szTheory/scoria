---
phase: 34
slug: real-time-operator-dashboards
status: executed
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-21
executed_on: 2026-05-21
verified_by_phase: 35-vanguard-verification-backfill
---

# Phase 34 — Validation Strategy

> Per-phase validation contract used as truthful proof input for the Phase 35 verification backfill.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `ExUnit` |
| **Config file** | `config/test.exs` |
| **Wave 1 quick run** | `MIX_ENV=test mix test test/scoria/orchestrator_test.exs test/scoria/eval/campaign_worker_test.exs test/scoria/eval/dashboard_projection_test.exs test/scoria/req/steps/resiliency_test.exs` |
| **Wave 2 quick run** | `MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_test.exs test/scoria/eval/dashboard_projection_test.exs test/scoria/req/steps/resiliency_test.exs` |
| **Wave 3 / phase-final quick run** | `MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_test.exs test/scoria/eval/dashboard_projection_test.exs test/scoria/eval/campaign_worker_test.exs test/scoria/req/steps/resiliency_test.exs` |
| **Full suite command** | `MIX_ENV=test mix test` |
| **Estimated runtime** | ~45-120 seconds |

---

## Sampling Rate

- After every task commit, run the task-local command from the owning plan.
- After Wave 1, run the Wave 1 quick run.
- After Wave 2, run the Wave 2 quick run.
- After Wave 3 / phase closeout, run the Wave 3 / phase-final quick run.
- Before `$gsd-verify-work`, the full suite must be green.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 34-01-01 | 01 | 1 | `OBS-01`, `OBS-02` | `T-34-01`, `T-34-02` | Traced orchestrator outcomes, fallback provenance, and dashboard projections match durable truth | unit + integration | `MIX_ENV=test mix test test/scoria/orchestrator_test.exs test/scoria/eval/campaign_worker_test.exs test/scoria/eval/dashboard_projection_test.exs test/scoria/req/steps/resiliency_test.exs` | ✅ | ✅ green |
| 34-01-02 | 01 | 1 | `OBS-01`, `OBS-02` | `T-34-01`, `T-34-04` | Migration and schemas persist fallback-aware eval truth without drift | unit + migration | `MIX_ENV=test mix test test/scoria/eval/campaign_worker_test.exs test/scoria/eval/dashboard_projection_test.exs && MIX_ENV=test mix ecto.migrate && MIX_ENV=test mix ecto.rollback --step 1 && MIX_ENV=test mix ecto.migrate` | ✅ | ✅ green |
| 34-01-03 | 01 | 1 | `OBS-01`, `OBS-02` | `T-34-03` | Campaign and model-health broadcasts are emitted from durable rollups and breaker-affecting request paths | integration | `MIX_ENV=test mix test test/scoria/eval/dashboard_projection_test.exs test/scoria/eval/campaign_worker_test.exs test/scoria/req/steps/resiliency_test.exs` | ✅ | ✅ green |
| 34-02-01 | 02 | 2 | `OBS-01`, `OBS-02` | `T-34-05`, `T-34-06` | `/scoria` renders summary strip, model matrix, and campaign board from tenant-scoped query APIs | liveview | `MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_test.exs` | ✅ | ✅ green |
| 34-02-02 | 02 | 2 | `OBS-02` | `T-34-05`, `T-34-06` | Model-health topic refresh rerenders the matrix from canonical query data, including `Unknown` rows | liveview | `MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_test.exs test/scoria/req/steps/resiliency_test.exs` | ✅ | ✅ green |
| 34-02-03 | 02 | 2 | `OBS-01` | `T-34-07` | Campaign board rows expose fallback counts and selection-only primary action | liveview | `MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_test.exs` | ✅ | ✅ green |
| 34-03-01 | 03 | 3 | `OBS-01` | `T-34-08`, `T-34-10` | Inline campaign detail shows fallback-aware target lineage and canonical terminal states | liveview | `MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_test.exs` | ✅ | ✅ green |
| 34-03-02 | 03 | 3 | `OBS-01`, `OBS-02` | `T-34-08`, `T-34-09` | Selection persists across live refreshes and stays tenant-scoped | liveview | `MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_test.exs test/scoria/eval/dashboard_projection_test.exs` | ✅ | ✅ green |
| 34-03-03 | 03 | 3 | `OBS-01`, `OBS-02` | `T-34-09`, `T-34-10` | Empty, partial, fatal, open, and unknown dashboard states remain operator-legible | liveview | `MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_test.exs test/scoria/eval/dashboard_projection_test.exs` | ✅ | ✅ green |

*Status: ✅ green · ❌ red*

---

## Automated Operator Closure

The primary Phase 34 proof package is:

1. `test/scoria/eval/dashboard_projection_test.exs`
   Proves durable campaign truth, configured-model coverage, unknown-health rows, and model-health detail payloads for the dashboard.
2. `test/scoria/req/steps/resiliency_test.exs` and `test/scoria/eval/campaign_worker_test.exs`
   Prove both real-time refresh triggers: breaker-affecting request paths and campaign rollup transitions.
3. `test/scoria_web/live/orchestrator_live_test.exs`
   Proves the operator-visible `/scoria` surface renders summary cards, matrix rows, campaign board, inline drill-in detail, and selection persistence.

---

## Validation Sign-Off

- [x] Current proof lanes use the supported `MIX_ENV=test` environment and do not rely on the stale database-port override
- [x] Dashboard proof commands remain explicit and requirement-aligned
- [x] The sign-off wording is compatible with backfilled verification usage
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** Executed during the Phase 35 verification-chain backfill on 2026-05-21. Canonical closure is recorded in `34-VERIFICATION.md`.
