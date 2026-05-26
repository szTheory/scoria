---
phase: 50-release-preview-ci-truth-and-phase-47-verification
verified: 2026-05-26T13:29:22Z
status: passed
score: 8/8 must-haves verified
overrides_applied: 0
---

# Phase 50: Release-preview CI Truth And Phase 47 Verification Report

**Phase Goal:** Restore a truthful CI-safe release-preview lane and close the missing Phase 47 verification gap.  
**Verified:** 2026-05-26T13:29:22Z  
**Status:** passed  
**Re-verification:** No

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | The broken `MIX_ENV=test mix scoria.release_preview` closeout contract has been re-scoped away from dev-only tooling instead of being silently kept as supported. | ✓ VERIFIED | [.github/workflows/ci.yml](/Users/jon/projects/scoria/.github/workflows/ci.yml:63) runs `MIX_ENV=dev mix scoria.release_preview`, while [docs/operator_verification.md](/Users/jon/projects/scoria/docs/operator_verification.md:136) keeps the maintainer-facing command plain `mix scoria.release_preview` and explains the CI-only `MIX_ENV=dev` override at lines 143 and 161. |
| 2 | The package/docs truth lane now fails for real regressions instead of environment wiring drift. | ✓ VERIFIED | `MIX_ENV=dev mix scoria.release_preview` passed on 2026-05-26, emitting `==> Building publish-facing docs` and `==> Release preview passed`; the workflow step is isolated ahead of database setup and broad test execution in [.github/workflows/ci.yml](/Users/jon/projects/scoria/.github/workflows/ci.yml:63). |
| 3 | Source assertions fail if the repo drifts back to presenting `MIX_ENV=test mix scoria.release_preview` as the closeout contract. | ✓ VERIFIED | [test/scoria/adoption_surface_test.exs](/Users/jon/projects/scoria/test/scoria/adoption_surface_test.exs:150) asserts the operator guide contains `mix scoria.release_preview` and explicitly refutes `MIX_ENV=test mix scoria.release_preview` at line 183. |
| 4 | `47-VERIFICATION.md` exists and records bounded proof for `ADPT-03` and `ADPT-04` in the corrected release-preview lane. | ✓ VERIFIED | [.planning/phases/47-release-packaging-and-docs-truth/47-VERIFICATION.md](/Users/jon/projects/scoria/.planning/phases/47-release-packaging-and-docs-truth/47-VERIFICATION.md:28) includes behavioral spot-checks for `MIX_ENV=dev mix scoria.release_preview` and `MIX_ENV=test mix test test/scoria/package_surface_test.exs test/mix/tasks/scoria.release_preview_test.exs --trace`, plus requirements coverage for `ADPT-03` and `ADPT-04` at lines 35-40. |
| 5 | Phase 47 closure is backed by fresh executable proof rather than summary-only completion, and the evidence would have gone red if the rerun commands failed. | ✓ VERIFIED | I re-ran both commands cited in [47-VERIFICATION.md](/Users/jon/projects/scoria/.planning/phases/47-release-packaging-and-docs-truth/47-VERIFICATION.md:28): `MIX_ENV=dev mix scoria.release_preview` passed, and `MIX_ENV=test mix test test/scoria/package_surface_test.exs test/mix/tasks/scoria.release_preview_test.exs --trace` passed with `5 tests, 0 failures`. |
| 6 | Milestone requirements bookkeeping now reflects repaired verification state for `ADPT-03` and `ADPT-04`. | ✓ VERIFIED | [.planning/REQUIREMENTS.md](/Users/jon/projects/scoria/.planning/REQUIREMENTS.md:35) marks both requirements complete, and the traceability table maps `ADPT-03` and `ADPT-04` to `Phase 50 | Complete` at lines 78-79. |
| 7 | Phase 50 bookkeeping reflects a real three-plan gap-closure phase instead of the prior `0 plans` placeholder. | ✓ VERIFIED | [.planning/ROADMAP.md](/Users/jon/projects/scoria/.planning/ROADMAP.md:72) lists `**Plans**: 3 plans` with `50-01-PLAN.md`, `50-02-PLAN.md`, and `50-03-PLAN.md` at lines 73-75; the progress table shows `2/3 | In Progress` at line 96, matching the current artifact state. |
| 8 | Bookkeeping does not overclaim full milestone closure; Phase 51 remains pending. | ✓ VERIFIED | [.planning/REQUIREMENTS.md](/Users/jon/projects/scoria/.planning/REQUIREMENTS.md:84) keeps `DOCS-01` and `DOCS-02` at `Phase 51 | Pending`, and [.planning/ROADMAP.md](/Users/jon/projects/scoria/.planning/ROADMAP.md:97) keeps Phase 51 at `0/0 | Pending`. |

