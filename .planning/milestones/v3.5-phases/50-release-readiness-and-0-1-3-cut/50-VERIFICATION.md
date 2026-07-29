---
phase: 50-release-readiness-and-0-1-3-cut
verified: 2026-07-11T18:16:30Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
reverified: 2026-07-11T18:16:30Z
gaps: []
---

# Phase 50: Release Readiness and 0.1.3 Cut — Verification Report

**Phase Goal:** Release readiness and 0.1.3 cut — policy/e2e release blockers fixed, stale version refs corrected, GREEN release PR, Hex publish, and post-publish smoke.
**Verified:** 2026-07-11 (re-verified after gap-closure train 50-05..50-11 + release cut)
**Status:** passed
**Re-verification:** Yes — initial verification (2026-07-10) found REL-04 blocked; this re-verification confirms all 5 truths after the gap-closure train and the live 0.1.3 release cut.

> **Re-verification note (2026-07-11T18:16Z):** The initial 2026-07-10 report below scored 3/5 with REL-04 blocked by ~30 Phase 46-49 verify-lane failures (Buckets A-G). Those buckets were closed by plans 50-05..50-11 (PR #12 reached `ci-gate` CLEAN). This session then cut the release: PR #12 squash-merged (`b904c22a`) → Release Please tagged `v0.1.3` + published the GitHub Release → "Publish to Hex.pm" job success → hex.pm lists 0.1.3 (HTTP 200, `has_docs`, full requirements) → "Post-publish registry attest" job SUCCESS (run 29162646314, completed/success). Truths 4 and 5 are now VERIFIED. The original findings are retained verbatim below as the historical record.

## Goal Achievement

The phase goal is **fully achieved**. The three release-*blocker-repair* requirements (REL-01 policy lane, REL-02 e2e lane, REL-03 version/docs truth) were met at initial verification. The gap-closure train (50-05..50-11) then closed the ~30 Phase 46-49 verify-lane failures that had blocked the release, PR #12 reached green `ci-gate`, and the release *cut* itself (REL-04) completed this session: `v0.1.3` is merged, tagged, published, listed on Hex (HTTP 200), and the post-publish registry attest passed.

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Policy lane no longer fails on planning-ledger drift; v2.15 Connector Adoption Lane breadcrumb preserved (REL-01, SC1) | ✓ VERIFIED | `ci_policy_contract_test.exs` `@maintainer_docs`/`@operator_docs` = `guides/maintainers.md`; no `docs/*.md` canonical refs remain; `guides/maintainers.md:128` carries `## Hex release & recovery {: #hex-release--recovery-maintainers}`. Ground truth: 58/0 policy lane green. Commits 51461be5, 25ad5233, c809241c present. 50-01-SUMMARY.md. |
| 2 | Browser e2e regressions from PR #12 fixed (hidden theme-toggle, modal focus, orientation) (REL-02, SC2) | ✓ VERIFIED | `dev_seed.exs:960,1048` call arity-3 tenant-scoped `start_release_workflow(..., tenant_id: tenant_id)`; `phase16_parity.spec.mjs` has 4 `.filter({ visible: true })` locators. Ground truth: full `mix scoria.ui.e2e` 165/0. Commits 7a24315, 75ee88a present. 50-02-SUMMARY.md. |
| 3 | Version references (README, maintainer docs, release automation, package metadata) reflect live 0.1.2 baseline / 0.1.3 target, no stale 0.1.1 (REL-03, SC3) | ✓ VERIFIED | No `docs/MAINTAINERS.md`/`docs/operator_verification.md` refs remain in `.github/workflows/`; no `SCORIA_REGISTRY_VERSION=0.1.1` in `scoria.post_publish_smoke.ex`; `mix.exs` `@hexdocs_url "https://scoria.hexdocs.pm"`, `@version "0.1.2"`. Ground truth: adoption_surface_test 29/0, `mix scoria.release_preview` exits 0. Commits 6692d93e, e151a502 present. 50-03-SUMMARY.md. |
| 4 | Release PR reaches green ci-gate and merges through release-please (REL-04, SC4) | ✓ VERIFIED | After gap-closure (50-05..50-11), PR #12 reached `ci-gate` CLEAN/MERGEABLE on head `be87badd`; squash-merged this session (merge commit `b904c22a`). Release Please tagged `v0.1.3` + published the GitHub Release; "Publish to Hex.pm" job success (run 29162646314). |
| 5 | Hex lists 0.1.3 and post-publish smoke proves fresh install + live-lineage upgrade (REL-04, SC5) | ✓ VERIFIED | `curl https://hex.pm/api/packages/scoria/releases/0.1.3` -> HTTP 200 (`has_docs`, full requirements), inserted 18:10:45Z. "Post-publish registry attest / Registry consumer" job SUCCESS (run 29162646314, completed/success) — the canonical fresh-install + live-lineage consumer proof. |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `test/scoria/ci_policy_contract_test.exs` | Docs constants repointed to `guides/maintainers.md` | ✓ VERIFIED | Both constants + README-link assertions repointed; no docs/*.md canonical refs |
| `guides/maintainers.md` | Restored maintainer content + Hex-release anchor | ✓ VERIFIED | `## Hex release & recovery {: #hex-release--recovery-maintainers}` at L128; content restored |
| `priv/repo/dev_seed.exs` | Arity-3 tenant-scoped `start_release_workflow` at both sites | ✓ VERIFIED | Lines 960, 1048 pass `tenant_id: tenant_id` |
| `priv/dev/e2e/phase16_parity.spec.mjs` | Visible-locator theme-toggle fix | ✓ VERIFIED | 4 `.filter({ visible: true })` sites |
| `.github/workflows/*.yml`, `scoria.post_publish_smoke.ex`, `mix.exs` | Stale-ref/version polish | ✓ VERIFIED | No stale docs/*.md comments, no 0.1.1, subdomain HexDocs URL, @version 0.1.2 |
| `.planning/STATE.md` (50-04 closeout: publish run URL/ID per D-04) | Post-publish evidence recorded | ✓ VERIFIED | Release published this session; evidence: Release Please run 29162646314 (Publish to Hex.pm + Post-publish registry attest both success), merge commit `b904c22a`, Hex 0.1.3 HTTP 200. |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| REL-01 | 50-01 | Policy lane no longer fails on ledger drift; v2.15 breadcrumb preserved | ✓ SATISFIED | Truth 1; 58/0 policy lane |
| REL-02 | 50-02 | e2e lane no longer fails on browser regressions | ✓ SATISFIED | Truth 2; 165/0 e2e lane |
| REL-03 | 50-03 | Version refs reflect 0.1.2/0.1.3, no stale 0.1.1 | ✓ SATISFIED | Truth 3; 29/0 adoption surface |
| REL-04 | 50-04 | 0.1.3 PR green, Hex publish, post-publish smoke | ✓ SATISFIED | Truths 4-5; PR #12 merged (`b904c22a`), Hex 0.1.3 HTTP 200, post-publish attest success (run 29162646314) |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Hex lists 0.1.3 | `curl -sw '%{http_code}' https://hex.pm/api/packages/scoria/releases/0.1.3` | 200 | ✓ PASS (published this session, `has_docs`, full requirements) |
| Task commits exist | `git cat-file -t <7 hashes>` | all FOUND | ✓ PASS |
| REL-01/02/03 code state matches SUMMARYs | grep of test/seed/workflow/mix files | all match | ✓ PASS |

Note: verify-lane CI results (~30 failures) are taken as ground truth from the parent session (run 29137880790) and the located, reproduced-locally inventory in 50-CI-GAP-INVENTORY.md — CI was NOT re-run per instruction.

### Anti-Patterns Found

None in the Phase-50-modified files. The ~30 failing tests are in the Phase 46-49 surface (docs/guide restructure fallout), not in files this phase touched. No unreferenced TBD/FIXME/XXX debt markers introduced by Phase 50.

### Human Verification Required

None as a status driver — the outstanding work is a concrete, code-level gap (REL-04), not an unverifiable judgment call. REL-04's remaining maintainer steps (merge PR #12, authorize Hex publish, run post-publish smoke) are gated behind fixing the ~30 CI failures first and are captured as gap-closure work, not human-verify items.

### Gaps Summary

Wave 1 (REL-01/02/03) fully delivered and confirmed in the codebase: the two original PR #12 blockers (policy docs-contract drift, e2e seed arity + theme-toggle) are fixed, and the version/docs-truth polish is consistent. **REL-04 is the single blocking gap.** Pushing the local-only v3.5 milestone to `origin/main` ran Phases 46-49 through CI for the first time, exposing ~30 pre-existing verify-lane failures (chiefly Bucket A: `*_example_source_test.exs`/`support_journey_source_test.exs` still reading `docs/*.md` stubs whose SSOT content Phase 48 moved to `guides/`; plus Buckets B-F: package surface, runtime/LiveView contracts, UI/dev-lab contracts, SupportCopilot journeys, warning inventory). `ci-gate` is RED, so no merge, no `v0.1.3` tag, and Hex returns 404 for `0.1.3`. These failures are release-blocking but are Phase 46-49 verification debt, not Phase 50 regressions.

**Resume path (COMPLETED 2026-07-11):** the gap-closure train (50-05..50-11) closed Buckets A-G, PR #12 reached green `ci-gate`, and the release was cut this session — PR #12 squash-merged, `v0.1.3` tagged + published, Hex 200, post-publish attest success. No further resume work remains.

**Phase marked complete.** REL-04 is satisfied; `0.1.3` is live on Hex with a passing post-publish registry attest.

---

_Initial verification: 2026-07-10 (3/5, REL-04 blocked)_
_Re-verified: 2026-07-11T18:16Z (5/5, REL-04 satisfied — release cut this session)_
_Verifier: Claude (gsd-verifier / gsd-verify-work)_
