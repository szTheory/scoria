---
phase: 41-proof-docs-and-regression-guardrails
plan: 02
subsystem: testing
tags: [phoenix-liveview, floki, exunit, regression-guard, drift-guard]

# Dependency graph
requires:
  - phase: 41-proof-docs-and-regression-guardrails (plan 01)
    provides: PROOF-03 gap analysis identifying GAP-A (D-06) as the single required net-new rendered-DOM guard
provides:
  - Rendered-DOM guard closing single_header_guard_test.exs:28-30's self-declared deferral
  - PROOF-03's 8th named regression (redundant single-region header) now has a live blocking guard
affects: [41-03, 41-05]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Rendered-DOM Floki assertion as the semantic-redundancy proof layer above a static-literal source scan (source scan for cheap breadth, rendered-DOM for the cases it structurally cannot see)"
    - "Per-test-file Router+Endpoint+ErrorView boilerplate (no shared ConnCase) — mirrors review_queue_live_test.exs"
    - "Honesty-caveat moduledoc documenting exactly which routes are out of scope and why (mirrors dev_lab_boundary_test.exs Guard #7)"

key-files:
  created:
    - test/scoria_web/single_header_rendered_guard_test.exs
  modified: []

key-decisions:
  - "New guard module is async: false (real LiveView render + DB) and kept separate from the async: true, no-DB single_header_guard_test.exs source-scan module rather than merging async settings."
  - "Covered exactly the 9 static/index live routes (/, /approvals, /reviews, /datasets, /workflows, /connectors, /incidents, /eval_specs, /prompts) that render via page_header/1 without a specific record ID."
  - "Skipped /workflows/:id, /incidents/:id, /prompts/:id/release (object_header/1 pages — no free-text :title slot to compare against, so the restatement check is structurally inapplicable) and /coming/:screen (ComingSoonLive never pairs page_header/1 or stub_page/1 with a panel/page_section :title slot, so there is no region title to compare at all) — documented in the moduledoc as an honesty caveat, not a fixture-cost shortcut."
  - "CSS selectors verified directly against lib/scoria_web/ui.ex before landing (Assumption A2): page title is .scoria-pagehead__title h1; region titles are .scoria-panel__header h2 and .scoria-page-section__header h2."

patterns-established:
  - "When a source-scan drift guard self-declares a coverage gap in its own moduledoc, close it with a sibling rendered-DOM test file (not a rewrite of the source-scan guard) so the cheap/broad and expensive/precise checks stay independently maintainable."

requirements-completed: [PROOF-03]

coverage:
  - id: D1
    description: "Rendered-DOM guard (single_header_rendered_guard_test.exs) proves no region title restates the rendered page title across all 9 covered static/index routes, closing the single_header_guard_test.exs:28-30 deferral."
    requirement: "PROOF-03"
    verification:
      - kind: unit
        ref: "test/scoria_web/single_header_rendered_guard_test.exs (9 parameterized tests, one per route)"
        status: pass
    human_judgment: false

# Metrics
duration: 20min
completed: 2026-07-04
status: complete
---

# Phase 41 Plan 02: D-06 Rendered-DOM Region-Title-Restatement Guard Summary

**New `async: false` Floki-over-rendered-HTML guard renders all 9 static/index dashboard routes via `Phoenix.LiveViewTest.live/2` and asserts no `panel`/`page_section` region title restates the page's own `page_header/1` `<h1>` text — closing the dynamic/interpolated blind spot the existing static-literal source-scan guard (`single_header_guard_test.exs:28-30`) self-declares it cannot see.**

## Performance

- **Duration:** ~20 min
- **Completed:** 2026-07-04
- **Tasks:** 1
- **Files modified:** 1 (created)

## Accomplishments
- Authored `test/scoria_web/single_header_rendered_guard_test.exs`: a net-new sibling guard module that renders each of the 9 covered routes for real, parses the output HTML with `Floki`, and refutes any region title case-insensitively equaling the rendered page title.
- Verified the exact CSS selectors against `lib/scoria_web/ui.ex`'s actual rendered markup (Assumption A2) rather than trusting the research sketch's shape-only example: `.scoria-pagehead__title h1` for the page title, `.scoria-panel__header h2` / `.scoria-page-section__header h2` for region titles.
- Documented the 4 skipped param routes (`/workflows/:id`, `/incidents/:id`, `/prompts/:id/release`, `/coming/:screen`) in the moduledoc with the actual structural reason each is out of scope (object_header pages have no `:title` slot at all; `ComingSoonLive` never pairs a header with a region `:title` slot), mirroring `dev_lab_boundary_test.exs`'s "honesty caveat" precedent.
- This closes PROOF-03's 8th and final named regression — all eight now have a live blocking guard (the other seven per D-05 from prior plans/phases).

## Task Commits

Each task was committed atomically:

1. **Task 1: Author the D-06 rendered-DOM region-title-restatement guard** - `bda1d0e2` (test)

**Plan metadata:** (recorded below after STATE/ROADMAP update)

## Files Created/Modified
- `test/scoria_web/single_header_rendered_guard_test.exs` - New `ScoriaWeb.SingleHeaderRenderedGuardTest` module: per-file Router+Endpoint+ErrorView boilerplate (mirrors `review_queue_live_test.exs`), 9 parameterized route tests, Floki-based page-title/region-title extraction, honesty-caveat moduledoc.

## Decisions Made
- Kept the new guard as its own module (`async: false`) rather than adding to the existing `async: true` source-scan module, since it needs a real DB-backed LiveView render — avoids mixing async settings within one test module.
- Verified `object_header/1` genuinely has no `:title` slot (confirmed by reading `lib/scoria_web/ui.ex:494-537`) before writing the skip rationale, rather than assuming from the plan text alone.
- Confirmed `ComingSoonLive` (`lib/scoria_web/live/coming_soon_live.ex`) never renders a `panel`/`page_section` region at all, so the skip rationale for `/coming/:screen` is "no comparable surface to test," not merely "it's a param route."

## Deviations from Plan

None - plan executed exactly as written. All 9 tests passed on first run against current source (Phase 40 already remediated the real region-title-restatement defects this guard would have caught); `mix compile --warnings-as-errors` is clean; the sibling `single_header_guard_test.exs` and `dev_lab_boundary_test.exs` suites remain green (21 tests, 0 failures) confirming no regression.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- PROOF-03 is now fully guarded: all 8 named regressions have a live blocking guard, closing the one gap (GAP-A) a source scan structurally cannot cover.
- Plan 03 (design_system.md accessibility/headers sections) and Plan 05 (evidence manifest) can reference this guard's final selectors and documented skip list directly from this SUMMARY.

---
*Phase: 41-proof-docs-and-regression-guardrails*
*Completed: 2026-07-04*

## Self-Check: PASSED
- FOUND: test/scoria_web/single_header_rendered_guard_test.exs
- FOUND: .planning/phases/41-proof-docs-and-regression-guardrails/41-02-SUMMARY.md
- FOUND commit: bda1d0e2
