---
phase: 35-maintenance-release-0-1-2-publish-post-publish-smoke
verified: 2026-06-19T15:41:19Z
status: passed
score: 3/3 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 35: Maintenance Release 0.1.2 Publish + Post-Publish Smoke Verification Report

**Phase Goal:** Prove the `0.1.2` maintenance release shipped cleanly to Hex and the live post-publish smoke passed, including fresh-install and previous-live registry upgrade proofs.
**Verified:** 2026-06-19T15:41:19Z
**Status:** passed
**Re-verification:** No - initial verification for the phase archive

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `REL-01` is satisfied: the release preflight and PR merge path completed, and the release branch stayed generated-only. | VERIFIED | Phase 35 Plan 02 summary records PR #3 refresh, release-file-only diff, latest-head `CI / ci-gate` success, and merge commit `26eb9a5e686fe4957196dfa5c6654121bda65c03`. |
| 2 | `REL-02` is satisfied: Hex lists `scoria` `0.1.2` as live/latest and the post-publish registry smoke passed. | VERIFIED | Phase 35 Plan 03 summary records `mix hex.info scoria 0.1.2` success, Hex API latest version `0.1.2`, and final smoke run `27834739958` passing. |
| 3 | `REL-03` is satisfied: the post-publish smoke workflow and registry upgrade proof both passed against the live package. | VERIFIED | Phase 35 Plan 03 summary records both fresh-install and upgrade proofs succeeding after harness fixes, with upgrade lineage `0.1.0 -> 0.1.2`. |

**Score:** 3/3 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `35-01-SUMMARY.md` | Release contract fix evidence | VERIFIED | Documents README Hex-primary contract narrowing and previous-live registry lineage. |
| `35-02-SUMMARY.md` | Release preflight + PR merge evidence | VERIFIED | Documents release-file-only refresh, docs/CI fixes, and merge commit `26eb9a5e686fe4957196dfa5c6654121bda65c03`. |
| `35-03-SUMMARY.md` | Publish + post-publish smoke evidence | VERIFIED | Documents Hex visibility, recovery publish, harness fixes, and final smoke success. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `35-03-SUMMARY.md` | Hex package release truth | Release and API checks in the summary | WIRED | Summary records `0.1.2` live on Hex, latest in the registry, and the final post-publish smoke passing. |
| `35-02-SUMMARY.md` | Release PR merge authority | Latest-head `CI / ci-gate` success | WIRED | Summary records PR #3 merge authority and release-file-only refresh. |
| `35-01-SUMMARY.md` | Registry lineage contract | Offline contract tests | WIRED | Summary records the previous-live registry override encoded in `Scoria.HexConsumerContract`. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Release merge and publish evidence are present in phase summaries | Summary review | Release PR refreshed, merged, published, and smoke-verified | PASS |
| Live Hex package evidence is present | Summary review | `mix hex.info scoria 0.1.2` and Hex API confirmed `0.1.2` latest | PASS |
| Final post-publish smoke completed successfully | Summary review | Final smoke run `27834739958` passed with fresh-install and upgrade proofs | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| REL-01 | 35-01, 35-02 | Maintainer can merge the release PR on green CI to publish `0.1.2` to Hex, with docs clean before merge. | SATISFIED | Phase 35 Plan 02 summary records docs cleanup, PR refresh, and merge success. |
| REL-02 | 35-03 | Post-publish registry semver upgrade smoke confirms the published `0.1.2` installs from the live Hex registry. | SATISFIED | Phase 35 Plan 03 summary records live Hex visibility and registry upgrade proof success. |
| REL-03 | 35-02, 35-03 | `post-publish-smoke.yml` Postgres host-port bind is fixed and the workflow guard covers the workflow file. | SATISFIED | Phase 35 Plan 02 and 03 summaries plus Phase 34 verification show the final workflow uses `5432:5432` and the smoke passed. |

No additional Phase 35 requirements are orphaned in `.planning/REQUIREMENTS.md`.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None | - | No placeholder markers or unfinished release artifacts remain in the phase summaries. | - | - |

### Human Verification Required

None.

### Gaps Summary

No gaps found. Phase 35 now has the required verification artifact, and the milestone audit can close cleanly.

---

_Verified: 2026-06-19T15:41:19Z_
_Verifier: the agent (gsd-verifier)_
