---
phase: 15
slug: high-traffic-screens-evidence-adapters
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-12
---

# Phase 15 - Validation Strategy

Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix LiveViewTest |
| **Config file** | `mix.exs`, `test/test_helper.exs`, `test/support/conn_case.ex` |
| **Quick run command** | `mix test <focused test files>` |
| **Full suite command** | `mix test test/scoria_web/ds06_drift_guard_test.exs test/scoria_web/ui_component_test.exs test/scoria_web/live/orchestrator_live_test.exs test/scoria_web/live/workflow_live_test.exs test/scoria_web/live/approvals_live_test.exs test/scoria_web/live/connectors_live_test.exs` |
| **Estimated runtime** | ~60-180 seconds focused, depending on database setup |

## Sampling Rate

- **After every task commit:** run the focused test file(s) named in that task's `<verify><automated>` block plus `mix test test/scoria_web/ds06_drift_guard_test.exs` when a `lib/scoria_web/` file was touched.
- **After every plan wave:** run all focused Phase 15 LiveView/component tests modified in that wave.
- **Before `$gsd-verify-work`:** run the full suite command above and any additional tests named by the final PLAN.md files.
- **Max feedback latency:** 180 seconds for focused Phase 15 feedback.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 15-01-01 | 01 | 1 | SCREEN-04 | T-15-01 / SC | Shared evidence primitives render tokenized chrome and do not introduce raw palette classes. | component | `mix test test/scoria_web/ui_component_test.exs test/scoria_web/ds06_drift_guard_test.exs` | yes | pending |
| 15-02-01 | 02 | 2 | SCREEN-03 | T-15-02 | Home stream removes mutating evidence/replay/promote controls and keeps mount-prefix-safe deep links. | LiveView | `mix test test/scoria_web/live/orchestrator_live_test.exs test/scoria_web/live/orchestrator_live_integration_test.exs test/scoria_web/live/orchestrator_live_sre_test.exs test/scoria_web/ds06_drift_guard_test.exs` | yes | pending |
| 15-02-02 | 02 | 2 | SCREEN-03 | T-15-02 / SC | Runs index renders real run rows through shared table and opens trace detail pages. | LiveView | `mix test test/scoria_web/live/workflow_live_test.exs test/scoria_web/ds06_drift_guard_test.exs` | yes | pending |
| 15-03-01 | 03 | 3 | SCREEN-03, SCREEN-04 | T-15-03 | Workflow Show preserves run loading, step selection, Dataset Builder promotion URL, and shared modal/detail shells. | LiveView | `mix test test/scoria_web/live/workflow_live_test.exs test/scoria_web/components/trace_tree_component_test.exs test/scoria_web/ds06_drift_guard_test.exs` | yes | pending |
| 15-04-01 | 04 | 3 | SCREEN-03 | T-15-04 | Approvals preserve approve/resume and reject/no-resume behavior through table -> drawer -> modal flow. | LiveView | `mix test test/scoria_web/live/approvals_live_test.exs test/scoria_web/live/approvals_live_integration_test.exs test/scoria_web/ds06_drift_guard_test.exs` | yes | pending |
| 15-04-02 | 04 | 3 | SCREEN-03 | T-15-05 | Connectors preserve presence refresh and real OperatorSurface detail data through shared tables/drawers. | LiveView | `mix test test/scoria_web/live/connectors_live_test.exs test/scoria_web/components/runtime_detail_drawer_component_test.exs test/scoria_web/ds06_drift_guard_test.exs` | yes | pending |
| 15-05-01 | 05 | 4 | SCREEN-04 | T-15-06 / SC | Evidence adapters preserve evidence values while moving chrome, rows, empty states, and raw disclosures into shared primitives. | component | `mix test test/scoria_web/components/semantic_evidence_notebook_component_test.exs test/scoria_web/components/incident_evidence_component_test.exs test/scoria_web/ui_component_test.exs test/scoria_web/ds06_drift_guard_test.exs` | yes | pending |

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

- [x] ExUnit and Phoenix LiveViewTest are already configured.
- [x] DS-06 raw-palette drift guard already exists.
- [x] Phase 11 screenshot harness already exists as optional dev-only proof support.
- [x] No package-manager or framework install is required.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| High-traffic screens meet the visual rubric bar after all plans land. | SCREEN-03 | The rubric includes hierarchy, density, microcopy, and scanability beyond source assertions. | Start the dashboard, inspect Home / Live Ops, Runs / Workflow Show, Approvals, and Connectors against `priv/shots/gap_register.md` and Phase 15 CONTEXT decisions D-01..D-28. |
| Evidence adapters read as thin notebook-shell adapters with no duplicated layout logic. | SCREEN-04 | Some duplication is structural and easier to judge by code review across files. | Review all converted adapter files and verify they own projection/copy/event wiring only while `ui.ex` owns chrome, rows, empty state, raw evidence, and tone mapping. |
| Optional screenshot proof support. | SCREEN-03, SCREEN-04 | Screenshot harness is committed dev tooling, not merge-blocking CI. | Run `mix scoria.ui.shots` after implementation if a visual proof pass is needed. |

## Validation Sign-Off

- [x] All planned tasks have an automated verify command or existing Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing infrastructure references.
- [x] No watch-mode flags.
- [x] Feedback latency target is under 180 seconds for focused checks.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-06-12
