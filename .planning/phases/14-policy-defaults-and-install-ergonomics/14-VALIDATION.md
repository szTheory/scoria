---
phase: 14
slug: policy-defaults-and-install-ergonomics
status: passed
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-14
updated: 2026-05-16
verified_by_phase: 17-re-verify-keystone-defaults-and-adoption-surface
---

# Phase 14 - Validation Strategy

> Terminal-truth validation ledger for the Phase 17 backfill completed on 2026-05-16.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `ExUnit` |
| **Config file** | `config/test.exs` |
| **Quick run command** | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/prompt_policy_test.exs test/scoria/runtime/defaults_test.exs test/scoria/runtime_test.exs test/scoria/runtime_integration_test.exs test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.install_route_smoke_test.exs test/scoria/bootstrap/migration_lane_compatibility_test.exs test/mix/tasks/scoria.test_knowledge_test.exs` |
| **Full suite command** | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test` |
| **Estimated runtime** | ~30-75 seconds |

---

## Sampling Rate

- **After every task commit:** Run the task-local command from the owning plan.
- **After every plan wave:** Run the Phase 14 quick run command.
- **Before `$gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** 90 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 14-01-01 | 01 | 1 | `POLY-01` | `T-14-01-*` | Prompt-policy edge input normalizes into one canonical public noun | unit | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/prompt_policy_test.exs` | ✅ | ✅ green |
| 14-01-02 | 01 | 1 | `POLY-01` | `T-14-01-*` | Baseline runtime defaults come from one boring app-facing config surface | unit | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/prompt_policy_test.exs test/scoria/runtime/defaults_test.exs` | ✅ | ✅ green |
| 14-02-01 | 02 | 2 | `POLY-01`, `POLY-02` | `T-14-02-*` | Identity-aware overlay precedence resolves exactly once and rejects unsafe widening | unit | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/runtime/defaults_test.exs test/scoria/runtime_test.exs` | ✅ | ✅ green |
| 14-02-02 | 02 | 2 | `POLY-02` | `T-14-02-*` | Resolved provider/model/policy metadata survives the public runtime path into downstream seams | integration | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/runtime_test.exs test/scoria/runtime_integration_test.exs` | ✅ | ✅ green |
| 14-03-01 | 03 | 3 | `POLY-03` | `T-14-03-*` | Installer wires the boring Phoenix core lane without optional knowledge dependencies and yields a working `/scoria` route | unit + integration | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.install_route_smoke_test.exs` | ✅ | ✅ green |
| 14-03-02 | 03 | 3 | `POLY-03` | `T-14-03-*` | Core and knowledge verification lanes stay explicit, separate, and repeatable | unit + integration | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.test_knowledge_test.exs test/scoria/bootstrap/migration_lane_compatibility_test.exs` | ✅ | ✅ green |

*Status: ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/scoria/prompt_policy_test.exs` - canonical prompt-policy normalization coverage
- [x] `test/scoria/runtime/defaults_test.exs` - baseline defaults and overlay-precedence coverage
- [x] `test/mix/tasks/scoria.install_route_smoke_test.exs` - installed `/scoria` route viability coverage
- [x] `test/mix/tasks/scoria.test_knowledge_test.exs` - explicit knowledge-lane command contract coverage
- [x] Existing runtime and installer integration tests reused where they already exercise the public path

---

## Automated Closure

The old bounded install-to-run walkthrough is now covered by executable seams:

1. `test/mix/tasks/scoria.install_test.exs`
   Proves `mix scoria.install` injects the default `/scoria` dashboard mount, Tailwind wiring, and baseline runtime config.
2. `test/mix/tasks/scoria.install_route_smoke_test.exs`
   Proves the installed router resolves both `/scoria` and `/scoria/workflows/:run_id`.
3. `test/scoria/runtime_integration_test.exs`
   Proves one real `Scoria.start_run/2` flow yields a durable `run_id`, runtime readback works, exact-run resume keeps the same `run_id`, and the operator page shows the same run/status.

Together these tests replace the former manual checkpoint with a repeatable CI-safe proof lane.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify commands
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 gaps are explicit and assigned to Plan 14-01 or 14-03
- [x] No watch-mode flags
- [x] Feedback latency target is under 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** targeted `POLY-01` through `POLY-03` defaults/install seams, the automated install-to-run/operator closure lane, and the secondary `SCORIA_DB_PORT=55432 MIX_ENV=test mix test` regression-hygiene pass completed on 2026-05-16.
