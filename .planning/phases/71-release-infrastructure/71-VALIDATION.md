---
phase: 71
slug: release-infrastructure
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-28
---

# Phase 71 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix) |
| **Config file** | `mix.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/scoria/ci_policy_contract_test.exs` |
| **Full suite command** | `MIX_ENV=test mix scoria.test.ci_trust` |
| **Estimated runtime** | ~90–180 seconds (quick); ci_trust longer with Postgres |

---

## Sampling Rate

- **After every task commit:** Run quick run command
- **After every plan wave:** Run full suite command when CI/workflow files changed
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 71-01-01 | 01 | 1 | HEX-02 | — | N/A | unit | `rg 'Planning milestones vs Hex releases' CHANGELOG.md` | ✅ | ⬜ pending |
| 71-01-02 | 01 | 1 | HEX-02 | — | N/A | unit | `rg 'CHANGELOG.md' mix.exs` | ✅ | ⬜ pending |
| 71-02-01 | 02 | 2 | HEX-01 | T-71-01 | CI verify reusable before publish paths | integration | `MIX_ENV=test mix test test/scoria/ci_policy_contract_test.exs` | ❌ W0 | ⬜ pending |
| 71-02-02 | 02 | 2 | HEX-01 | T-71-01 | release-please branches trigger CI | integration | `rg 'release-please--' .github/workflows/ci.yml` | ❌ W0 | ⬜ pending |
| 71-03-01 | 03 | 3 | HEX-01 | T-71-02 | publish job disabled Phase 71 | integration | `rg 'if: false' .github/workflows/release-please.yml` | ❌ W0 | ⬜ pending |
| 71-03-02 | 03 | 3 | HEX-01 | T-71-02 | hex-publish calls ci-verify | integration | `rg 'ci-verify.yml' .github/workflows/hex-publish.yml` | ❌ W0 | ⬜ pending |
| 71-04-01 | 04 | 4 | HEX-01/02 | T-71-03 | HEX_API_KEY documented, not in README body | unit | `rg 'HEX_API_KEY' docs/operator_verification.md` | ✅ | ⬜ pending |
| 71-04-02 | 04 | 4 | HEX-01 | T-71-04 | Gate-zero attestation or waiver | manual | See 71-VERIFICATION.md checklist | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `.github/workflows/ci-verify.yml` — reusable policy + test jobs (plan 02)
- [ ] `test/scoria/ci_policy_contract_test.exs` — assertions updated for ci-verify SSOT
- [ ] `.github/workflows/release-please.yml` — release-please + stubbed publish (plan 03)
- [ ] `.github/workflows/hex-publish.yml` — manual recovery with verify (plan 03)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Release PR version target 0.1.0 | HEX-01 prep | Requires GitHub after merge to main | Open Release PR; confirm title/body targets 0.1.0; do not merge |
| Workflow permissions | HEX-01 prep | GitHub repo settings API | Run `gh api` workflow permissions per CONTEXT D-17 |
| Remote CI gate-zero | ROADMAP #5 | Needs GitHub Actions run URL | Record in `71-VERIFICATION.md` or file waiver D-24 |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 180s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