**Score:** 8/8 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `.github/workflows/ci.yml` | Truthful release-preview env contract in CI | ✓ VERIFIED | Exists, substantive, and wired. The job-wide `MIX_ENV: test` remains at line 34, while the release-preview step is explicitly overridden to `MIX_ENV=dev` at line 64 before database prep and broader tests. |
| `docs/operator_verification.md` | Maintainer-facing explanation of the canonical release-preview lane | ✓ VERIFIED | Exists, substantive, and wired. The guide names plain `mix scoria.release_preview` as canonical at lines 139-160 and explains the CI-only `MIX_ENV=dev` override at lines 143 and 161. |
| `test/scoria/adoption_surface_test.exs` | Source assertions that pin the closeout command contract | ✓ VERIFIED | Exists, substantive, and wired. The operator-guide assertions at lines 150-185 enforce the canonical command and reject the old test-env-prefixed variant. |
| `.planning/phases/47-release-packaging-and-docs-truth/47-VERIFICATION.md` | Executable closeout evidence for Phase 47 | ✓ VERIFIED | Exists, substantive, and wired to rerun evidence and Phase 47 source plans. It records the corrected lane, focused package/docs assertions, and `ADPT-03`/`ADPT-04` coverage. |
| `.planning/REQUIREMENTS.md` | Requirement and traceability truth for `ADPT-03` and `ADPT-04` | ✓ VERIFIED | Exists, substantive, and wired. Both requirements are checked complete and traced to Phase 50 without changing the pending Phase 51 docs requirements. |
| `.planning/ROADMAP.md` | Phase 50 plan inventory and milestone progress truth | ✓ VERIFIED | Exists, substantive, and wired. The Phase 50 section reflects the three-plan gap-closure shape and the progress table reflects the real `2/3` in-progress state. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `.github/workflows/ci.yml` | `docs/operator_verification.md` | release-preview lane command | ✓ WIRED | Workflow step at [.github/workflows/ci.yml](/Users/jon/projects/scoria/.github/workflows/ci.yml:63) runs `MIX_ENV=dev mix scoria.release_preview`; the same command is documented as canonical in [docs/operator_verification.md](/Users/jon/projects/scoria/docs/operator_verification.md:139). |
| `test/scoria/adoption_surface_test.exs` | `docs/operator_verification.md` | closeout command wording assertions | ✓ WIRED | [test/scoria/adoption_surface_test.exs](/Users/jon/projects/scoria/test/scoria/adoption_surface_test.exs:153) asserts `mix scoria.release_preview`, [line 171](/Users/jon/projects/scoria/test/scoria/adoption_surface_test.exs:171) asserts the CI `MIX_ENV=dev` note, and [line 183](/Users/jon/projects/scoria/test/scoria/adoption_surface_test.exs:183) refutes the unsupported `MIX_ENV=test` wording. |
| `47-VERIFICATION.md` | `47-01-SUMMARY.md` | ADPT-03 source-plan traceability | ✓ WIRED | [47-VERIFICATION.md](/Users/jon/projects/scoria/.planning/phases/47-release-packaging-and-docs-truth/47-VERIFICATION.md:39) cites `47-01` for `ADPT-03`, and the source summary file exists on disk. |
| `47-VERIFICATION.md` | `47-02-SUMMARY.md` | ADPT-04 source-plan traceability | ✓ WIRED | [47-VERIFICATION.md](/Users/jon/projects/scoria/.planning/phases/47-release-packaging-and-docs-truth/47-VERIFICATION.md:40) cites `47-02` for `ADPT-04`, and the source summary file exists on disk. |
| `.planning/REQUIREMENTS.md` | `47-VERIFICATION.md` | ADPT requirement completion | ✓ WIRED | [.planning/REQUIREMENTS.md](/Users/jon/projects/scoria/.planning/REQUIREMENTS.md:78) maps `ADPT-03` and `ADPT-04` to `Phase 50 | Complete`, which is only truthful because [47-VERIFICATION.md](/Users/jon/projects/scoria/.planning/phases/47-release-packaging-and-docs-truth/47-VERIFICATION.md:35) now contains executable evidence. |
| `.planning/ROADMAP.md` | `47-VERIFICATION.md` | gap-closure bookkeeping | ✓ WIRED | [.planning/ROADMAP.md](/Users/jon/projects/scoria/.planning/ROADMAP.md:70) names `47-VERIFICATION.md` as a success criterion and the Phase 50 progress/inventory rows reflect that repaired evidence state. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `test/scoria/adoption_surface_test.exs` | `content` for operator-guide assertions | `File.read!("docs/operator_verification.md")` | Yes | ✓ FLOWING |
| `47-VERIFICATION.md` | behavioral spot-check outcomes | Current reruns of `mix scoria.release_preview` and focused package/docs tests | Yes | ✓ FLOWING |
| `.github/workflows/ci.yml` | release-preview command contract | Static workflow shell step | N/A static contract | N/A |
| `.planning/REQUIREMENTS.md` / `.planning/ROADMAP.md` | milestone ledger state | Static planning artifacts updated after Phase 47 verification backfill | N/A static contract | N/A |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Focused operator-guide and support-truth assertions | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs --trace` | Passed with `8 tests, 0 failures`. | ✓ PASS |
| Corrected bounded release-preview lane | `MIX_ENV=dev mix scoria.release_preview` | Passed. Built docs, emitted two non-failing docs warnings, built the unpacked Hex preview, and finished with `==> Release preview passed`. | ✓ PASS |
| Phase 47 bounded package/docs proof suite | `MIX_ENV=test mix test test/scoria/package_surface_test.exs test/mix/tasks/scoria.release_preview_test.exs --trace` | Passed with `5 tests, 0 failures`. | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `ADPT-03` | `50-01`, `50-02`, `50-03` | Maintainer can build publish-facing docs locally through `mix docs`, with truthful closeout/traceability bookkeeping. | ✓ SATISFIED | The corrected lane passes via `MIX_ENV=dev mix scoria.release_preview`; [47-VERIFICATION.md](/Users/jon/projects/scoria/.planning/phases/47-release-packaging-and-docs-truth/47-VERIFICATION.md:39) records executable proof; [.planning/REQUIREMENTS.md](/Users/jon/projects/scoria/.planning/REQUIREMENTS.md:78) accounts for the requirement as complete. |
| `ADPT-04` | `50-01`, `50-02`, `50-03` | Maintainer can preview the package artifact and keep its proof/ledger state truthful. | ✓ SATISFIED | The bounded package/docs suite passes; [47-VERIFICATION.md](/Users/jon/projects/scoria/.planning/phases/47-release-packaging-and-docs-truth/47-VERIFICATION.md:40) records executable package-inventory evidence; [.planning/REQUIREMENTS.md](/Users/jon/projects/scoria/.planning/REQUIREMENTS.md:79) accounts for the requirement as complete. |

All requirement IDs declared in phase 50 plan frontmatter were cross-referenced: `ADPT-03` and `ADPT-04` appear in all three plans, both are present in `.planning/REQUIREMENTS.md`, both are mapped in the traceability table, and no extra Phase 50 requirement IDs were orphaned.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| None | — | No TODO/FIXME/placeholders or empty implementations found in the Phase 50 artifacts scanned. | — | No blocker or warning found in the implemented phase files. |

### Human Verification Required

None.

### Gaps Summary

No blocking gaps found. Phase 50 achieves its goal from the current codebase: the CI release-preview lane is re-scoped to the supported dev env, the maintainer-facing command remains plain `mix scoria.release_preview`, the regression assertions reject the old test-env contract, `47-VERIFICATION.md` now exists with fresh bounded proof for `ADPT-03` and `ADPT-04`, and the roadmap/requirements ledgers reflect that repaired state without overclaiming Phase 51 closure.

Residual risk: `mix scoria.release_preview` still emits two non-failing docs warnings (`README.md` references `LICENSE`, and docs reference `Scoria.Knowledge.Source.t()` as undefined/private). Those warnings do not block Phase 50's goal, but they remain worth cleaning up separately.

---

_Verified: 2026-05-26T13:29:22Z_  
_Verifier: Codex (gsd-verifier)_
