# Phase 05 Plan 03: Workflow Operator Surface Summary

## Summary
Added a trace-first workflow run view under the existing Scoria dashboard routing surface. The UI reads persisted workflow state, shows lifecycle badges and a compact workflow tree, and exposes checkpoint metadata and timeline details without moving workflow truth into LiveView.

## Delivered
- Added `ScoriaWeb.WorkflowLive.Show`.
- Added `WorkflowTreeComponent` and `WorkflowDetailPanelComponent`.
- Extended `scoria_dashboard` routing with `/workflows/:id`.
- Updated the install task description to reflect workflow-route support.
- Added component, LiveView, and router tests for the new operator surface.

## Verification
- `MIX_ENV=test mix test test/scoria_web/components/workflow_tree_component_test.exs test/scoria_web/live/workflow_live_test.exs test/scoria_web/router_test.exs test/mix/tasks/scoria.install_test.exs`

## Notes
- The default mental model stays trace-first, with timeline details as a secondary drilldown.
