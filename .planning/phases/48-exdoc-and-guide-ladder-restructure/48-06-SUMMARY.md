---
phase: 48-exdoc-and-guide-ladder-restructure
plan: 06
subsystem: documentation
tags: [readme, guides, docs-links, guide-ladder]

requires:
  - phase: 48-exdoc-and-guide-ladder-restructure
    provides: 48-03 through 48-05 canonical guide bodies
provides:
  - README navigation links to the canonical Phase 48 guide ladder
  - README inline docs links moved from old flat docs paths to current guide names and paths
affects: [phase-48, readme, guide-ladder, adopter-docs]

tech-stack:
  added: []
  patterns:
    - README remains the GitHub/package front door while sending deeper docs navigation to canonical guides/ paths.
    - Old 0.1.x terminology is kept only as compatibility wording, not current navigation link text.

key-files:
  created:
    - .planning/phases/48-exdoc-and-guide-ladder-restructure/48-06-SUMMARY.md
  modified:
    - README.md

key-decisions:
  - "README Docs navigation is grouped by the Phase 48 guide ladder: Start Here, Capabilities, Operate & Verify, Compare & Decide, Reference, and Maintainers."
  - "README keeps current public guide names first while retaining one explicit 0.1.x semantic-fast-path compatibility sentence required by existing docs contracts."

patterns-established:
  - "README guide links should prefer canonical guides/... paths over old docs/*.md compatibility sources."

requirements-completed: [DOCS-03]

duration: 4m 52s
completed: 2026-07-10
status: complete
---

# Phase 48 Plan 06: README Guide Ladder Links Summary

**README navigation now points at the canonical Phase 48 guide ladder while keeping the README as the GitHub/package front door.**

## Performance

- **Duration:** 4m 52s
- **Started:** 2026-07-10T19:32:46Z
- **Completed:** 2026-07-10T19:37:38Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Replaced the old flat docs list with grouped links to the canonical `guides/` ladder: Getting Started, Golden Path, JTBD/User Flows, Ownership Boundary, Default Runtime, Bounded Handoffs, Semantic Cache, Connectors/MCP, Support Copilot Gallery, Reviewer Verification, Troubleshooting, comparison guide, cheatsheet, glossary, and maintainers guide.
- Updated inline README links for comparison, installer verification, bounded handoffs, semantic cache, connectors, support gallery, golden path/default runtime, and maintainer docs.
- Removed current-navigation links to old `docs/adoption_lanes.md`, `docs/semantic_fast_path.md`, `docs/operator_verification.md`, and `docs/scoria_vs_external_llm_ops.md`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite README docs links to canonical guides** - `8ffc56d5` (`docs`)

## Files Created/Modified

- `README.md` - Rewired Docs list and inline documentation links to canonical `guides/` paths.
- `.planning/phases/48-exdoc-and-guide-ladder-restructure/48-06-SUMMARY.md` - Records plan completion.

## Verification

- `rg -n "guides/getting-started.md|guides/golden-path.md|guides/capabilities/semantic-cache.md|guides/reviewer-verification.md|guides/scoria-vs-external-llm-ops.md|guides/reference/glossary.md" README.md && ! rg -n "\]\(docs/(adoption_lanes|semantic_fast_path|operator_verification|scoria_vs_external_llm_ops)\.md\)" README.md` - PASS.
- `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs:122 test/scoria/adoption_surface_test.exs:171 test/scoria/adoption_surface_test.exs:193 test/scoria/adoption_surface_test.exs:204 test/scoria/adoption_surface_test.exs:216 test/scoria/adoption_surface_test.exs:286` - PASS, 6 tests, 0 failures.
- `MIX_ENV=test mix test test/scoria/terminology_contract_test.exs test/scoria/adoption_surface_test.exs` - PARTIAL / expected still-RED outside README scope: 39 tests, 8 failures in D-17 public moduledoc guide links plus Golden Path, JTBD, and Bounded Handoffs guide fragments already logged in `deferred-items.md`.

## Decisions Made

- Kept README as a concise front door and avoided copying guide bodies into it.
- Retained one explicit 0.1.x compatibility note containing the old `semantic fast-path` wording because the existing docs contract still asserts that support sentence; current README navigation and primary wording use `Semantic Cache`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserved existing semantic-fast-path compatibility contract**
- **Found during:** Task 1 verification
- **Issue:** Replacing the old support sentence entirely with `semantic cache setup` caused the existing README contract to fail, even though current guide links were correct.
- **Fix:** Kept current `semantic cache setup` wording first and added the old sentence as an explicit 0.1.x compatibility note.
- **Files modified:** `README.md`
- **Verification:** README-specific adoption surface tests passed, 6 tests, 0 failures.
- **Committed in:** `8ffc56d5`

**Total deviations:** 1 auto-fixed (Rule 1 bug)
**Impact on plan:** The fix preserved current terminology while keeping existing compatibility contracts green.

## Issues Encountered

- The broad stable-doc command still fails outside the 48-06 README file set. Remaining failures match the already-recorded Phase 48 deferred items: Golden Path compatibility fragments, JTBD bounded-handoff wording, Bounded Handoffs first-run fragment, and D-17 public moduledoc guide links.

## Known Stubs

None found in `README.md`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 48-07 can wire ExDoc extras/groups against the canonical guide paths now linked from README. Later public moduledoc and guide-fragment plans still need to close the remaining adoption-surface RED failures documented in `deferred-items.md`.

## Self-Check: PASSED

- Found modified file: `README.md`.
- Found summary file: `.planning/phases/48-exdoc-and-guide-ladder-restructure/48-06-SUMMARY.md`.
- Found task commit: `8ffc56d5`.

---
*Phase: 48-exdoc-and-guide-ladder-restructure*
*Completed: 2026-07-10*
