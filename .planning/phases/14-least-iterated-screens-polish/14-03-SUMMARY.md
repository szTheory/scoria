---
phase: 14-least-iterated-screens-polish
plan: "03"
subsystem: ui
tags: [liveview, review-queue, dataset-builder, ds06, shared-components]
requires:
  - phase: 14-02
    provides: Dataset Builder promotion entry point
provides:
  - Shared-component Review Queue ingress surface
  - Dataset Builder promotion links from Review Queue and Workflow Show
  - Zero raw-palette leakage for Review Queue
affects: [phase-14, phase-15, dataset-builder, review-queue, workflow-show]
tech-stack:
  added: []
  patterns:
    - Source screens link to Dataset Builder for promotion ownership
    - Review Queue uses ScoriaWeb.UI metric, field, table, badge, panel, and empty-state components
key-files:
  created:
    - .planning/phases/14-least-iterated-screens-polish/14-03-SUMMARY.md
  modified:
    - lib/scoria_web/live/review_queue_live.ex
    - test/scoria_web/live/review_queue_live_test.exs
    - lib/scoria_web/live/workflow_live/show.ex
    - test/scoria_web/live/workflow_live_test.exs
    - lib/scoria_web/ui.ex
    - test/support/ds06_baseline.txt
key-decisions:
  - "Review Queue no longer owns direct dataset or sealed-baseline promotion mutations; it links into Dataset Builder with stable source IDs."
  - "Workflow Show renders a Dataset Builder promotion link for the selected step and leaves Dataset Builder to validate promotion context."
patterns-established:
  - "Review Queue table actions expose visible Selected text and aria-current for selected state."
  - "DS-06 baseline rows are removed only after the corresponding LiveView reaches zero raw-palette matches."
requirements-completed: [SCREEN-01, SCREEN-02]
duration: 14 min
completed: 2026-06-12
---

# Phase 14 Plan 03: Review Queue Shared-Component Ingress Summary

**Review Queue now uses shared components and routes all promotion ownership into Dataset Builder while Workflow Show provides the same Dataset Builder handoff.**

## Performance

- **Duration:** 14 min
- **Started:** 2026-06-12T20:34:00Z
- **Completed:** 2026-06-12T20:48:27Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Replaced Review Queue direct dataset selection, direct promotion, and sealed-baseline request controls with `Promote in Dataset Builder` and `Request baseline approval in Dataset Builder` links.
- Replaced Workflow Show's next-step promotion button with a Dataset Builder link carrying `promote=workflow`, `run_id`, `step_id`, `source_variant`, and `from=run:<id>`.
- Converted Review Queue's page shell to shared metrics, fields, table, badges, panels, and empty-state components.
- Removed Review Queue from the DS-06 raw-palette baseline after verifying the file has zero raw-palette matches.

## Task Commits

1. **Task 1: Route Review Queue and Workflow promotion affordances to Dataset Builder** - `9687adf` (feat)
2. **Task 2: Convert Review Queue to shared components and update DS-06** - `51299ae` (test)

**Plan metadata:** pending in this commit.

## Files Created/Modified

- `lib/scoria_web/live/review_queue_live.ex` - Shared-component Review Queue surface, Dataset Builder promotion links, direct promotion handlers removed.
- `test/scoria_web/live/review_queue_live_test.exs` - Assertions for Dataset Builder routing, required table columns, selected state semantics, and preserved dismiss behavior.
- `lib/scoria_web/live/workflow_live/show.ex` - Dataset Builder promotion next-step link from Workflow Show.
- `test/scoria_web/live/workflow_live_test.exs` - Workflow Dataset Builder routing assertions.
- `lib/scoria_web/ui.ex` - Allows `aria-current` through shared button attrs for selected Review Queue row semantics.
- `test/support/ds06_baseline.txt` - Removed stale Review Queue baseline row.

## Decisions Made

- Review Queue links to Dataset Builder instead of invoking `Eval.promote_review_candidate/2` or `Eval.request_review_candidate_baseline_approval/2` locally, matching the Phase 14 ownership split.
- Workflow Show now links to Dataset Builder whenever a step is selected, because Dataset Builder is the server-side validator for the promotion context.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first Workflow Show test pass hid the Dataset Builder link when the old modal promotion context was absent. The link now renders for a selected step and passes stable IDs to Dataset Builder for validation.

## Verification

- `mix test test/scoria_web/live/review_queue_live_test.exs test/scoria_web/live/workflow_live_test.exs` - 18 tests, 0 failures.
- `mix test test/scoria_web/live/review_queue_live_test.exs test/scoria_web/live/workflow_live_test.exs test/scoria_web/ds06_drift_guard_test.exs && ! grep -E '^lib/scoria_web/live/review_queue_live\.ex:' test/support/ds06_baseline.txt` - 21 tests, 0 failures, no Review Queue baseline row.
- `rg -n "\b(stone|rose|sky|emerald|amber|blue|gray|slate|zinc|neutral|red|green|yellow|purple|pink|indigo|teal|cyan|lime|orange|violet|fuchsia)-\d" lib/scoria_web/live/review_queue_live.ex` - no matches.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 14-06 can now build on the same Dataset Builder promotion ownership pattern and continue reducing DS-06 raw-palette leakage in Prompt Registry and Release Workbench.

---
*Phase: 14-least-iterated-screens-polish*
*Completed: 2026-06-12*
