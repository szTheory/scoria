---
phase: 72
slug: hex-publish-closeout
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-28
---

# Phase 72 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix) |
| **Config file** | `mix.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/scoria/ci_policy_contract_test.exs test/scoria/package_surface_test.exs` |
| **Full suite command** | `MIX_ENV=test mix scoria.test.ci_trust` |
| **Estimated runtime** | ~90–180 seconds (quick); ci_trust longer with Postgres |

---

## Sampling Rate

- **After every task commit:** Run quick run command when Elixir/workflow/docs under test change
- **After every plan wave:** Run full suite when `.github/workflows/*` changed
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 72-01-01 | 01 | 1 | HEX-01 | T-72-01 | @version shape for publish grep | unit | `rg '@version \"0\\.1\\.0\"' mix.exs` | ❌ W0 | ⬜ pending |
| 72-01-02 | 01 | 1 | HEX-01 | T-72-02 | publish jobs enabled + dry-run steps | integration | `MIX_ENV=test mix test test/scoria/ci_policy_contract_test.exs` | ❌ W0 | ⬜ pending |
| 72-01-03 | 01 | 1 | HEX-01 | T-72-03 | Integration PR remote CI attestation | manual | Record URL in `72-VERIFICATION.md` | ❌ W0 | ⬜ pending |
| 72-02-01 | 02 | 2 | HEX-01 | T-72-04 | Hex lists 0.1.0 | manual | `curl -fsS https://hex.pm/api/packages/scoria/releases/0.1.0` | ❌ W0 | ⬜ pending |
| 72-02-02 | 02 | 2 | HEX-01 | T-72-04 | Publish workflow evidence | manual | `72-VERIFICATION.md` publish section | ❌ W0 | ⬜ pending |
| 72-03-01 | 03 | 3 | HEX-02 | T-72-05 | Hex-primary README + refute dual deps | unit | `MIX_ENV=test mix test test/scoria/package_surface_test.exs` | ✅ | ⬜ pending |
| 72-03-02 | 03 | 3 | HEX-02 | T-72-05 | release-as removed post-ship | integration | `rg 'release-as' release-please-config.json` → no match | ❌ W0 | ⬜ pending |
| 72-03-03 | 03 | 3 | HEX-02 | — | Operator post-publish appendix | unit | `rg 'Post-publish registry checks' docs/operator_verification.md` | ✅ | ⬜ pending |
| 72-04-01 | 04 | 4 | HEX-01/02 | — | Milestone audit artifact | unit | `test -f .planning/milestones/v2.7-MILESTONE-AUDIT.md` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `mix.exs` — `@version` module attribute + `docs/0` without version param (plan 01)
- [ ] `.github/workflows/release-please.yml` — enabled `publish-hex` (plan 01)
- [ ] `.github/workflows/hex-publish.yml` — enabled `publish` (plan 01)
- [ ] `test/scoria/ci_policy_contract_test.exs` — Phase 72 enabled-publish assertions (plan 01)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| HEX_API_KEY + workflow permissions | HEX-01 | GitHub secrets/settings | `gh secret set HEX_API_KEY`; `gh api` workflow permissions per CONTEXT D-72-08 |
| Release PR review 0.1.0 | HEX-01 | Human gate before merge | Confirm Release PR targets 0.1.0 only; CI green on `release-please--**` |
| Remote ci-verify on publish commit | HEX-01 | GitHub Actions | Record policy + test job green URL/SHA in `72-VERIFICATION.md` (non-waivable) |
| Hex registry 0.1.0 | HEX-01 | External API | `curl` hex.pm release; smoke deps.get in clean project |
| README flip timing | HEX-02 | Registry must exist first | Do not merge 72-03 until 72-02 must_haves satisfied |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 180s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
