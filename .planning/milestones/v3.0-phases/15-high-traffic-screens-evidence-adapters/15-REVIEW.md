---
phase: 15-high-traffic-screens-evidence-adapters
status: clean
review_depth: standard
review_mode: inline
files_reviewed: 22
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
resolved_during_review:
  - id: CR-15-001
    severity: warning
    summary: "Shared table density controls emitted unowned set_density events"
    fixed_by: 0fc2ff7
  - id: CR-15-002
    severity: warning
    summary: "Shared table sort controls emitted unowned sort events"
    fixed_by: b23f530
created: 2026-06-13
---

# Phase 15 Code Review

Status: clean after review fixes.

## Scope

Reviewed the Phase 15 implementation surface from the phase summaries:

- `assets/css/04-components.css`
- `lib/scoria_web/components/approval_inbox_component.ex`
- `lib/scoria_web/components/citation_evidence_component.ex`
- `lib/scoria_web/components/connector_detail_drawer_component.ex`
- `lib/scoria_web/components/delegated_evidence_component.ex`
- `lib/scoria_web/components/incident_evidence_component.ex`
- `lib/scoria_web/components/memory_notebook_component.ex`
- `lib/scoria_web/components/remote_invocation_evidence_component.ex`
- `lib/scoria_web/components/replay_evidence_notebook_component.ex`
- `lib/scoria_web/components/runtime_detail_drawer_component.ex`
- `lib/scoria_web/components/semantic_evidence_notebook_component.ex`
- `lib/scoria_web/components/trace_tree_component.ex`
- `lib/scoria_web/components/workflow_detail_panel_component.ex`
- `lib/scoria_web/components/workflow_tree_component.ex`
- `lib/scoria_web/live/approvals_live/index.ex`
- `lib/scoria_web/live/connectors_live/index.ex`
- `lib/scoria_web/live/orchestrator_live.ex`
- `lib/scoria_web/live/workflow_live/index.ex`
- `lib/scoria_web/live/workflow_live/show.ex`
- `lib/scoria_web/operator_surface.ex`
- `lib/scoria_web/ui.ex`
- `test/support/ds06_baseline.txt`

## Resolved During Review

### CR-15-001: Shared table density controls emitted unowned events

`ScoriaWeb.UI.table/1` rendered density buttons with `phx-click="set_density"` for every table, including existing LiveViews without a `set_density` handler. That would route a user click to an unowned parent event.

Fixed in `0fc2ff7` by adding `on_density_change` to the shared table primitive, rendering density controls only when the caller supplies an event, and updating Phase 15 callers plus `DatasetLive` where the handler already exists.

### CR-15-002: Shared table sort controls emitted unowned events

`ScoriaWeb.UI.table/1` emitted `phx-click="sort"` for keyed columns even when the parent LiveView had no `sort` handler. Existing `EvalSpecLive` keyed columns would expose inert/crashing sort controls.

Fixed in `b23f530` by adding `on_sort` to the shared table primitive, rendering sort controls only when the caller supplies an event, and preserving `DatasetLive` sorting with `on_sort="sort"`.

## Verification

- `mix test test/scoria_web/ui_component_test.exs test/scoria_web/live/approvals_live_test.exs test/scoria_web/live/approvals_live_integration_test.exs test/scoria_web/live/connectors_live_test.exs test/scoria_web/live/workflow_live_test.exs test/scoria_web/ds06_drift_guard_test.exs` - passed, 110 tests, 0 failures.
- `rg -n 'phx-click="sort"|phx-click="set_density"' lib/scoria_web/live lib/scoria_web/components lib/scoria_web/ui.ex` - no literal unowned table event emissions remain.
- `git diff --check` - passed.

## Outstanding Findings

None.
