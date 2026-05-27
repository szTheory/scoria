---
phase: 60
slug: drift-classification-and-safe-apply
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-27
---

# Phase 60 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (mix test) |
| **Config file** | `mix.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.install_check_test.exs` |
| **Full suite command** | `MIX_ENV=test mix test` |
| **Estimated runtime** | ~180 seconds |

---

## Sampling Rate

- **After every task commit:** Run `MIX_ENV=test mix test test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.install_check_test.exs`
- **After every plan wave:** Run `MIX_ENV=test mix test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 60-01-01 | 01 | 1 | INST-07 | T-60-01 | Surface analyzers emit ownership/drift/remediation fields and force missing/ambiguous marker ownership into `manual_review` instead of auto-adopt. | integration | `MIX_ENV=test mix test test/scoria/install/planner_test.exs` | ✅ | ⬜ pending |
| 60-01-02 | 01 | 1 | INST-07, INST-06 | T-60-02 | Human and JSON report paths render the same remediation payload while preserving stable check trailer and exit semantics. | integration | `MIX_ENV=test mix test test/scoria/install/planner_test.exs test/mix/tasks/scoria.install_check_test.exs` | ✅ | ⬜ pending |
| 60-02-01 | 02 | 2 | INST-06, INST-07 | T-60-04, T-60-05 | Apply executes planner-typed operations only and blocks stale/manual-review plans with zero writes before any mutation dispatch. | integration | `MIX_ENV=test mix test test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.install_check_test.exs` | ✅ | ⬜ pending |
| 60-02-02 | 02 | 2 | INST-06, INST-07 | T-60-06 | Subprocess coverage keeps `0/1/2` exits and `SCORIA_CHECK_RESULT` trailer parse-stable while validating remediation reason-code parity. | integration | `MIX_ENV=test mix test test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.install_check_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Remediation steps are calm, specific, and operator-actionable in both human and JSON output. | INST-07 | Actionability and tone quality are easier to evaluate with realistic operator samples. | Run `mix scoria.install --check` and `mix scoria.install` against drift fixtures, review reason code summary, ordered remediation steps, and verify command clarity. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 180s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
