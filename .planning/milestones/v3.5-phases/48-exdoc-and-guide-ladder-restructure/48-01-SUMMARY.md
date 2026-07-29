---
phase: 48-exdoc-and-guide-ladder-restructure
plan: 01
subsystem: documentation-contracts
tags: [exdoc, hexdocs, package-surface, release-preview, red-contracts]

requires:
  - phase: 47-readme-first-screen-positioning-and-scope-doctrine
    provides: README positioning, scope doctrine, and comparison guide baseline
provides:
  - RED ExDoc/package contract for grouped extras, grouped modules, redirects, source metadata, and docs brand assets
  - RED release-preview required path contract for canonical guides, compatibility stubs, brand assets, and dev-doc exclusions
affects: [phase-48, docs, package, release-preview, exdoc]

tech-stack:
  added: []
  patterns:
    - ExUnit RED contracts for documentation/package inventory before implementation
    - Explicit canonical guide, compatibility stub, and brand asset path constants

key-files:
  created:
    - .planning/phases/48-exdoc-and-guide-ladder-restructure/48-01-SUMMARY.md
  modified:
    - test/scoria/package_surface_test.exs
    - test/mix/tasks/scoria.release_preview_test.exs

key-decisions:
  - "Plan 48-01 intentionally stops at RED contracts; later Phase 48 plans implement the guide ladder, ExDoc config, and release-preview GREEN path."
  - "Old docs/*.md paths are package compatibility stubs only, while canonical guides live under guides/ and dev-only docs stay excluded."

patterns-established:
  - "Package surface contracts assert ExDoc metadata, grouped extras/modules, redirects, canonical guides, compatibility stubs, brand assets, and dev-doc exclusion."
  - "Release-preview contracts compare required_package_paths/0 against the full Phase 48 inventory before production wiring changes."

requirements-completed: [DOCS-01, DOCS-02, DOCS-03]

duration: 5 min
completed: 2026-07-10
status: complete
---

# Phase 48 Plan 01: RED ExDoc and Release-Preview Contracts Summary

**RED ExUnit contracts now pin the Phase 48 HexDocs, package, redirect, guide-ladder, and release-preview inventory before implementation changes land.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-07-10T18:33:27Z
- **Completed:** 2026-07-10T18:38:24Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Replaced the old flat `docs/*.md` ExDoc assumptions in `test/scoria/package_surface_test.exs` with RED assertions for `main: "getting-started"`, dynamic `"main"` source refs on non-tag builds, ExDoc source metadata, grouped extras, grouped modules, redirects, canonical `guides/` extras, package compatibility stubs, brand assets, and dev-only doc exclusion.
- Replaced the release-preview path expectation in `test/mix/tasks/scoria.release_preview_test.exs` with the Phase 48 inventory: base package files, all canonical guides, all old compatibility stubs, and the four required brand assets.
- Preserved the existing Hex-primary dependency and GitHub fallback assertions while removing the obsolete README flat-doc path loop from the package surface test.

## Task Commits

1. **Task 1: Add RED ExDoc config and package surface contract** - `8b073b29` (`test`)
2. **Task 2: Add RED release-preview required path contract** - `15fac003` (`test`)

## Files Created/Modified

- `test/scoria/package_surface_test.exs` - Adds Phase 48 RED contract coverage for ExDoc metadata, guide groups, module groups, redirects, package inventory, brand assets, and dev-doc exclusion.
- `test/mix/tasks/scoria.release_preview_test.exs` - Adds Phase 48 RED contract coverage for `Mix.Tasks.Scoria.ReleasePreview.required_package_paths/0`.
- `.planning/phases/48-exdoc-and-guide-ladder-restructure/48-01-SUMMARY.md` - Records plan completion.

## Verification

- `MIX_ENV=test mix test test/scoria/package_surface_test.exs` - RED as expected: compiles, 8 tests run, 7 failures from missing Phase 48 implementation (`main` still `"readme"`, missing guide extras/package paths, missing groups, missing redirects).
- `MIX_ENV=test mix test test/mix/tasks/scoria.release_preview_test.exs` - RED as expected: compiles, 1 test run, 1 failure because `required_package_paths/0` still returns the old flat docs inventory.
- `MIX_ENV=test mix test test/scoria/package_surface_test.exs test/mix/tasks/scoria.release_preview_test.exs` - RED as expected: compiles, 9 tests run, 8 failures from the same pending implementation gaps.
- Source acceptance checks passed: required guide, brand asset, `groups_for_extras`, `groups_for_modules`, and `redirects` tokens are present; stale `main == "readme"` and `source_ref == "v#{version}"` assertions are gone.

## Decisions Made

- This Wave 1 plan ends in RED by design. No `mix.exs`, guide, package, or release-preview production wiring was changed.
- Requirements DOCS-01, DOCS-02, and DOCS-03 are represented in the plan frontmatter and contract coverage, but remain phase-level pending until later Phase 48 plans implement the contracts.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None found in files modified by this plan.

## Issues Encountered

None. The nonzero verification commands are the expected RED outcome for this plan.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plans 48-02 and later can build against these RED contracts. The current blockers are intentional implementation gaps: no canonical `guides/` ladder yet, `mix.exs` still has flat ExDoc metadata, and `scoria.release_preview` still uses the old required path list.

## Self-Check: PASSED

- Found modified files: `test/scoria/package_surface_test.exs`, `test/mix/tasks/scoria.release_preview_test.exs`.
- Found summary file: `.planning/phases/48-exdoc-and-guide-ladder-restructure/48-01-SUMMARY.md`.
- Found task commits: `8b073b29`, `15fac003`.

---
*Phase: 48-exdoc-and-guide-ladder-restructure*
*Completed: 2026-07-10*
