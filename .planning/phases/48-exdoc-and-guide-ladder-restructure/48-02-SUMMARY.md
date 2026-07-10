---
phase: 48-exdoc-and-guide-ladder-restructure
plan: 02
subsystem: documentation-contracts
tags: [exdoc, guide-ladder, public-moduledocs, red-contracts]

requires:
  - phase: 48-exdoc-and-guide-ladder-restructure
    provides: 48-01 RED ExDoc/package/release-preview contracts
  - phase: 47-readme-first-screen-positioning-and-scope-doctrine
    provides: README scope doctrine and external LLM-ops comparison baseline
provides:
  - RED stable-doc contracts for canonical guides/ paths
  - RED glossary and ownership-boundary guide path contracts
  - RED public moduledoc contract for D-17 prioritized modules and D-15 compatibility aliases
affects: [phase-48, docs, guides, exdoc, public-api-docs]

tech-stack:
  added: []
  patterns:
    - Contract helper path constants for canonical guides
    - Code.fetch_docs based public moduledoc assertions

key-files:
  created:
    - .planning/phases/48-exdoc-and-guide-ladder-restructure/48-02-SUMMARY.md
  modified:
    - lib/scoria/adopter_doc_contract.ex
    - lib/scoria/hex_consumer_contract.ex
    - test/scoria/terminology_contract_test.exs
    - test/scoria/adoption_surface_test.exs
    - test/scoria/glossary_contract_test.exs
    - test/scoria/scope_doctrine_contract_test.exs

key-decisions:
  - "Plan 48-02 intentionally remains RED: canonical guide files, README links, and D-17 module guide links are implemented by later Phase 48 plans."
  - "Stable adopter-doc contracts now treat old docs/*.md paths as compatibility-only; canonical public truth points at guides/ paths."
  - "Public moduledoc tests use Code.fetch_docs/1 to verify compiled docs without adding doctest expectations for runtime, dashboard, DB, or LiveView examples."

patterns-established:
  - "AdopterDocContract exposes canonical guide path helpers for golden path, JTBD/user flows, ownership boundary, reviewer verification, comparison, and glossary docs."
  - "HexConsumerContract.adopter_doc_surfaces/0 now drives README plus canonical guide surface checks instead of old adoption_lanes/operator_verification docs."
  - "AdoptionSurfaceTest keeps D-14 internals out of the public contract set and checks D-15 compatibility wrappers without runtime @deprecated warnings."

requirements-completed: [DOCS-01, DOCS-03]

duration: 5m 29s
completed: 2026-07-10
status: complete
---

# Phase 48 Plan 02: Canonical Guide and Public Moduledoc RED Contracts Summary

**Stable-doc, glossary, ownership-boundary, and public moduledoc contracts now point at the Phase 48 canonical guide ladder before the guides and moduledocs are green.**

## Performance

- **Duration:** 5m 29s
- **Started:** 2026-07-10T18:43:12Z
- **Completed:** 2026-07-10T18:48:41Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added canonical `guides/` path helpers to `Scoria.AdopterDocContract`, including `comparison_guide_path/0` returning `guides/scoria-vs-external-llm-ops.md`.
- Moved `Scoria.HexConsumerContract.adopter_doc_surfaces/0` from old flat `docs/adoption_lanes.md` / `docs/operator_verification.md` surfaces to README plus `guides/golden-path.md`, `guides/jtbd-and-user-flows.md`, and `guides/reviewer-verification.md`.
- Updated terminology, adoption surface, glossary, and scope doctrine contracts to read canonical guide paths, including `guides/reference/glossary.md` and `guides/ownership-boundary.md`.
- Added D-17 public moduledoc RED coverage for 21 prioritized public modules, D-14 internal-module exclusion, D-15 compatibility alias documentation without `@deprecated`, and D-19 doctest boundaries.

## Task Commits

1. **Task 1: Move stable adopter-doc contracts to canonical guides** - `ffe8223a` (`test`)
2. **Task 2: Add glossary, ownership-boundary, and public moduledoc RED checks** - `d1db06a9` (`test`)

## Files Created/Modified

- `lib/scoria/adopter_doc_contract.ex` - Adds canonical guide path helpers for Phase 48 guide contracts.
- `lib/scoria/hex_consumer_contract.ex` - Moves adopter doc surface drift checks to canonical guide paths.
- `test/scoria/terminology_contract_test.exs` - Replaces stable adopter doc corpus with README plus the D-03 guide ladder.
- `test/scoria/adoption_surface_test.exs` - Moves guide assertions to canonical paths and adds public moduledoc contract coverage.
- `test/scoria/glossary_contract_test.exs` - Reads the glossary from `guides/reference/glossary.md`.
- `test/scoria/scope_doctrine_contract_test.exs` - Requires the ownership-boundary guide to carry the public owns-vs-delegates table.

## Verification

- `MIX_ENV=test mix test test/scoria/terminology_contract_test.exs test/scoria/adoption_surface_test.exs` - RED as expected: compiled, 39 tests run, 24 failures from missing canonical guide files, README still linking old `docs/` paths, and D-17 moduledocs missing canonical guide fragments.
- `MIX_ENV=test mix test test/scoria/glossary_contract_test.exs test/scoria/scope_doctrine_contract_test.exs test/scoria/adoption_surface_test.exs` - RED as expected: compiled, 39 tests run, 25 failures from missing canonical guide files, README old links, and public moduledocs missing guide/vocabulary fragments.
- Source assertions passed with `rg`: required `guides/capabilities/semantic-cache.md`, `guides/reviewer-verification.md`, `guides/reference/glossary.md`, `guides/ownership-boundary.md`, D-17 module names, `comparison_guide_path/0`, `glossary_guide_path/0`, and `adopter_doc_surfaces/0` canonical paths are present.

## Decisions Made

- This plan stops at RED contracts. It does not create guide files, update README links, or polish moduledocs; those are owned by later Phase 48 plans.
- Public moduledoc coverage is source-of-truth in `test/scoria/adoption_surface_test.exs` and uses compiled docs, not source-only regexes.
- Compatibility aliases remain documented as compatibility wrappers and are explicitly guarded against runtime `@deprecated` warnings during this phase.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None found in files modified by this plan. The scan matched existing asserted copy (`This Scoria dashboard is not available for this session.`) and test checks for non-empty moduledocs; neither is a stub.

## Issues Encountered

None. The nonzero verification commands are the expected RED outcome for this contract plan.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plans 48-03 through 48-05 can now create the canonical guide ladder against executable contracts. Plans 48-08, 48-09, 48-12, and 48-13 can green the D-17 public moduledoc assertions after the guide paths exist.

## Self-Check: PASSED

- Found modified files: `lib/scoria/adopter_doc_contract.ex`, `lib/scoria/hex_consumer_contract.ex`, `test/scoria/terminology_contract_test.exs`, `test/scoria/adoption_surface_test.exs`, `test/scoria/glossary_contract_test.exs`, and `test/scoria/scope_doctrine_contract_test.exs`.
- Found summary file: `.planning/phases/48-exdoc-and-guide-ladder-restructure/48-02-SUMMARY.md`.
- Found task commits: `ffe8223a`, `d1db06a9`.

---
*Phase: 48-exdoc-and-guide-ladder-restructure*
*Completed: 2026-07-10*
