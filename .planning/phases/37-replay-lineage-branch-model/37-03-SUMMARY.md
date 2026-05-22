# Phase 37 Plan 03: Replay Lineage Operator Surfaces Summary

## Summary
Exposed replay lineage on the public run-detail surface and both workflow and trace-facing operator UIs. Replay provenance now renders from stable DTO fields instead of template-side metadata scraping.

## Delivered
- Extended `Scoria.Runtime.RunSummary` with lightweight replay identification fields.
- Extended `Scoria.Runtime.RunDetail` with a dedicated `replay_lineage` block carrying source run id, source checkpoint id, execution mode, and overrides.
- Updated `WorkflowLive.Show` and `WorkflowDetailPanelComponent` to render replay provenance from the DTO surface.
- Updated `OrchestratorLive` to project replay lineage for run-linked traces and show replay branch badges/context.
- Added or extended `test/scoria/runtime_view_test.exs`, `test/scoria_web/live/workflow_live_test.exs`, and `test/scoria_web/live/orchestrator_live_test.exs`.

## Verification
- `mix test test/scoria/runtime_view_test.exs test/scoria_web/live/workflow_live_test.exs test/scoria_web/live/orchestrator_live_test.exs`

## Notes
- The trace-facing UI remains a projection over workflow truth; this plan does not add a second replay lineage store.
- No commit was created during this execution.
