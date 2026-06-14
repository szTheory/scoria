---
phase: 15-high-traffic-screens-evidence-adapters
verified: 2026-06-13T01:52:00Z
status: passed
score: 12/12 must-haves verified
overrides_applied: 0
human_verification: []
---

# Phase 15: High-Traffic Screens + Evidence Adapters Verification

**Phase Goal:** Convert Home / Live Ops, Runs / Workflow Show, Approvals, Connectors, and the remaining evidence adapters onto the shared `ScoriaWeb.UI` component layer while preserving current backend behavior, links, events, and evidence contracts.

**Status:** passed

## Goal Achievement

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Status Home / Live Ops is a calm read-only triage surface, not a workbench | VERIFIED | `OrchestratorLive` tests cover shared surface contracts, attention/deep-link behavior, incident/runtime signals, and removal of local raw-palette god-page action chrome. |
| 2 | Runs index renders through the shared table scan pattern | VERIFIED | `WorkflowLive.Index` uses `<.table id="runs">`, badges, IDs, timestamps, and `Open trace`; workflow tests pass. |
| 3 | Workflow Show is the canonical trace inspector | VERIFIED | `WorkflowLive.Show` keeps object header, next-step verbs, trace tree/detail area, replay promotion, semantic evidence, delegated evidence, memory evidence, and incident evidence under the trace inspector flow. |
| 4 | Approvals uses table -> drawer -> final decision modal | VERIFIED | `ApprovalsLive.Index` renders `ApprovalInboxComponent` table, shared drawer detail, and shared modal confirmation; approval/rejection integration tests pass. |
| 5 | Approval decision semantics are preserved | VERIFIED | Approval still calls `Workflows.approve/3` and attempts `Resume.resume_run/1`; rejection records a durable rejection and keeps the workflow paused. |
| 6 | Connectors uses shared runtime and fleet tables plus parent-owned drawers | VERIFIED | `ConnectorsLive.Index` renders runtime presence and connector fleet tables with shared drawer shells; connector tests pass. |
| 7 | Runtime and connector detail components are content adapters | VERIFIED | `RuntimeDetailDrawerComponent` and `ConnectorDetailDrawerComponent` render shared evidence rows/sections and do not own drawer shell chrome. |
| 8 | Evidence components are thin notebook adapters | VERIFIED | Citation, delegated, memory, replay, semantic, remote invocation, and incident adapters import `ScoriaWeb.UI` and render through notebook/evidence primitives. |
| 9 | Existing evidence values/events/links are preserved | VERIFIED | Component and workflow tests cover citation values, delegated lineage and disclosure, memory runtime links, replay `select_comparison_source`, semantic fallback copy, remote approval values, incident evidence, and unsafe-value escaping. |
| 10 | Raw palette leakage is removed from touched screens/adapters | VERIFIED | `test/support/ds06_baseline.txt` is empty; `mix test test/scoria_web/ds06_drift_guard_test.exs` passes. |
| 11 | Shared table interactions emit only caller-owned events | VERIFIED | Review fixes added `on_density_change` and `on_sort`; static tables no longer emit unowned `set_density` or `sort` events. UI component tests pass. |
| 12 | No backend capability scope was added | VERIFIED | Changes are LiveView/component/CSS/test/planning only. No new approval routes, connector routes, setup workflows, registry behavior, query language, or backend capability families were introduced. |

**Score:** 12/12 must-haves verified

## Required Artifacts

| Artifact | Expected | Status |
|----------|----------|--------|
| `lib/scoria_web/ui.ex` | Shared evidence primitives and opt-in table controls | VERIFIED |
| `assets/css/04-components.css` | Shared evidence/table/trace CSS classes | VERIFIED |
| `lib/scoria_web/live/orchestrator_live.ex` | Home / Live Ops shared surface | VERIFIED |
| `lib/scoria_web/live/workflow_live/index.ex` | Runs shared table | VERIFIED |
| `lib/scoria_web/live/workflow_live/show.ex` | Trace inspector and evidence stack | VERIFIED |
| `lib/scoria_web/live/approvals_live/index.ex` | Table/drawer/modal approval flow | VERIFIED |
| `lib/scoria_web/live/connectors_live/index.ex` | Runtime/connector tables and drawers | VERIFIED |
| Evidence adapter components | Thin notebook/evidence-section adapters | VERIFIED |
| `test/support/ds06_baseline.txt` | Lowered raw-palette baseline | VERIFIED - empty |
| `15-REVIEW.md` | Code review report | VERIFIED - clean after two review fixes |

## Requirements Coverage

| Requirement | Description | Status | Evidence |
|-------------|-------------|--------|----------|
| SCREEN-03 | Live Ops, Workflows / Trace Explorer, Approvals, and Connectors render through shared components and Home uses design-system deep-links | SATISFIED | Plans 15-02, 15-03, and 15-04 converted those screens; phase suite covers Home, Workflow index/show, Approvals, and Connectors. |
| SCREEN-04 | Evidence components are thin adapters over the unified notebook shell with no duplicated layout logic | SATISFIED | Plan 15-05 converted remaining evidence adapters; DS-06 and component source/behavior tests pass. |

## Automated Verification

- Phase suite: `mix test test/scoria_web/live/orchestrator_live_test.exs test/scoria_web/live/orchestrator_live_integration_test.exs test/scoria_web/live/orchestrator_live_sre_test.exs test/scoria_web/live/workflow_live_test.exs test/scoria_web/live/approvals_live_test.exs test/scoria_web/live/approvals_live_integration_test.exs test/scoria_web/live/connectors_live_test.exs test/scoria_web/components/trace_tree_component_test.exs test/scoria_web/components/workflow_tree_component_test.exs test/scoria_web/components/runtime_detail_drawer_component_test.exs test/scoria_web/components/semantic_evidence_notebook_component_test.exs test/scoria_web/components/incident_evidence_component_test.exs test/scoria_web/components/memory_notebook_component_test.exs test/scoria_web/ui_component_test.exs test/scoria_web/ds06_drift_guard_test.exs` - passed, 147 tests, 0 failures.
- Regression gate: `mix test test/scoria/ui_critique_test.exs test/scoria_web/ui_component_test.exs test/scoria_web/ds06_drift_guard_test.exs` - passed, 78 tests, 0 failures.
- Schema drift gate: `gsd-sdk query verify.schema-drift 15` - `drift_detected: false`, `blocking: false`.
- Codebase drift gate: `gsd-sdk query verify.codebase-drift` - skipped, `reason: no-structure-md`.
- Code review gate: `.planning/phases/15-high-traffic-screens-evidence-adapters/15-REVIEW.md` - `status: clean` after fixes `0fc2ff7` and `b23f530`.

## Issues Encountered

- The advisory review found two shared table event ownership bugs. Both were fixed before verification:
  - `0fc2ff7` gates density controls behind `on_density_change`.
  - `b23f530` gates sort controls behind `on_sort`.
- The full phase test run emitted a non-fatal Postgrex sandbox owner disconnect log from the workflow reconciler after an async test owner exited. ExUnit completed green with 147 tests and 0 failures.

## Human Verification Required

None. Phase 15 acceptance is covered by LiveView/component tests, source contracts, DS-06 drift guard, regression tests, and review fixes.

## Verdict

Phase 15 achieved its goal. SCREEN-03 and SCREEN-04 are satisfied, and the phase is ready to be marked complete in tracking.

---
*Verified: 2026-06-13T01:52:00Z*
