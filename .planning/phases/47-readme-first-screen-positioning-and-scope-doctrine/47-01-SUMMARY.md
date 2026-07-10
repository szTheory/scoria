---
phase: 47-readme-first-screen-positioning-and-scope-doctrine
plan: "01"
subsystem: docs-contracts
tags: [readme, scope-doctrine, exunit, docs-as-public-api]

requires:
  - phase: 46-terminology-and-public-vocabulary-migration
    provides: final public vocabulary for reviewer, trace, capability, verification suite, scoped context, semantic cache, and optional knowledge base
provides:
  - RED README first-screen positioning contracts for POS-01 and POS-02
  - RED README stale-version contracts for POS-01/D-06
  - RED owns-vs-delegates public table contract for POS-03
affects: [phase-47-plan-02, readme, adoption-docs, scope-doctrine]

tech-stack:
  added: []
  patterns:
    - README-scoped literal contract helpers in Scoria.AdopterDocContract
    - File.read!-based docs-as-public-API assertions
    - RED-only docs contract commits before copy implementation

key-files:
  created:
    - .planning/phases/47-readme-first-screen-positioning-and-scope-doctrine/47-01-SUMMARY.md
  modified:
    - lib/scoria/adopter_doc_contract.ex
    - test/scoria/adoption_surface_test.exs
    - test/scoria/scope_doctrine_contract_test.exs

key-decisions:
  - "Plan 47-01 intentionally leaves README and stable docs unchanged, producing RED contracts for Wave 1 copy edits."
  - "README stale-version checks are scoped to README only, leaving broader release reconciliation to Phase 50."
  - "The public scope table contract uses adopter-readable boundary rows instead of P1-P6 planning labels."

patterns-established:
  - "RED docs contracts can use small public helper constants when the target copy is intentionally absent."
  - "Scope doctrine docs tests should follow Phase 46 capability vocabulary, not older lane wording."

requirements-completed: [POS-01, POS-02, POS-03]

duration: 3 min
completed: 2026-07-10
status: complete
---

# Phase 47 Plan 01: README First-Screen RED Contracts Summary

**Executable README and scope-doctrine RED contracts now pin the missing first-screen positioning, persona boundaries, stale-version cleanup, and owns-vs-delegates table before docs copy changes.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-07-10T13:21:52Z
- **Completed:** 2026-07-10T13:25:45Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added `Scoria.AdopterDocContract` helpers for the embedded Phoenix README intro marker, first-screen ordering markers, and README-only stale-version refutes.
- Added README RED assertions for product-category-before-capability ordering, roles-not-headcount persona boundaries, Core/Adjacent/Not Scoria surface labels, and stale `0.1.1` fallback guidance.
- Added the public owns-vs-delegates table RED contract with required headers, five required boundary rows, host-owned responsibility terms, and a guard against P1-P6 public row labels.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add README first-screen and stale-version RED contracts** - `3f5c80ca` (test)
2. **Task 2: Add public owns-vs-delegates RED contracts** - `2916c974` (test)

**Plan metadata:** pending final docs commit

## Files Created/Modified

- `lib/scoria/adopter_doc_contract.ex` - Adds README positioning and stale-version helper constants.
- `test/scoria/adoption_surface_test.exs` - Adds RED README first-screen, persona, and stale-version assertions.
- `test/scoria/scope_doctrine_contract_test.exs` - Adds RED owns-vs-delegates table assertions and aligns existing wording with current capability vocabulary.
- `.planning/phases/47-readme-first-screen-positioning-and-scope-doctrine/47-01-SUMMARY.md` - Records execution outcome and verification evidence.

## Verification

- `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs` exited `2` as expected: 20 tests, 3 planned README failures. Compilation passed. Failures were missing embedded-Phoenix intro copy, missing roles-not-headcount/Core/Adjacent/Not Scoria copy, and stale README `v0.1.1` fallback guidance.
- `MIX_ENV=test mix test test/scoria/scope_doctrine_contract_test.exs` exited `2` as expected after baseline wording alignment: 5 tests, 1 planned failure. Compilation passed. The only failure was the missing public `What Scoria owns vs what your app owns` table.
- `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/scope_doctrine_contract_test.exs` exited `2` as expected: 25 tests, 4 planned RED failures. No compile errors or unrelated contract failures surfaced.

## Decisions Made

- Kept README, `docs/adoption_lanes.md`, and `docs/operator_verification.md` unchanged in this plan because Wave 0 is RED-only.
- Scoped stale-version refutes to README strings from D-06 so maintainer release-command cleanup remains owned by Phase 50.
- Allowed the owns-vs-delegates table to live in README or stable adopter docs, while still requiring adopter-readable rows and host-owned responsibility terms.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Aligned stale scope-doctrine baseline wording**
- **Found during:** Task 2 (Add public owns-vs-delegates RED contracts)
- **Issue:** The pre-existing scope-doctrine test still expected older "lane" wording in README/adoption/operator docs, while current Phase 46 docs use "capability" and "path" wording. That would have mixed baseline failures with the new RED table failure.
- **Fix:** Updated three existing assertions in `test/scoria/scope_doctrine_contract_test.exs` to match current docs vocabulary.
- **Files modified:** `test/scoria/scope_doctrine_contract_test.exs`
- **Verification:** `MIX_ENV=test mix test test/scoria/scope_doctrine_contract_test.exs` now fails only on the newly introduced missing public table assertion.
- **Committed in:** `2916c974`

---

**Total deviations:** 1 auto-fixed (1 blocking baseline-contract issue)
**Impact on plan:** The auto-fix narrowed RED output to the planned missing docs copy and did not change product/source/docs copy.

## Issues Encountered

Expected RED test exits were observed by design. No authentication gates, package installs, compile errors, or unrelated runtime failures occurred.

## Known Stubs

None. Stub scan found only existing test assertions for generic unavailable copy and non-empty moduledocs; no placeholder implementation was introduced.

## Threat Flags

None. The plan added docs-contract assertions for the planned adopter-doc trust boundary and introduced no new runtime endpoint, auth path, file access pattern, or schema change.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for 47-02. The next plan can edit README and stable docs against the four RED failures captured here.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/47-readme-first-screen-positioning-and-scope-doctrine/47-01-SUMMARY.md`.
- Key modified files exist on disk.
- Task commits `3f5c80ca` and `2916c974` exist in git history.

---
*Phase: 47-readme-first-screen-positioning-and-scope-doctrine*
*Completed: 2026-07-10*
