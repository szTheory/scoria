---
phase: 59
slug: planner-contract-foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-27
---

# Phase 59 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (mix test) |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/mix/tasks/scoria.install_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~120 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/mix/tasks/scoria.install_test.exs`
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 59-01-01 | 01 | 1 | INST-03 | — | `--dry-run` performs no host writes and returns deterministic ordered plan entries | integration | `mix test test/mix/tasks/scoria.install_test.exs` | ✅ | ⬜ pending |
| 59-01-02 | 01 | 1 | INST-05 | — | every managed surface is classified as `create`/`update`/`no-op`/`manual-review` with rationale and target path | integration | `mix test test/mix/tasks/scoria.install_test.exs` | ✅ | ⬜ pending |
| 59-02-01 | 02 | 2 | INST-04 | — | `--check` maps compliant/unsafe/error scenarios to stable exit codes `0/1/2` and emits stable trailer line | integration | `mix test test/mix/tasks/scoria.install_test.exs` | ✅ | ⬜ pending |
| 59-02-02 | 02 | 2 | INST-03, INST-04, INST-05 | — | planner/check contract remains truthful without regressing existing installer/adoption reliability tests | full-suite | `mix test` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Human summary readability and remediation clarity for operator output | INST-04, INST-05 | Tone and actionability are subjective and best reviewed with sample output fixtures | Run `mix scoria.install --dry-run` and `mix scoria.install --check` against fixture apps, review grouped output order and remediation language for clarity/accuracy |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
