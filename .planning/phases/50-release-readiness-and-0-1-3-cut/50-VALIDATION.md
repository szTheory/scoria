---
phase: 50
slug: release-readiness-and-0-1-3-cut
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-10
---

# Phase 50 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (`mix test`) + Playwright `@playwright/test` (browser e2e) |
| **Config file** | `test/test_helper.exs` (ExUnit); `priv/dev/e2e/playwright.config.mjs` (Playwright) |
| **Quick run command** | `MIX_ENV=test mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs` |
| **Full suite command** | `mix ci` (local merge-gate reproduction; see `guides/maintainers.md`) |
| **Estimated runtime** | ~30–60s (focused policy lane); e2e adds a dev-server boot + seed |

---

## Sampling Rate

- **After every task commit:** Run the focused policy-lane command (REL-01 fixes) or `mix scoria.ui.e2e --base-url http://localhost:4799/scoria` (REL-02 fixes).
- **After every plan wave:** Run `mix ci` locally, then push and let `ci-verify.yml` + `ci.yml`'s `e2e` job run in full.
- **Before `/gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** ~60s (focused lane); e2e bounded by dev-server boot + seed.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 50-01-xx | 01 | 1 | REL-01 | — | Docs-contract paths point at canonical `guides/`; `v2.15` breadcrumb present | unit/contract | `MIX_ENV=test mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs` | ✅ | ⬜ pending |
| 50-02-xx | 02 | 1 | REL-02 | T-50 (V4, incidental) | Seed uses `start_release_workflow/3` w/ explicit `tenant_id`; seeded IA/incident/eval/approval evidence renders; theme toggle clickable at desktop width | e2e (Playwright) | `mix scoria.ui.e2e --base-url http://localhost:4799/scoria` | ✅ | ⬜ pending |
| 50-03-xx | 03 | 1 | REL-03 | — | No stale `0.1.1` guidance outside historical CHANGELOG; `0.1.2` live / `0.1.3` target stated | unit/contract | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs` | ✅ | ⬜ pending |
| 50-04-xx | 04 | 2 | REL-04 | Manual publish bypass (mitigated by existing `gate-ci-green`) | `ci-gate` green on PR #12; Hex lists `0.1.3`; post-publish smoke proves fresh install + upgrade | contract + live CI + registry | `MIX_ENV=dev mix scoria.release_preview`; `gh pr checks 12`; `SCORIA_REGISTRY_VERSION=0.1.3 mix scoria.post_publish_smoke` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*
*Task IDs are placeholders until the planner assigns final numbering.*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements.* This phase repairs existing tests/fixtures/contracts rather than adding new coverage, per its "no large test-harness rewrites" scope fence (CONTEXT.md). The only optional new coverage (Claude's Discretion) is one focused regression test pinning the `dev_seed.exs` call-site arity fix — not required if existing e2e specs are judged sufficient.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Hex lists `0.1.3` after publish | REL-04 | Requires a real publish through the release-please → publish-hex chain; cannot run pre-merge | After merge + tag, confirm `curl https://hex.pm/api/packages/scoria/releases/0.1.3` returns the release, then run `SCORIA_REGISTRY_VERSION=0.1.3 mix scoria.post_publish_smoke`; capture workflow/run URL or ID in closeout state (D-04). |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (none — existing infra covers all)
- [x] No watch-mode flags
- [x] Feedback latency < 60s (focused lane)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-07-10 (plan-checker cross-verified per-task verify commands against live repo state)
