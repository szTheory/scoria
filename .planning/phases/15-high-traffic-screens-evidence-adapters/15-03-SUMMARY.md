---
phase: 15-high-traffic-screens-evidence-adapters
plan: "03"
subsystem: ui
tags: [phoenix-liveview, workflow-show, trace-explorer, design-system, ds06]

requires:
  - phase: 15-high-traffic-screens-evidence-adapters
    plan: "01"
    provides: Shared evidence primitives and UI gateway components
provides:
  - Workflow Show rendered as the canonical shared-component trace inspector
  - Tokenized workflow tree, trace tree, and selected-step detail components
  - Shared modal boundary for Dataset Builder promotion
  - Reduced DS-06 baseline rows for Workflow Show/tree/detail components
affects:
  - phase-15-high-traffic-screens
  - workflow-show
  - trace-explorer
  - dataset-promotion-ingress

tech-stack:
  added: []
  patterns:
    - Workflow Show uses shared object header, panels, badges, modal, evidence rows, and action rows
    - Tree/detail components keep behavior while delegating visual state to `scoria-*` classes
    - Runtime focus links derive from `assigns[:scoria_base] || ""`

key-files:
  created: []
  modified:
    - lib/scoria_web/live/workflow_live/show.ex
    - lib/scoria_web/components/workflow_tree_component.ex
    - lib/scoria_web/components/trace_tree_component.ex
    - lib/scoria_web/components/workflow_detail_panel_component.ex
    - test/scoria_web/live/workflow_live_test.exs
    - test/scoria_web/components/trace_tree_component_test.exs
    - test/scoria_web/components/workflow_tree_component_test.exs
    - test/support/ds06_baseline.txt

key-decisions:
  - "Workflow Show remains the backed APM-style run/trace inspector; no TraceQL, flame graph, service map, session browser, or analytics modes were added."
  - "Dataset Builder promotion remains owned by `DatasetLive.PromoteComponent`; this plan only replaced the local overlay with the shared modal shell."
  - "SCREEN-03 and SCREEN-04 remain pending until Approvals/Connectors and the final evidence adapter sweep land."

patterns-established:
  - "Use `<.modal>` for promotion confirmation boundaries instead of local fixed overlays."
  - "Use source-contract tests for DS-06-sensitive high-traffic components so raw palette leakage cannot quietly return."
  - "Use `scoria-span` rows plus semantic helper classes for trace/workflow trees instead of palette utility classes."

requirements-completed: []

duration: 4 min
completed: 2026-06-13
---

# Phase 15 Plan 03: Workflow Trace Inspector Summary

**Workflow Show now uses shared surfaces for the run header, next-step verbs, replay provenance, notices, tree, selected-step detail, timeline, and promotion modal.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-13T01:14:46Z
- **Completed:** 2026-06-13T01:18:42Z
- **Tasks:** 2 completed
- **Files modified:** 8

## Accomplishments

- Converted Workflow Show’s local page shell, replay strip, promotion/baseline notices, review candidate evidence, memory failure state, timeline, and promotion overlay to shared UI primitives.
- Replaced the hard-coded `/scoria?runtime=...` runtime presence link source with a mount-prefix-safe helper.
- Converted `WorkflowTreeComponent` and `TraceTreeComponent` away from raw palette classes while preserving selection, indentation, lazy metadata, and token preview behavior.
- Converted `WorkflowDetailPanelComponent` to a shared panel with evidence rows and semantic button classes while preserving promotion disabled logic and evidence notebook rendering.
- Removed four stale DS-06 baseline rows after the drift guard confirmed the touched files now have zero raw palette matches.

## Task Commits

1. **Task 1/2 RED: Add Workflow Show/tree shared-shell contracts** - `efe8337` (test)
2. **Task 1/2 GREEN: Convert Workflow Show/tree/detail surfaces** - `8761e85` (feat)

**Plan metadata:** pending in this summary commit.

## Files Created/Modified

- `lib/scoria_web/live/workflow_live/show.ex` - Uses shared object header, action row, panels, modal, badges, evidence rows, and mount-prefix-safe runtime links.
- `lib/scoria_web/components/workflow_tree_component.ex` - Keeps `select_step`, selected row state, status badge, role, kind, and handoff marker with tokenized classes.
- `lib/scoria_web/components/trace_tree_component.ex` - Keeps flat rows, `phx-target={@myself}` lazy metadata, token previews, and `--indent-level` styles with tokenized classes.
- `lib/scoria_web/components/workflow_detail_panel_component.ex` - Uses a shared panel and evidence rows while preserving promotion disabled logic and notebook rendering.
- `test/scoria_web/live/workflow_live_test.exs` - Adds source contracts for shared modal/object header/runtime link and raw-palette removal.
- `test/scoria_web/components/trace_tree_component_test.exs` - Adds token-preview and source contracts for tokenized TraceTree behavior.
- `test/scoria_web/components/workflow_tree_component_test.exs` - Adds source contract for selection behavior without raw palette classes.
- `test/support/ds06_baseline.txt` - Removes Workflow Show/tree/detail rows after scanner counts reached zero.

## Decisions Made

- Kept `Replay run`, `Promote in Dataset Builder`, `Open incident`, `Open prompt`, and `View associated runtime presence` as flat backed next-step verbs.
- Used shared panels for promotion/baseline notices rather than adding a toast queue or new status component.
- Kept detail evidence notebooks owned by their existing components; this plan only removed the selected-detail local shell.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

- The first GREEN test pass had only DS-06 stale-baseline failures, confirming behavior was intact before tightening the baseline.

## Verification

- `mix test test/scoria_web/live/workflow_live_test.exs test/scoria_web/components/trace_tree_component_test.exs test/scoria_web/components/workflow_tree_component_test.exs test/scoria_web/ds06_drift_guard_test.exs` - passed, 28 tests, 0 failures.
- Source assertions confirmed `workflow_live/show.ex` contains `<.modal`, `<.object_header`, and `View associated runtime presence`.
- Source assertions confirmed no hard-coded `href={"/scoria?runtime=` expression remains.
- Source assertions confirmed `TraceTreeComponent`, `WorkflowTreeComponent`, and `WorkflowDetailPanelComponent` preserve key event/component hooks.
- Source assertions confirmed no forbidden raw palette strings remain in the four touched source files.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 15-04 can now convert Approvals and Connectors to the same shared table/drawer/modal patterns with the Workflow Show trace inspector available as the backed destination.

## Self-Check: PASSED

- [x] All planned tasks executed.
- [x] Task work committed.
- [x] SUMMARY.md created.
- [x] Focused verification passed.
- [x] DS-06 baseline reductions verified by drift guard.

---
*Phase: 15-high-traffic-screens-evidence-adapters*
*Completed: 2026-06-13*
