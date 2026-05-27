---
phase: 66
slug: baseline-expiry-and-inventory
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-27
---

# Phase 66 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via `mix test` |
| **Config file** | `mix.exs` (existing) |
| **Quick run command** | `MIX_ENV=test mix test test/scoria/warning_baseline_test.exs` |
| **Policy + lanes command** | `MIX_ENV=test mix test test/scoria/verification_lanes_test.exs test/scoria/ci_policy_contract_test.exs` |
| **Full suite command** | `MIX_ENV=test mix test` |
| **Estimated runtime** | ~30s quick; ~3–5min full (inventory smoke excluded from CI) |

---

## Sampling Rate

- **After every task commit:** Run task `<automated>` verify from PLAN.md
- **After wave 1:** `mix test test/scoria/warning_baseline_test.exs` + `mix scoria.warning_baseline.check`
- **After wave 2:** Read `.github/workflows/ci.yml` + policy contract tests + `mix compile --warnings-as-errors`
- **Before `/gsd-verify-work`:** Full `mix test` green (inventory smoke optional, tagged)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------|-------------------|--------|
| 66-01-01 | 01 | 1 | WARN-03 | unit | `mix test test/scoria/warning_baseline_test.exs` | ⬜ pending |
| 66-01-02 | 01 | 1 | WARN-03 | unit | `mix scoria.warning_baseline.check --date 2026-06-08` (fixture) | ⬜ pending |
| 66-02-01 | 02 | 2 | WARN-03 | contract | `mix test test/scoria/ci_policy_contract_test.exs` | ⬜ pending |
| 66-02-02 | 02 | 2 | WARN-03 | integration | `mix scoria.warning_baseline.check` (live baseline) | ⬜ pending |
| 66-03-01 | 03 | 2 | WARN-04 | unit | `mix test test/scoria/warning_inventory/` | ⬜ pending |
| 66-03-02 | 03 | 2 | WARN-04 | unit | `mix scoria.warning_inventory --format table` (no --write in CI) | ⬜ pending |

---

## Wave 0 Requirements

Existing ExUnit + Mix infrastructure covers all phase requirements. No new framework install.

- [x] `test/support` compiled in `:test` — reuse for fixture stderr snippets

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Full-suite inventory reproducibility | WARN-04 | Runtime + DB; merge churn if in CI | Run `MIX_ENV=test mix scoria.warning_inventory --write --scope full` locally; commit baseline JSON + INVENTORY.md once counts stable |
| Policy job in GHA | WARN-03 | Needs Actions runner | Push PR; confirm `policy` passes before `test` starts |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 N/A — existing infrastructure
- [x] No watch-mode flags
- [ ] Feedback latency validated at execute time

**Approval:** pending execute
