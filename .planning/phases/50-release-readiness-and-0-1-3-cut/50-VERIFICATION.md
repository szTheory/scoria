---
phase: 50-release-readiness-and-0-1-3-cut
verified: 2026-07-10T00:00:00Z
status: gaps_found
score: 3/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "The 0.1.3 release PR reaches green ci-gate, merges through release-please, and Hex lists 0.1.3 with passing post-publish smoke (REL-04; ROADMAP SC4 + SC5)"
    status: failed
    reason: >-
      Once the v3.5 milestone (Phases 46-49, 163 commits) was pushed to origin/main
      this session, CI ran on that work for the FIRST TIME and the refreshed release
      PR #12 (chore(main): release 0.1.3, head 0e54b551, run 29137880790) surfaced
      ~30 pre-existing test failures across the verify lanes. ci-gate is RED, so the
      Release PR Auto-Merge never fired: nothing merged, no v0.1.3 tag, no Hex publish.
      Verified independently: curl https://hex.pm/api/packages/scoria/releases/0.1.3
      returns HTTP 404 (release not published). These failures are Phase 46-49
      verification debt (the milestone was local-only and never CI'd), NOT introduced
      by Phase 50 — but they block the release train and REL-04 remains unmet.
      50-04 is still at its maintainer checkpoint (no SUMMARY). Full inventory:
      50-CI-GAP-INVENTORY.md.
    artifacts:
      - path: "test/scoria/phoenix_example_source_test.exs:8"
        issue: "Bucket A — reads old docs/phoenix_runtime_example.md stub; Scoria.identity/1 fragment moved to guides/ in Phase 48"
      - path: "test/scoria/handoff_example_source_test.exs:8"
        issue: "Bucket A — reads docs/bounded_handoffs.md stub; Scoria.start_handoff_run/3 fragment now in guides/"
      - path: "test/scoria/semantic_fast_path_example_source_test.exs:6"
        issue: "Bucket A — reads docs/semantic_fast_path.md stub; use Scoria.SemanticCache.Profile fragment now in guides/"
      - path: "test/scoria/support_journey_source_test.exs:7"
        issue: "Bucket A — 4 failures: README.md, docs/connector_adoption.md, docs/operator_verification.md, docs/support_copilot_gallery.md SSOT fragments relocated to guides/"
      - path: "test/scoria/package_surface_test.exs:79"
        issue: "Bucket B — 'project metadata describes one publish surface' fails"
      - path: "test/scoria/runtime_integration_test.exs:159"
        issue: "Bucket C — operator workflow page renders 'Workflow run not found' vs expected seeded run id"
      - path: "test/scoria_web/live/coming_soon_live_test.exs:60"
        issue: "Bucket C — 'allowlisted stubs render honest coming-soon pages' fails"
      - path: "test/scoria_web/components/memory_notebook_component_test.exs:10"
        issue: "Bucket C — shared notebook primitives contract fails"
      - path: "test/scoria_web/ui_component_test.exs:286,1289"
        issue: "Bucket D — flush panel gutters + table/1 density-out-of-public-API contracts fail"
      - path: "test/scoria_web/dev_lab_boundary_test.exs:161"
        issue: "Bucket D — guard #7 canonical PRIM-*/GROUP-* inventory ID reference under dev/lab/**"
      - path: "test/scoria/support_copilot_gallery_test.exs:8"
        issue: "Bucket E — advisory adoption journey fails"
      - path: "test/support_copilot_web/orchestrator_producer_test.exs:31"
        issue: "Bucket E — approvals page shows approval from producer path fails"
      - path: "test/support_copilot/journey_test.exs:110"
        issue: "Bucket E — knowledge lane refund-policy grounded journey fails"
      - path: "test/scoria/warning_inventory/capture_parity_test.exs:53"
        issue: "Bucket F — optimized compile-only capture misses injected high-signal warning"
    missing:
      - "Bucket A (docs-source alignment): repoint each *_example_source_test.exs / support_journey_source_test.exs to canonical guides/ paths after confirming fragment set is present there (do not weaken assertions)"
      - "Bucket B (package/publish surface): fix package_surface_test one-publish-surface expectation"
      - "Bucket C (runtime/LiveView rendered contracts): restore seeded run id + coming-soon + notebook primitive alignment"
      - "Bucket D (UI component/dev-lab contracts): reconcile flush-panel/table density + dev-lab inventory-ID guard"
      - "Bucket E (SupportCopilot demo journeys): repair advisory/approvals/knowledge journeys"
      - "Bucket F (warning inventory): restore compile-only capture parity"
      - "Enumerate full-suite (1-4) + connector partition failures via `gh run view 29137880790 --job <id> --log-failed` — buckets above are the default-lane subset (~30 full-suite + 5 connector total)"
      - "After all buckets green: push -> Release Please refreshes PR #12 -> confirm ci-gate green -> release-please merge/tag/publish 0.1.3 -> finish 50-04 Task 3 (post-publish smoke + D-04 closeout)"
---

# Phase 50: Release Readiness and 0.1.3 Cut — Verification Report

**Phase Goal:** Release readiness and 0.1.3 cut — policy/e2e release blockers fixed, stale version refs corrected, GREEN release PR, Hex publish, and post-publish smoke.
**Verified:** 2026-07-10
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

The phase goal is **NOT fully achieved**. The three release-*blocker-repair* requirements (REL-01 policy lane, REL-02 e2e lane, REL-03 version/docs truth) are met and independently confirmed against the codebase. The release *cut* itself (REL-04) is blocked: the release PR is RED on `ci-gate`, nothing merged, and Hex does not list `0.1.3` (HTTP 404). The blocker is Phase 46-49 verification debt exposed by pushing the local-only v3.5 milestone to CI for the first time — real and release-blocking, but not introduced by Phase 50.

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Policy lane no longer fails on planning-ledger drift; v2.15 Connector Adoption Lane breadcrumb preserved (REL-01, SC1) | ✓ VERIFIED | `ci_policy_contract_test.exs` `@maintainer_docs`/`@operator_docs` = `guides/maintainers.md`; no `docs/*.md` canonical refs remain; `guides/maintainers.md:128` carries `## Hex release & recovery {: #hex-release--recovery-maintainers}`. Ground truth: 58/0 policy lane green. Commits 51461be5, 25ad5233, c809241c present. 50-01-SUMMARY.md. |
| 2 | Browser e2e regressions from PR #12 fixed (hidden theme-toggle, modal focus, orientation) (REL-02, SC2) | ✓ VERIFIED | `dev_seed.exs:960,1048` call arity-3 tenant-scoped `start_release_workflow(..., tenant_id: tenant_id)`; `phase16_parity.spec.mjs` has 4 `.filter({ visible: true })` locators. Ground truth: full `mix scoria.ui.e2e` 165/0. Commits 7a24315, 75ee88a present. 50-02-SUMMARY.md. |
| 3 | Version references (README, maintainer docs, release automation, package metadata) reflect live 0.1.2 baseline / 0.1.3 target, no stale 0.1.1 (REL-03, SC3) | ✓ VERIFIED | No `docs/MAINTAINERS.md`/`docs/operator_verification.md` refs remain in `.github/workflows/`; no `SCORIA_REGISTRY_VERSION=0.1.1` in `scoria.post_publish_smoke.ex`; `mix.exs` `@hexdocs_url "https://scoria.hexdocs.pm"`, `@version "0.1.2"`. Ground truth: adoption_surface_test 29/0, `mix scoria.release_preview` exits 0. Commits 6692d93e, e151a502 present. 50-03-SUMMARY.md. |
| 4 | Release PR reaches green ci-gate and merges through release-please (REL-04, SC4) | ✗ FAILED | PR #12 head `0e54b551` run 29137880790: verify lanes RED (~30 failures + 5 connector); `ci-gate` fail -> Release PR Auto-Merge never fired; nothing merged, no v0.1.3 tag. See 50-CI-GAP-INVENTORY.md. |
| 5 | Hex lists 0.1.3 and post-publish smoke proves fresh install + live-lineage upgrade (REL-04, SC5) | ✗ FAILED | `curl https://hex.pm/api/packages/scoria/releases/0.1.3` -> HTTP 404 (not published). Post-publish smoke never ran; 50-04 remains at maintainer checkpoint (no SUMMARY). |

**Score:** 3/5 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `test/scoria/ci_policy_contract_test.exs` | Docs constants repointed to `guides/maintainers.md` | ✓ VERIFIED | Both constants + README-link assertions repointed; no docs/*.md canonical refs |
| `guides/maintainers.md` | Restored maintainer content + Hex-release anchor | ✓ VERIFIED | `## Hex release & recovery {: #hex-release--recovery-maintainers}` at L128; content restored |
| `priv/repo/dev_seed.exs` | Arity-3 tenant-scoped `start_release_workflow` at both sites | ✓ VERIFIED | Lines 960, 1048 pass `tenant_id: tenant_id` |
| `priv/dev/e2e/phase16_parity.spec.mjs` | Visible-locator theme-toggle fix | ✓ VERIFIED | 4 `.filter({ visible: true })` sites |
| `.github/workflows/*.yml`, `scoria.post_publish_smoke.ex`, `mix.exs` | Stale-ref/version polish | ✓ VERIFIED | No stale docs/*.md comments, no 0.1.1, subdomain HexDocs URL, @version 0.1.2 |
| `.planning/STATE.md` (50-04 closeout: publish run URL/ID per D-04) | Post-publish evidence recorded | ✗ MISSING | Release never published; no closeout evidence exists (blocked by REL-04) |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| REL-01 | 50-01 | Policy lane no longer fails on ledger drift; v2.15 breadcrumb preserved | ✓ SATISFIED | Truth 1; 58/0 policy lane |
| REL-02 | 50-02 | e2e lane no longer fails on browser regressions | ✓ SATISFIED | Truth 2; 165/0 e2e lane |
| REL-03 | 50-03 | Version refs reflect 0.1.2/0.1.3, no stale 0.1.1 | ✓ SATISFIED | Truth 3; 29/0 adoption surface |
| REL-04 | 50-04 | 0.1.3 PR green, Hex publish, post-publish smoke | ✗ BLOCKED | Truths 4-5; ci-gate RED, Hex 404 |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Hex lists 0.1.3 | `curl -sw '%{http_code}' https://hex.pm/api/packages/scoria/releases/0.1.3` | 404 | ✗ FAIL (release not published) |
| Task commits exist | `git cat-file -t <7 hashes>` | all FOUND | ✓ PASS |
| REL-01/02/03 code state matches SUMMARYs | grep of test/seed/workflow/mix files | all match | ✓ PASS |

Note: verify-lane CI results (~30 failures) are taken as ground truth from the parent session (run 29137880790) and the located, reproduced-locally inventory in 50-CI-GAP-INVENTORY.md — CI was NOT re-run per instruction.

### Anti-Patterns Found

None in the Phase-50-modified files. The ~30 failing tests are in the Phase 46-49 surface (docs/guide restructure fallout), not in files this phase touched. No unreferenced TBD/FIXME/XXX debt markers introduced by Phase 50.

### Human Verification Required

None as a status driver — the outstanding work is a concrete, code-level gap (REL-04), not an unverifiable judgment call. REL-04's remaining maintainer steps (merge PR #12, authorize Hex publish, run post-publish smoke) are gated behind fixing the ~30 CI failures first and are captured as gap-closure work, not human-verify items.

### Gaps Summary

Wave 1 (REL-01/02/03) fully delivered and confirmed in the codebase: the two original PR #12 blockers (policy docs-contract drift, e2e seed arity + theme-toggle) are fixed, and the version/docs-truth polish is consistent. **REL-04 is the single blocking gap.** Pushing the local-only v3.5 milestone to `origin/main` ran Phases 46-49 through CI for the first time, exposing ~30 pre-existing verify-lane failures (chiefly Bucket A: `*_example_source_test.exs`/`support_journey_source_test.exs` still reading `docs/*.md` stubs whose SSOT content Phase 48 moved to `guides/`; plus Buckets B-F: package surface, runtime/LiveView contracts, UI/dev-lab contracts, SupportCopilot journeys, warning inventory). `ci-gate` is RED, so no merge, no `v0.1.3` tag, and Hex returns 404 for `0.1.3`. These failures are release-blocking but are Phase 46-49 verification debt, not Phase 50 regressions.

**Resume path:** `/gsd-plan-phase 50 --gaps` (group closure by Buckets A-F), then `/gsd-execute-phase 50 --gaps-only`, push, confirm `ci-gate` green, let Release Please merge/tag/publish `0.1.3`, then finish 50-04 Task 3 (post-publish smoke + D-04 closeout). Gap planning should first enumerate the full-suite (1-4) and connector partition failures beyond the default-lane subset via `gh run view 29137880790 --job <id> --log-failed`.

**Phase not marked complete.** REL-04 (Pending in REQUIREMENTS.md and ROADMAP) remains open.

---

_Verified: 2026-07-10_
_Verifier: Claude (gsd-verifier)_
