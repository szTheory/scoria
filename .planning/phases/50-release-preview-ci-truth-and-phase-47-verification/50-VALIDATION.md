---
phase: 50
slug: release-preview-ci-truth-and-phase-47-verification
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-26
---

# Phase 50 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit plus bounded Mix task and markdown ledger checks |
| **Config file** | `mix.exs`, `.github/workflows/ci.yml`, `test/test_helper.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/scoria/package_surface_test.exs test/mix/tasks/scoria.release_preview_test.exs --trace` |
| **Full suite command** | `MIX_ENV=dev mix scoria.release_preview && MIX_ENV=test mix test test/scoria/package_surface_test.exs test/mix/tasks/scoria.release_preview_test.exs test/scoria/adoption_surface_test.exs --trace` |
| **Estimated runtime** | ~45-120 seconds depending on docs compilation |

---

## Sampling Rate

- **After every task commit:** Run the smallest focused verify command for the files just changed.
- **Fast interim smoke:** `MIX_ENV=test mix test test/mix/tasks/scoria.release_preview_test.exs test/scoria/package_surface_test.exs --trace`
- **After every plan wave:** Run `MIX_ENV=dev mix scoria.release_preview` plus the focused package/docs assertion suite.
- **Before `$gsd-verify-work`:** `MIX_ENV=dev mix scoria.release_preview` and the focused package/docs/source assertions must be green.
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 50-01-01 | 01 | 1 | ADPT-03 / ADPT-04 | T-50-01 | CI runs the bounded release-preview lane in its supported env instead of inheriting `MIX_ENV=test` drift. | source | `rg -n "Run release preview lane|MIX_ENV=dev mix scoria.release_preview" .github/workflows/ci.yml` | ✅ | ⬜ pending |
| 50-01-02 | 01 | 1 | ADPT-03 / ADPT-04 | T-50-02 | Public support docs and source assertions keep the canonical maintainer command as plain `mix scoria.release_preview`, not `MIX_ENV=test ...`. | unit/source | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs --trace` | ✅ | ⬜ pending |
| 50-02-01 | 02 | 2 | ADPT-03 / ADPT-04 | T-50-03 / T-50-04 | Phase 47 verification is rebuilt from fresh bounded proof in the corrected lane. | task + package | `MIX_ENV=dev mix scoria.release_preview && MIX_ENV=test mix test test/scoria/package_surface_test.exs test/mix/tasks/scoria.release_preview_test.exs --trace` | ✅ | ⬜ pending |
| 50-02-02 | 02 | 2 | ADPT-03 / ADPT-04 | T-50-05 | `47-VERIFICATION.md` exists and records executable evidence for both requirements. | ledger | `test -f .planning/phases/47-release-packaging-and-docs-truth/47-VERIFICATION.md && rg -n "ADPT-03|ADPT-04|mix scoria.release_preview|package_surface_test|scoria.release_preview_test" .planning/phases/47-release-packaging-and-docs-truth/47-VERIFICATION.md` | ❌ W0 | ⬜ pending |
| 50-03-01 | 03 | 3 | ADPT-03 / ADPT-04 | T-50-06 | Milestone ledgers stop treating ADPT-03 and ADPT-04 as pending once Phase 47 verification exists. | ledger | `rg -n "ADPT-03|ADPT-04|Phase 50" .planning/REQUIREMENTS.md .planning/ROADMAP.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- [x] Existing ExUnit package/docs tests already cover the release-preview contract.
- [x] Existing CI workflow file provides the source seam for env-contract verification.
- [x] Existing verification-report format in later phases can be reused for `47-VERIFICATION.md`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Maintainer closeout wording still reads naturally after the env re-scope | ADPT-03 / ADPT-04 | The command contract is mechanical, but the explanation that CI runs the lane in `:dev` while the public command stays plain is partly editorial | Read `docs/operator_verification.md` after execution and confirm the closeout lane still scans as `mix scoria.release_preview` then `mix test.adoption`, without promoting `MIX_ENV=test mix scoria.release_preview` |

---

## Validation Sign-Off

- [x] All tasks have directly runnable `<automated>` verify commands
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] No `MISSING` verify placeholders remain
- [x] No watch-mode flags
- [x] Feedback latency target is <= 120s for the bounded docs/package lane
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
