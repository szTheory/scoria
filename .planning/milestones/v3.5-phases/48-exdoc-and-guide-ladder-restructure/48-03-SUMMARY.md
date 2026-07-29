---
phase: 48-exdoc-and-guide-ladder-restructure
plan: 03
subsystem: documentation
tags: [guides, hexdocs, start-here, docs-contracts]

requires:
  - phase: 48-exdoc-and-guide-ladder-restructure
    provides: "48-01 and 48-02 RED guide/exdoc/stable-doc contracts"
  - phase: 47-readme-first-screen-positioning-and-scope-doctrine
    provides: README embedded-Phoenix positioning and public ownership-boundary table
provides:
  - Start Here guide files for Getting Started, Golden Path, JTBD/user flows, Ownership Boundary, and Cheatsheet
  - Canonical default-runtime-first guide path with `identity -> start -> inspect -> resume`
  - Ownership-boundary guide carrying the public owns-vs-delegates table
affects: [phase-48, guides, hexdocs, adopter-docs]

tech-stack:
  added: []
  patterns:
    - Canonical `guides/` paths used in Start Here links before README/exdoc rewiring
    - Default runtime capability stays first; semantic cache, knowledge, and connectors remain optional expansions
    - Ownership-boundary table duplicated into canonical guide source for docs contract coverage

key-files:
  created:
    - guides/getting-started.md
    - guides/golden-path.md
    - guides/jtbd-and-user-flows.md
    - guides/ownership-boundary.md
    - guides/cheatsheet.cheatmd
    - .planning/phases/48-exdoc-and-guide-ladder-restructure/48-03-SUMMARY.md
  modified: []

key-decisions:
  - "Start Here guides link to canonical `guides/...` paths even where later sibling plans still own the target guide bodies."
  - "The first-run guide ladder keeps the default runtime capability before optional semantic cache, knowledge, or connector setup."
  - "The ownership-boundary guide carries the same public owns-vs-delegates table shape as README so scope doctrine stays executable."

patterns-established:
  - "Start Here docs open from product positioning, then move to copyable runtime steps and only then to optional capability expansion."
  - "Guide content uses reviewer/capability/verification-suite vocabulary and keeps old lane/operator names out of new canonical Start Here docs."

requirements-completed: [DOCS-01, DOCS-03]

duration: 5m 41s
completed: 2026-07-10
status: complete
---

# Phase 48 Plan 03: Start Here Guide Ladder Summary

**Start Here guide ladder with Getting Started, Golden Path, JTBD/user flows, ownership boundary, and cheatsheet content for the new canonical `guides/` surface.**

## Performance

- **Duration:** 5m 41s
- **Started:** 2026-07-10T18:54:03Z
- **Completed:** 2026-07-10T18:59:44Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Created `guides/getting-started.md` as the intended HexDocs first page with embedded-Phoenix positioning, install/migration/dashboard setup, first identity, first run, inspect, and resume steps.
- Created `guides/golden-path.md` around the exact `identity -> start -> inspect -> resume` order, including `session_id` versus `run_id`, host-authenticated dashboard scope, and default-runtime optionality.
- Created `guides/jtbd-and-user-flows.md`, `guides/ownership-boundary.md`, and `guides/cheatsheet.cheatmd` with Core/Adjacent/Not-Scoria framing, the public owns-vs-delegates table, compact commands, and canonical guide links.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Getting Started and Golden Path guides** - `c22ba0b6` (`docs`)
2. **Task 2: Create JTBD, ownership boundary, and cheatsheet guides** - `12defdb9` (`docs`)

## Files Created/Modified

- `guides/getting-started.md` - HexDocs first-run guide with install, migration, dashboard mount, identity, first run, inspect, resume, and verification path.
- `guides/golden-path.md` - Copyable `identity -> start -> inspect -> resume` walkthrough with `session_id`/`run_id` and default runtime footguns.
- `guides/jtbd-and-user-flows.md` - Role/JTBD and capability-ladder guide using Core, Adjacent, and Not Scoria surface language.
- `guides/ownership-boundary.md` - Canonical ownership-boundary guide with the public Scoria-vs-host responsibility table.
- `guides/cheatsheet.cheatmd` - Compact ExDoc cheatsheet covering install, first run, dashboard mount, verification suites, semantic cache, handoffs, connectors/MCP, and troubleshooting links.

## Test Evidence

- `test -f guides/getting-started.md && test -f guides/golden-path.md && rg -n "Scoria is an Elixir/Phoenix library|identity -> start -> inspect -> resume|guides/reference/glossary.md|session_id|run_id" guides/getting-started.md guides/golden-path.md` - passed.
- `test -f guides/jtbd-and-user-flows.md && test -f guides/ownership-boundary.md && test -f guides/cheatsheet.cheatmd && rg -n "Core:|Adjacent:|Not Scoria's surface:|What Scoria owns vs what your app owns|mix scoria.install|Scoria.start_run" guides/jtbd-and-user-flows.md guides/ownership-boundary.md guides/cheatsheet.cheatmd && ! rg -n "The Four Lanes|Keystone|v2\\.0 Relay" guides/jtbd-and-user-flows.md guides/ownership-boundary.md guides/cheatsheet.cheatmd` - passed.
- `MIX_ENV=test mix test test/scoria/scope_doctrine_contract_test.exs` - passed: 5 tests, 0 failures.

The broader `test/scoria/terminology_contract_test.exs` and `test/scoria/adoption_surface_test.exs` suites were not rerun as final acceptance because later Wave 2/3 plans still own the remaining canonical guide files, README rewiring, and public moduledoc links.

## Decisions Made

- Used canonical `guides/...` link literals in new docs so the RED contracts can see final paths before ExDoc and README are rewired.
- Kept the Start Here group focused on first adoption and reviewer workflow; capability guide bodies, glossary, reviewer verification, comparison, and maintainer migration remain with their sibling Phase 48 plans.
- Reused the README ownership table shape in `guides/ownership-boundary.md` so the public scope doctrine has a canonical guide home.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- A one-off attempt to run an ExUnit test by name with `--only` selected zero tests. The valid plan assertions and `scope_doctrine_contract_test.exs` were run instead.

## Known Stubs

None found in files created by this plan.

## Threat Flags

None. This plan created Markdown guide content only and introduced no new runtime endpoint, auth path, file access pattern, schema change, or package dependency.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 48-04 can add the capability and glossary guide bodies referenced from these Start Here pages. Plan 48-05 can add reviewer verification, troubleshooting, comparison, and maintainer guide bodies. Plan 48-06 can then rewire README links to the canonical `guides/` paths.

## Self-Check: PASSED

- Found created guide files: `guides/getting-started.md`, `guides/golden-path.md`, `guides/jtbd-and-user-flows.md`, `guides/ownership-boundary.md`, and `guides/cheatsheet.cheatmd`.
- Found summary file: `.planning/phases/48-exdoc-and-guide-ladder-restructure/48-03-SUMMARY.md`.
- Found task commits: `c22ba0b6`, `12defdb9`.

---
*Phase: 48-exdoc-and-guide-ladder-restructure*
*Completed: 2026-07-10*
