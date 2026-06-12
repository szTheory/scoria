---
phase: 13-orientation-spine-ia
plan: "07"
subsystem: ui
tags: [phoenix-liveview, information-architecture, quality-loop]
requires:
  - phase: 13-orientation-spine-ia
    provides: Object-aware origin chips from plan 13-05
provides:
  - incident ingress links into workflow and trace evidence
  - review queue ingress links into workflow evidence
  - dataset promotion verb alignment
affects: [incidents, review-queue, workflow-origin-context]
tech-stack:
  added: []
  patterns:
    - base-aware dashboard links using `assigns[:scoria_base]`
    - encoded `from={noun}:{id}` origin query propagation
key-files:
  created: []
  modified:
    - lib/scoria_web/live/incidents_live/index.ex
    - lib/scoria_web/live/review_queue_live.ex
    - test/scoria_web/live/incidents_live_test.exs
    - test/scoria_web/live/review_queue_live_test.exs
key-decisions:
  - "Incidents link `Open trace at failing span` back to the home trace stream because there is no dedicated trace route yet."
  - "Review Queue renders base-aware action hrefs in the LiveView instead of relying on the older hardcoded projection paths."
patterns-established:
  - "Ingress links carry `from=incident:<id>` or `from=review:<id>` so destination object headers can render the allowlisted return context."
  - "Quality-loop threading stays as contextual verb links, not a loop rail, stepper, wizard, or current-step state."
requirements-completed: [IA-05]
duration: 6 min
completed: 2026-06-12
---

# Phase 13 Plan 07: Incident And Review Ingress Threading

**Incidents and review items now carry operators into run evidence with origin context**

## Performance

- **Duration:** 6 min
- **Started:** 2026-06-12T14:28:30Z
- **Completed:** 2026-06-12T14:34:21Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added LiveView tests proving selected incidents render `Open run` and `Open trace at failing span`.
- Added review queue tests proving the detail rail renders `Open run`, no longer renders `Open workflow`, and carries `from=review:<id>` on the workflow href.
- Added selected-incident tracking to the incident LiveView so the evidence pane can render next-step verbs beside the notebook.
- Added base-aware incident run and trace links with encoded `from=incident:<id>` query values.
- Updated Review Queue action links to use `@scoria_base`, preserve `review_candidate_id`, and append `from=review:<id>`.
- Renamed the queue promotion verb from `Promote candidate` to `Promote to dataset`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add ingress threading tests** - `ad0622c` (test)
2. **Task 2: Implement incident and review next-step links** - `3e66229` (feat)

## Files Created/Modified

- `test/scoria_web/live/incidents_live_test.exs` - Incident run/trace next-step link assertions.
- `test/scoria_web/live/review_queue_live_test.exs` - Review run href, origin propagation, and promotion verb assertions.
- `lib/scoria_web/live/incidents_live/index.ex` - Selected incident assign and base-aware next-step links.
- `lib/scoria_web/live/review_queue_live.ex` - Base-aware review action hrefs and dataset promotion verb.

## Decisions Made

- The incident trace link targets the dashboard home trace stream fragment with `from=incident:<id>` because trace details are currently a home-stream surface, not a routed object page.
- Query values are URL-encoded in rendered hrefs; tests decode them before asserting the semantic `from=` contract.
- Existing Review Queue projection paths were left unchanged to avoid widening this plan beyond the UI ingress threading surface.

## Deviations from Plan

- No DS-06 baseline change was needed. A first implementation used raw palette classes in the new incident links; the final implementation uses existing `scoria-button` classes instead.

**Total deviations:** 1 implementation correction. **Impact:** DS-06 ratchet remains tight.

## Issues Encountered

- Raw button palette classes in the incident link cluster triggered the DS-06 drift guard. Replaced them with semantic Scoria button classes.
- Review href assertions needed parsing through Floki because raw rendered HTML escapes `&` as `&amp;`.

## User Setup Required

None - no external service configuration required.

## Verification

- Red step: `mix test test/scoria_web/live/incidents_live_test.exs test/scoria_web/live/review_queue_live_test.exs --max-failures 1` - failed on missing incident `Open run`.
- Focused pass: `mix test test/scoria_web/live/incidents_live_test.exs test/scoria_web/live/review_queue_live_test.exs test/scoria_web/ds06_drift_guard_test.exs` - 9 tests, 0 failures.

## Self-Check: PASSED

- Incident pages render `Open run` when a workflow run exists.
- Incident pages render `Open trace at failing span` when trace evidence exists.
- Incident links carry decoded `from=incident:<id>` context.
- Review Queue renders `Open run` and carries decoded `from=review:<id>` context.
- Review Queue renders `Promote to dataset`.
- No loop rail, numbered stepper, wizard, or current-step state was added.
- DS-06 raw palette baseline did not change.

## Next Phase Readiness

Phase 13 can proceed to Plan 08, which threads egress from run and prompt release workbench actions back into quality-loop destinations.

---
*Phase: 13-orientation-spine-ia*
*Completed: 2026-06-12*
