---
phase: 64
slug: adoption-lane-discoverability-sync
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-27
---

# Phase 64 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix) |
| **Config file** | `mix.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/mix/tasks/test.adoption_test.exs` |
| **Full suite command** | `MIX_ENV=test mix test.adoption && MIX_ENV=test mix test test/scoria/verification_lanes_test.exs` |
| **Estimated runtime** | ~15–90 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick run command
- **After plan wave:** Run full suite command
- **Before `/gsd-verify-work`:** Full suite command must be green
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 64-01-01 | 01 | 1 | INST-08 | — | Discoverability list matches lane SSOT | integration | `MIX_ENV=test mix test test/mix/tasks/test.adoption_test.exs` | ✅ | ⬜ pending |
| 64-01-02 | 01 | 1 | INST-08 | — | Adoption lane runtime unchanged | integration | `MIX_ENV=test mix test.adoption` | ✅ | ⬜ pending |
| 64-01-03 | 01 | 1 | INST-08 | — | Closeout lane order registry unchanged | unit | `MIX_ENV=test mix test test/scoria/verification_lanes_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements — no Wave 0.*

---

## Manual-Only Verifications

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
