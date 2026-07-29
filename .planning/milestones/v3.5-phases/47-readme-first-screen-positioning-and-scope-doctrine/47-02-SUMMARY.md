---
phase: 47-readme-first-screen-positioning-and-scope-doctrine
plan: "02"
subsystem: docs
tags: [readme, scope-doctrine, adopter-docs, docs-contracts]

requires:
  - phase: 47-readme-first-screen-positioning-and-scope-doctrine
    provides: "47-01 RED contracts for README positioning, stale version cleanup, persona copy, and public owns-vs-delegates table"
provides:
  - README first-screen embedded Phoenix positioning before capability and verification-suite vocabulary
  - README n=1 reviewer persona and Core/Adjacent/Not Scoria surface boundaries
  - Public owns-vs-delegates scope table with host-owned auth, policy, eval, knowledge, and business-truth boundaries
  - Stable guide cross-links from adoption and reviewer verification docs to the public scope table
affects: [phase-47-plan-03, readme, adoption-docs, scope-doctrine, comparison-guide]

tech-stack:
  added: []
  patterns:
    - "Docs-as-public-API contract checks using existing ExUnit files"
    - "README first-screen progressive disclosure before capability ladder"
    - "Adopter-readable ownership rows instead of public P1-P6 labels"

key-files:
  created:
    - .planning/phases/47-readme-first-screen-positioning-and-scope-doctrine/47-02-SUMMARY.md
  modified:
    - README.md
    - docs/adoption_lanes.md
    - docs/operator_verification.md

key-decisions:
  - "README now leads with the embedded Phoenix library boundary and defers capability/verification-suite vocabulary until after persona and scope preview copy."
  - "The public scope table translates the planning doctrine into adopter-readable boundaries rather than exposing P1-P6 labels."
  - "README links to docs/scoria_vs_external_llm_ops.md as a Phase 47-03 comparison-guide surface but does not create or package that guide in this plan."
  - "README release copy uses live Hex baseline 0.1.2 and leaves the 0.1.3 release cut to Phase 50."

patterns-established:
  - "Scope rows pair Scoria-owned mechanism verbs with host-owned identity, policy values, business truth, and end-user surfaces."
  - "Stable guides cross-link the README scope table near the top while preserving existing proof-command guidance."

requirements-completed: [POS-01, POS-02, POS-03]

duration: 5 min
completed: 2026-07-10
status: complete
---

# Phase 47 Plan 02: README Positioning and Scope Doctrine Summary

**README now opens with embedded Phoenix positioning, n=1 reviewer role boundaries, live 0.1.2 release truth, and a public owns-vs-delegates table locked by docs contracts.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-07-10T13:30:11Z
- **Completed:** 2026-07-10T13:35:11Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Rewrote the README first screen so the first prose paragraph names Scoria as an embedded Elixir/Phoenix library for durable, inspectable AI/LLM work before capability or verification-suite language appears.
- Added roles-not-headcount persona copy plus Core, Adjacent, and Not Scoria surface boundaries.
- Updated README install/status copy to the live `0.1.2` baseline and removed the current OpenInference-style trace-substrate overclaim.
- Added the public `What Scoria owns vs what your app owns` table with adopter-readable rows for run traces, dashboard scope, governance gates, eval proof, knowledge grounding, bounded handoff, remote connectors, and Phoenix infrastructure.
- Cross-linked `docs/adoption_lanes.md` and `docs/operator_verification.md` to the README scope table while preserving existing proof-command guidance.

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite README first screen and live version baseline** - `b9f6c661` (docs)
2. **Task 2: Add public owns-vs-delegates scope table and stable guide cross-links** - `281d7611` (docs)

**Plan metadata:** committed after summary self-check in the close-out docs commit.

## Files Created/Modified

- `README.md` - First-screen product category, persona boundaries, future comparison-guide link, ownership table, `0.1.2` status, and non-OpenInference current trace wording.
- `docs/adoption_lanes.md` - Adds near-top README scope-table cross-link and n=1 roles-not-headcount sentence.
- `docs/operator_verification.md` - Adds near-top README scope-table cross-link and reviewer/operator compatibility plus host-owned auth/policy language.
- `.planning/phases/47-readme-first-screen-positioning-and-scope-doctrine/47-02-SUMMARY.md` - Records execution outcome and verification evidence.

## Verification

- `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs` passed: 20 tests, 0 failures.
- `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/scope_doctrine_contract_test.exs test/scoria/terminology_contract_test.exs test/scoria/changelog_contract_test.exs test/scoria/glossary_contract_test.exs` passed: 44 tests, 0 failures.
- `rg -n 'v0\.1\.1|Current release: `0\.1\.1`|OpenInference' README.md || true` returned no matches.
- README scope-table scan confirmed no P1-P6 public row labels in the table section.

## Decisions Made

- Kept the comparison guide itself out of this plan per the explicit 47-03 boundary, while adding the README link expected by 47-02.
- Used `v0.1.2` for the README fork/pinned-patch fallback example because `0.1.2` is the live Hex baseline; `0.1.3` remains described only as a Phase 50 release cut.
- Kept guide edits additive and near the top so existing capability and verification proof sections remain stable.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Adjusted README scope-table link label so the table contract parsed the actual table**
- **Found during:** Task 2 (Add public owns-vs-delegates scope table and stable guide cross-links)
- **Issue:** The first-screen link used the exact table title before the heading, so the existing contract split on that first occurrence and inspected the wrong section.
- **Fix:** Changed the first-screen link label to `the ownership table below` while retaining the same anchor.
- **Files modified:** `README.md`
- **Verification:** The focused Phase 47 docs-contract command passed with 44 tests, 0 failures.
- **Committed in:** `281d7611`

---

**Total deviations:** 1 auto-fixed (1 docs-contract parsing bug)
**Impact on plan:** No scope expansion. The fix preserved the intended first-screen link and made the existing public-table contract inspect the actual table.

## Issues Encountered

The only implementation issue was the table-link label described above. No authentication gates, package installs, runtime code changes, or unrelated failures occurred.

## Known Stubs

None. Stub-pattern scan found only the required generic fail-closed dashboard copy `This Scoria dashboard is not available for this session` in existing guide sections; it is not placeholder content.

## Threat Flags

None. This plan changed Markdown documentation only and introduced no new runtime endpoint, auth path, file access pattern, schema change, or package dependency.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for 47-03. The README now links to `docs/scoria_vs_external_llm_ops.md`; Plan 47-03 owns creating, packaging, and contract-testing that comparison guide plus release-preview/package-surface wiring.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/47-readme-first-screen-positioning-and-scope-doctrine/47-02-SUMMARY.md`.
- Key modified files exist on disk: `README.md`, `docs/adoption_lanes.md`, `docs/operator_verification.md`.
- Task commits `b9f6c661` and `281d7611` exist in git history.
- Verification command passed after both task commits.

---
*Phase: 47-readme-first-screen-positioning-and-scope-doctrine*
*Completed: 2026-07-10*
