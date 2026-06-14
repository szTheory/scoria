---
phase: 14
slug: least-iterated-screens-polish
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-12
---

# Phase 14 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix.LiveViewTest |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/scoria_web/ds06_drift_guard_test.exs test/scoria_web/dashboard_nav_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30-120 seconds for focused web slices; full project suite is longer |

---

## Sampling Rate

- **After every task commit:** Run the focused LiveView/component test for the touched screen plus `mix test test/scoria_web/ds06_drift_guard_test.exs`
- **After every plan wave:** Run `mix test test/scoria_web/dashboard_nav_test.exs test/scoria_web/live/review_queue_live_test.exs test/scoria_web/live/incidents_live_test.exs test/scoria_web/live/eval_spec_live/index_test.exs test/scoria_web/live/prompt_live_test.exs test/scoria_web/live/prompt_live/release_workbench_live_test.exs test/scoria_web/live/dataset_live/promote_component_test.exs test/scoria_web/ds06_drift_guard_test.exs`
- **Before `$gsd-verify-work`:** Run `mix test`
- **Max feedback latency:** ~120 seconds for focused web-slice feedback

---

## Per-Task Verification Map

> Task IDs are provisional until plans are written; the planner finalizes them.

| Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|----------|-----------|-------------------|-------------|--------|
| SCREEN-01 | Review Queue renders through shared components, preserves triage links, and no longer owns direct dataset management affordances | LiveView integration | `mix test test/scoria_web/live/review_queue_live_test.exs test/scoria_web/ds06_drift_guard_test.exs` | exists, update needed | pending |
| SCREEN-01 | Incidents renders through shared components and preserves `IncidentEvidenceComponent` content through the allowed one-component exception | LiveView integration | `mix test test/scoria_web/live/incidents_live_test.exs test/scoria_web/ds06_drift_guard_test.exs` | exists, update needed | pending |
| SCREEN-01 | Eval Workbench uses shared table/form surfaces and preserves quality-loop links | LiveView isolated | `mix test test/scoria_web/live/eval_spec_live/index_test.exs test/scoria_web/ds06_drift_guard_test.exs` | exists, update needed | pending |
| SCREEN-01 | Prompt Registry edit/token behavior and Release Workbench approval behavior are preserved after shared-component conversion | LiveView isolated/integration | `mix test test/scoria_web/live/prompt_live_test.exs test/scoria_web/live/prompt_live/release_workbench_live_test.exs test/scoria_web/ds06_drift_guard_test.exs` | exists, update needed | pending |
| SCREEN-02 | `/datasets` route, nav item, command-palette entry, shortcut, and non-stub Dataset Builder index exist | unit + LiveView integration | `mix test test/scoria_web/dashboard_nav_test.exs test/scoria_web/router_test.exs test/scoria_web/live/dataset_live/index_test.exs` | W0 required | pending |
| SCREEN-02 | Dataset Builder reconstructs promotion context from review/workflow IDs and reuses existing promotion behavior without raw-palette leakage | LiveView integration/component | `mix test test/scoria_web/live/dataset_live/index_test.exs test/scoria_web/live/dataset_live/promote_component_test.exs` | W0 for index; component test exists | pending |

---

## Wave 0 Requirements

- [ ] `lib/scoria_web/live/dataset_live/index.ex` - create the real Dataset Builder index LiveView required by SCREEN-02.
- [ ] `test/scoria_web/live/dataset_live/index_test.exs` - cover route/index rendering, non-stub copy, source affordances, and promotion-context reconstruction.
- [ ] `test/scoria_web/dashboard_nav_test.exs` - update for Dataset Builder nav item, shortcut, command-palette row, and stub exclusion.
- [ ] `test/scoria_web/router_test.exs` - update if route coverage asserts the known dashboard route set.
- [ ] `test/support/ds06_baseline.txt` - remove every in-scope row after each shared-component conversion reaches zero raw-palette matches.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Target screens meet the visual rubric bar after shared-component conversion | SCREEN-01 | Rubric-level polish needs browser rendering and screenshot critique beyond LiveView markup assertions | Start the dashboard, capture the target screens, and compare Review Queue, Incidents, Eval Workbench, Prompt Registry, and Release Workbench against Phase 12/13 shared-component quality. |
| Dataset Builder promotion entry feels usable from Review Queue and Workflow Show | SCREEN-02 | Drawer/modal fit, keyboard focus, and operator flow need browser interaction | Navigate from Review Queue and Workflow Show into Dataset Builder promotion context; verify source context remains understandable and no duplicate promote affordance owns the flow. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify commands or explicit Wave 0 scaffold tasks
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all missing Dataset Builder route/index/test references before production edits
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s for focused web-slice checks
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
