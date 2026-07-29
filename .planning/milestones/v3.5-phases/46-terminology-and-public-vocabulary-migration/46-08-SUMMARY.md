---
phase: 46-terminology-and-public-vocabulary-migration
plan: 08
subsystem: docs/release-readiness
tags: [terminology, changelog, readme, compatibility, release-preview]

requires: [46-07]
provides:
  - D-04 pre-1.0 terminology migration note in README install guidance
  - single ordered CHANGELOG Unreleased terminology migration entry before 0.1.2
  - changelog contract for upgrade-note placement, compatibility posture, and no-migration language
  - final Phase 46 focused verification across glossary, package, Hex consumer, adoption, changelog, and terminology contracts
affects: [phase-46, README, changelog, docs-contracts, release-preview]

tech-stack:
  added: []
  patterns:
    - Current changelog guidance owns final terminology while older main-branch notes are explicitly historical
    - Public upgrade notes must state Hex release status, alias compatibility, evidence boundary, and no schema migration together
    - Release-preview verification is part of terminology closeout because package-facing docs changed

key-files:
  modified:
    - README.md
    - CHANGELOG.md
    - test/scoria/changelog_contract_test.exs

key-decisions:
  - "CHANGELOG now has one current `## [Unreleased]` section before `## [0.1.2]`; older Unreleased markers were relabeled as historical main-branch notes."
  - "README install guidance now states that main-branch terminology is unreleased, Hex remains `0.1.2` until Phase 50, and legacy aliases remain accepted."
  - "RAG/citation evidence and `evidence_refs` remain unchanged; no database migration or trace-reference storage rename was introduced."

patterns-established:
  - "Changelog contracts should assert both section order and exact adopter-facing release posture language."
  - "Historical changelog entries can retain old terminology if current sections explicitly frame them as history."

requirements-completed: [TERM-04, TERM-03, TERM-02]

duration: 6 min
completed: 2026-07-09
status: complete
---

# Phase 46 Plan 08: README/CHANGELOG Upgrade Notes Summary

**README and CHANGELOG now explain the pre-1.0 terminology migration without implying a schema migration or a new Hex release.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-07-09T22:53:00Z
- **Completed:** 2026-07-09T22:59:00Z
- **Tasks:** 1
- **Files modified:** 3

## Accomplishments

- Added a README Install-section note titled `Pre-1.0 terminology migration` before `Upgrading or re-running install`.
- Added a single current CHANGELOG `## [Unreleased]` section before `## [0.1.2]` with `### Changed` and a final-vocabulary status table.
- Relabeled older CHANGELOG `## [Unreleased]` markers as historical main-branch notes instead of rewriting old release/history copy.
- Documented that Hex remains `0.1.2` until Phase 50 cuts the next release.
- Documented that legacy aliases remain accepted during the 0.1.x compatibility window.
- Kept RAG/citation proof as evidence and stated that `evidence_refs` stay unchanged.
- Confirmed there is no database migration for the terminology migration.
- Added changelog contracts for single-section ordering, exact upgrade-note language, README note placement, historical section framing, and storage/no-migration boundaries.

## Task Commits

1. **Task 1 RED: Terminology upgrade note contract** - `a13868e0` (test)
2. **Task 1 GREEN: README/CHANGELOG upgrade notes** - `c7f2ee5a` (docs)

## Files Created/Modified

- `test/scoria/changelog_contract_test.exs` - Added D-04 assertions for CHANGELOG order, single current Unreleased section, README Install note placement, Hex `0.1.2` status, alias compatibility, unchanged evidence storage, and no database migration.
- `CHANGELOG.md` - Added the current Unreleased terminology migration note and relabeled older Unreleased markers as historical main-branch notes.
- `README.md` - Added the Install-section terminology migration note before upgrade/re-run guidance.

## Decisions Made

- Kept historical changelog copy intact and changed only the heading labels needed to prevent duplicate current `Unreleased` sections.
- Used the current Unreleased section as the authoritative adopter-facing terminology migration note.
- Kept storage names and evidence semantics explicit in docs rather than introducing any schema/storage rename.

## Deviations from Plan

None.

## Issues Encountered

- Focused test assertions required exact contiguous strings for `Hex release remains \`0.1.2\` until Phase 50`, `legacy aliases remain accepted`, and `no database migration`; line wrapping and capitalization were adjusted.

## Verification

- `MIX_ENV=test mix test --warnings-as-errors test/scoria/changelog_contract_test.exs` - PASS, 4 tests, 0 failures.
- `rg -n '## \[Unreleased\]|Historical main-branch notes|Pre-1.0 terminology migration|Hex release remains \`0\.1\.2\` until Phase 50|no database migration|evidence_refs|trace_refs' CHANGELOG.md README.md` - PASS, expected upgrade-note hits and no `trace_refs` hits.
- `! rg -n "trace_refs" lib config priv mix.exs docs README.md CHANGELOG.md` - PASS, no matches.
- `bash -lc 'set -euo pipefail; ! rg -n "trace_refs" lib config priv mix.exs docs README.md CHANGELOG.md; MIX_ENV=dev mix scoria.release_preview; MIX_ENV=test mix test --warnings-as-errors test/scoria/glossary_contract_test.exs test/scoria/adoption_surface_test.exs test/scoria/package_surface_test.exs test/scoria/hex_consumer_contract_test.exs test/scoria/changelog_contract_test.exs test/scoria/terminology_contract_test.exs'` - PASS, release preview passed; 53 tests, 0 failures.

## User Setup Required

None.

## Next Phase Readiness

Phase 46 is ready for closeout: public vocabulary, compatibility aliases, glossary exposure, package docs, README/CHANGELOG upgrade notes, and focused release-preview verification are complete.

## Self-Check: PASSED

- Verified one current `## [Unreleased]` section appears before `## [0.1.2]`.
- Verified README Install guidance contains the migration note before upgrade/re-run guidance.
- Verified legacy aliases remain documented as accepted while final vocabulary is preferred.
- Verified `evidence_refs` and RAG/citation evidence semantics remain unchanged.
- Verified no `trace_refs` storage/public docs drift was introduced.
- Verified release preview and focused Phase 46 test suites pass.

---
*Phase: 46-terminology-and-public-vocabulary-migration*
*Completed: 2026-07-09*
