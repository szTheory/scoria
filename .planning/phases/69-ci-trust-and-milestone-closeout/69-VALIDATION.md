---
phase: 69
slug: ci-trust-and-milestone-closeout
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| **Quick run command** | `MIX_ENV=test mix test test/scoria/ci_policy_contract_test.exs test/scoria/warning_inventory/` |
| **Full suite command** | `MIX_ENV=test mix test test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs test/scoria/warning_inventory/` |
| **Estimated runtime** | ~30 seconds (quick); ~60 seconds (with verification_lanes) |

---

## Sampling Rate

- **After every task commit:** Run quick run command
- **After every plan wave:** Run full suite command + `mix scoria.warning_baseline.check`
- **Before `/gsd-verify-work`:** Contract tests green; human records remote CI green
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 69-00-01 | 00 | 0 | CI-03 | T-69-01 / — | Operator doc contains CI gate map without contradicting ci.yml | doc+contract | `MIX_ENV=test mix test test/scoria/ci_policy_contract_test.exs` | ✅ | ⬜ pending |
| 69-00-02 | 00 | 0 | CI-03 | — | ci.yml header comments present | grep | `rg -n "policy:" .github/workflows/ci.yml` | ✅ | ⬜ pending |
| 69-00-03 | 00 | 0 | CI-03 | — | README links operator CI gate map | grep | `rg "operator_verification" README.md` | ✅ | ⬜ pending |
| 69-00-04 | 00 | 0 | CI-03 | — | REQUIREMENTS CI-03 text matches D-08 | grep | `rg "Postgres-free policy job" .planning/REQUIREMENTS.md` | ✅ | ⬜ pending |
| 69-01-01 | 01 | 1 | CI-03 | T-69-02 | ratchet.test uses ensure_clean_tmp! + after cleanup | unit | `MIX_ENV=test mix test test/scoria/warning_inventory/tmp_preflight_test.exs` | ✅ | ⬜ pending |
| 69-01-02 | 01 | 1 | CI-03 | — | Subprocess ratchet check integration exercises real capture | integration | `MIX_ENV=test mix test test/scoria/warning_inventory/tmp_preflight_test.exs` | ✅ | ⬜ pending |
| 69-02-01 | 02 | 2 | CI-03 | — | 69-VERIFICATION.md traceability table present | file | `test -f .planning/phases/69-ci-trust-and-milestone-closeout/69-VERIFICATION.md` | ❌ W0 | ⬜ pending |
| 69-02-02 | 02 | 2 | CI-03 | — | v2.6 milestone audit artifact present | file | `test -f .planning/milestones/v2.6-MILESTONE-AUDIT.md` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No new test framework install.

- [x] `test/scoria/ci_policy_contract_test.exs` — CI order contracts
- [x] `test/scoria/warning_inventory/tmp_preflight_test.exs` — tmp hygiene contracts

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Remote GitHub Actions green | CI-03 | Requires push to origin | Push branch; confirm `CI` workflow green on GitHub; record URL/SHA in 69-VERIFICATION.md |
| Thread archive + complete-milestone | CI-03 | GSD ceremony workflows | Run `/gsd-complete-milestone v2.6` after audit review; archive thread per D-22 |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
