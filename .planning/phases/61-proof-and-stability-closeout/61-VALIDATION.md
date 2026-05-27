---
phase: 61
slug: proof-and-stability-closeout
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-27
---

# Phase 61 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (mix test) |
| **Config file** | `mix.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/scoria/install/report_test.exs` |
| **Installer proof command** | `MIX_ENV=test mix test test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.install_check_test.exs` |
| **Adoption lane command** | `MIX_ENV=test mix test.adoption` |
| **Closeout chain command** | See D-22 in `61-CONTEXT.md` |
| **Estimated runtime** | ~120 seconds (scoped); ~180 seconds (adoption lane) |

---

## Sampling Rate

- **After every task commit:** Run task-level `<automated>` command from PLAN.md
- **After Plan 61-01:** `MIX_ENV=test mix test test/scoria/install/report_test.exs`
- **After Plan 61-02:** `MIX_ENV=test mix test test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.install_check_test.exs`
- **After Plan 61-03:** Full v2.4 closeout chain (D-22)
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 61-01-01 | 01 | 1 | INST-08 | T-61-01 | Operator projection never mislabels `manual_review` as actionable write bucket. | unit | `MIX_ENV=test mix test test/scoria/install/report_test.exs` | ❌ W0 | ⬜ pending |
| 61-01-02 | 01 | 1 | INST-08 | T-61-02 | JSON adds `summary_operator` additively; planner summary keys unchanged; schema_version string `"1.0"`. | unit | `MIX_ENV=test mix test test/scoria/install/report_test.exs` | ❌ W0 | ⬜ pending |
| 61-02-01 | 02 | 2 | INST-08 | T-61-03 | Shared fixture harness replaces duplicate builders; six fixture classes build successfully. | integration | `MIX_ENV=test mix test test/mix/tasks/scoria.install_check_test.exs` | ❌ W0 | ⬜ pending |
| 61-02-02 | 02 | 2 | INST-08 | T-61-04 | dry_run/check plan bodies identical; B-cycle proves idempotency with zero preview writes. | integration | `MIX_ENV=test mix test test/mix/tasks/scoria.install_test.exs` | ✅ | ⬜ pending |
| 61-02-03 | 02 | 2 | INST-08 | T-61-05 | optional_surface_absent → skipped operator count; tri-state trailers unchanged. | integration | `MIX_ENV=test mix test test/mix/tasks/scoria.install_check_test.exs` | ✅ | ⬜ pending |
| 61-03-01 | 03 | 3 | INST-08 | — | Docs and adoption pins match Install.Contract SSOT. | integration | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs` | ✅ | ⬜ pending |
| 61-03-02 | 03 | 3 | INST-08 | — | v2.4 closeout chain green; VerificationLanes order unchanged. | integration | `MIX_ENV=test mix test test/scoria/verification_lanes_test.exs && MIX_ENV=test mix test.adoption` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/scoria/install/report_test.exs` — projection unit tests for Plan 61-01
- [ ] `test/support/scoria/host_install_fixtures.ex` — shared harness for Plan 61-02

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Optional full-suite smoke | D-23 | Not a Phase 61 gate | Run `mix test` and classify failures via `.planning/WARNING-BASELINE.md` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 180s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
