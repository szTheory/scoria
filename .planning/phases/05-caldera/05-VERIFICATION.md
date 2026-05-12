---
phase: 05-caldera
status: passed
verified_on: 2026-05-11
---

# Phase 5 Verification Report

## Goal Achievement
Phase 5 now provides a durable workflow layer for Scoria with persisted runs, steps, checkpoints, events, approvals, and handoffs; supervised execution and recovery; a trace-first operator LiveView; and an explicit Jido adapter boundary.

## Requirements Coverage
- `WF-01`: Passed. Workflow truth persists in Ecto through `Scoria.Workflows`, workflow schemas, and migrations.
- `WF-02`: Passed. `Scoria.Workflows.Resume`, `Runtime`, and `Reconciler` cover exact resume and retry-failed-step from durable state.
- `WF-03`: Passed. Handoffs remain bounded child steps under a root-owned run with explicit role IDs and projected-context slices.
- `WF-04`: Passed. Approval waits persist durable workflow state before projection and approvals now link to workflow records.
- `WF-05`: Passed. `ScoriaWeb.WorkflowLive.Show` renders persisted workflow state with lifecycle badges, drilldown details, and a timeline.
- `WF-06`: Passed. Jido integration is limited to `Scoria.Workflows.JidoAdapter`, with unsupported directives rejected explicitly.
- `WF-07`: Passed. Workflow routes ship through the existing `scoria_dashboard` surface and existing installer story remains additive.

## Test Evidence
- `MIX_ENV=test mix test test/scoria/workflows_test.exs`
- `MIX_ENV=test mix test test/scoria/workflows/runtime_test.exs`
- `MIX_ENV=test mix test test/scoria_web/components/workflow_tree_component_test.exs test/scoria_web/live/workflow_live_test.exs test/scoria_web/router_test.exs test/mix/tasks/scoria.install_test.exs`
- `MIX_ENV=test mix test test/scoria/workflows/jido_adapter_test.exs test/scoria/workflows/integration_test.exs`
- `MIX_ENV=test mix test`

## Residual Risks
- Runtime handlers are still configured in-process rather than through a richer persisted execution registry.
- The workflow UI currently focuses on per-run inspection; broader run-list and operator controls remain future work.
