---
phase: 69
slug: ci-trust-and-milestone-closeout
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-27
---

# Phase 69 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix test) |
| **Config file** | `mix.exs` test aliases |
| **Quick run command** | `mix scoria.test.ci_trust --fast` |
| **Full suite command** | `mix scoria.test.ci_trust` |
| **Estimated runtime** | ~30 seconds (fast); ~10 minutes (full, ratchet subprocess) |

---

## Sampling Rate

- **After every task commit:** Run `mix scoria.test.ci_trust --fast`
- **After every plan wave:** Run `mix scoria.test.ci_trust` + `mix scoria.warning_baseline.check`
- **Before phase closeout:** Full trust bundle green; remote CI attestation via required `CI` status on `origin/main`
- **Max feedback latency:** 90 seconds (fast mode)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 69-00-01 | 00 | 0 | CI-03 | T-69-01 / — | Operator doc contains CI gate map without contradicting ci.yml | doc+contract | `mix scoria.test.ci_trust --fast` | ✅ | ✅ green |
| 69-00-02 | 00 | 0 | CI-03 | — | ci.yml header comments present | contract | `mix scoria.test.ci_trust --fast` | ✅ | ✅ green |
| 69-00-03 | 00 | 0 | CI-03 | — | README links operator CI gate map | contract | `mix scoria.test.ci_trust --fast` | ✅ | ✅ green |
| 69-00-04 | 00 | 0 | CI-03 | — | REQUIREMENTS CI-03 text matches D-08 | contract | `mix scoria.test.ci_trust --fast` | ✅ | ✅ green |
| 69-01-01 | 01 | 1 | CI-03 | T-69-02 | ratchet.test uses ensure_clean_tmp! + after cleanup | integration | `mix scoria.test.ci_trust` | ✅ | ✅ green |
| 69-01-02 | 01 | 1 | CI-03 | — | Subprocess ratchet check/test integration | integration | `mix scoria.test.ci_trust` | ✅ | ✅ green |
| 69-02-01 | 02 | 2 | CI-03 | — | 69-VERIFICATION.md traceability table present | contract | `mix scoria.test.ci_trust --fast` | ✅ | ✅ green |
| 69-02-02 | 02 | 2 | CI-03 | — | v2.6 milestone audit artifact present | contract | `mix scoria.test.ci_trust --fast` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No new test framework install.

- [x] `test/scoria/ci_policy_contract_test.exs` — CI order + doc + planning contracts
- [x] `test/scoria/warning_inventory/tmp_preflight_test.exs` — tmp hygiene + ratchet subprocess
- [x] `mix scoria.test.ci_trust` — maintainer bundle (fast + full)

---

## Ceremony (not UAT)

| Behavior | Requirement | Automation |
|----------|-------------|------------|
| Remote CI on origin/main | CI-03 | Required green `CI` status check (branch protection) |
| Thread archive | CI-03 | `mix scoria.milestone.archive_thread warning-ratchet-followup` |
| Milestone closeout | v2.6 | `/gsd-complete-milestone v2.6` (user-initiated per D-21) |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 90s (fast mode)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** automated contract suite
