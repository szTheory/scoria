---
phase: 15-high-traffic-screens-evidence-adapters
plan: "02"
subsystem: ui
tags: [phoenix-liveview, design-system, high-traffic-screens, ds06]

requires:
  - phase: 15-high-traffic-screens-evidence-adapters
    plan: "01"
    provides: Shared evidence primitives and token-bound evidence rows/action rows
provides:
  - Status-first Home trace stream with compact badges and design-system deep links
  - Runs index rendered through the shared table component
  - Reduced DS-06 baseline rows for Home and Runs
affects:
  - phase-15-high-traffic-screens
  - home-live-ops
  - workflow-runs-index

tech-stack:
  added: []
  patterns:
    - Home trace cards use shared panels, badges, IDs, evidence rows, and action rows
    - Runs index uses `<.table id="runs">` with compact density and a single backed Open trace action

key-files:
  created: []
  modified:
    - lib/scoria_web/live/orchestrator_live.ex
    - lib/scoria_web/live/workflow_live/index.ex
    - test/scoria_web/live/orchestrator_live_test.exs
    - test/scoria_web/live/orchestrator_live_sre_test.exs
    - test/scoria_web/live/workflow_live_test.exs
    - test/support/ds06_baseline.txt

key-decisions:
  - "Home remains a read-only triage/status surface; lazy provenance, replay, promotion, and incident notebook controls were removed from Home."
  - "Trace badge enrichment happens when traces are opened or spans are upserted so SRE budget/breaker/incident state stays visible without lazy Home controls."
  - "SCREEN-03 remains pending until Workflow Show, Approvals, and Connectors are converted by later plans."

patterns-established:
  - "Home stream rows use shared `<.panel>`, `<.badge>`, `<.id>`, and `<.evidence_action_row>` instead of local raised-card markup."
  - "Runs scan surfaces should prefer shared `<.table>` empty/action slots over literal table markup."
  - "Mount-prefix-safe links receive `assigns[:scoria_base] || \"\"` or pass that base into a helper."

requirements-completed: []

duration: 6 min
completed: 2026-06-13
---

# Phase 15 Plan 02: Home and Runs Shared Surfaces Summary

**Home is now a compact read-only trace stream, and Runs is a shared-component scan table.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-06-13T01:06:13Z
- **Completed:** 2026-06-13T01:11:28Z
- **Tasks:** 2 completed
- **Files modified:** 6

## Accomplishments

- Converted Home trace rows from local raised cards and six workbench buttons into shared panels with compact badges, trace IDs, streamed spans, and backed deep links.
- Removed Home lazy evidence/replay/promote event handlers and their raw evidence panels.
- Enriched Home trace badges from `OperatorSurface.compact_trace_badges/2` during hydration/open/upsert paths so budget, breaker, review, and paging signals remain visible.
- Converted the Runs index to `<.table id="runs">` with Run, Status, Runtime, Started, and Open trace action columns.
- Replaced Home and Runs empty-state copy with the Phase 15 UI-SPEC copy.
- Removed the Home and Runs rows from the DS-06 baseline after the drift guard passed.

## Task Commits

1. **Task 1/2 RED: Add Home and Runs shared-surface tests** - `d306006` (test)
2. **Task 1/2 GREEN: Convert Home and Runs to shared surfaces** - `9c09764` (feat)

**Plan metadata:** pending in this summary commit.

## Files Created/Modified

- `lib/scoria_web/live/orchestrator_live.ex` - Replaces Home trace workbench controls with shared-panel summaries, compact badges, and run/trace/incident deep links.
- `lib/scoria_web/live/workflow_live/index.ex` - Renders the Runs index through the shared table component with compact density.
- `test/scoria_web/live/orchestrator_live_test.exs` - Updates stream DOM expectations and asserts removed Home controls stay absent.
- `test/scoria_web/live/orchestrator_live_sre_test.exs` - Verifies budget, breaker, review, and page signals render as compact Home badges without lazy controls.
- `test/scoria_web/live/workflow_live_test.exs` - Verifies the shared Runs table, empty copy, and Open trace navigation.
- `test/support/ds06_baseline.txt` - Removes Home and Runs baseline rows after the scanner count reached zero for those files.

## Decisions Made

- Kept both `Open run` and `Open trace` on Home mapped to `/workflows/:id`, matching the current canonical run trace inspector.
- Did not render incident links unless compact trace badge data proves review or page incident state exists.
- Left SCREEN-03 pending because Plans 15-03 and 15-04 still own Workflow Show, Approvals, and Connectors.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

- LiveView stream IDs include the stream name prefix, so the duplicate-trace expectation changed from `trace-dup-1` to `traces-trace-dup-1`.
- SRE badge copy was normalized to title case for user-facing labels.

## Verification

- `mix test test/scoria_web/live/orchestrator_live_test.exs test/scoria_web/live/orchestrator_live_integration_test.exs test/scoria_web/live/orchestrator_live_sre_test.exs test/scoria_web/live/workflow_live_test.exs test/scoria_web/ds06_drift_guard_test.exs` - passed, 39 tests, 0 failures.
- Source assertions confirmed `lib/scoria_web/live/orchestrator_live.ex` no longer renders `Load Deep Metadata`, `Load Retrieval Evidence`, `Load Budget State`, `Load Incident Evidence`, `Replay Retrieval`, or `Promote Retrieval`.
- Source assertions confirmed `lib/scoria_web/live/workflow_live/index.ex` contains `<.table id="runs">` and the exact Runs subtitle.
- Source assertions confirmed no raw palette matches remain in the two touched LiveView source files.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 15-03 can now convert Workflow Show / Trace Explorer while reusing the same table, panel, modal, badge, ID, and evidence primitives.

## Self-Check: PASSED

- [x] All planned tasks executed.
- [x] Task work committed.
- [x] SUMMARY.md created.
- [x] Focused verification passed.
- [x] DS-06 baseline reductions verified by drift guard.

---
*Phase: 15-high-traffic-screens-evidence-adapters*
*Completed: 2026-06-13*
