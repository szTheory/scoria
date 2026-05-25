---
phase: 42
slug: delegated-evidence-adoption-story
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-24
---

# Phase 42 — Validation Strategy

> Per-phase validation contract for delegated evidence inspectability, workflow-surface rendering, and runtime-first adoption-story alignment.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Phoenix LiveView test helpers |
| **Config file** | `mix.exs`, `test/test_helper.exs` |
| **Quick run command** | `mix test test/scoria/runtime_test.exs test/scoria/runtime_view_test.exs test/scoria_web/live/workflow_live_test.exs test/scoria/adoption_surface_test.exs test/scoria/handoff_example_source_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~45 seconds |

## Sampling Rate

- **After every task commit:** run the task-local smoke command in the task `<verify>` block.
- **After every plan wave:** run the relevant quick lane for runtime, workflow UI, or adoption docs.
- **Before `$gsd-verify-work`:** run the full Phase 42 quick lane.
- **Target task-local latency:** under 45 seconds.
- **Max feedback latency:** 90 seconds.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|--------|
| 42-01-01 | 01 | 1 | EVID-01 | T-42-01 | Public runtime detail exposes one curated delegated evidence projection without removing raw workflow evidence. | runtime DTO smoke | `mix test test/scoria/runtime_test.exs test/scoria/runtime_view_test.exs` | ✅ green |
| 42-01-02 | 01 | 1 | EVID-01 | T-42-02 | Projection precedence, ordering, and pending child-step semantics stay explicit and stable. | runtime DTO regression | `mix test test/scoria/runtime_test.exs test/scoria/runtime_view_test.exs` | ✅ green |
| 42-02-01 | 02 | 2 | EVID-01 | T-42-03 | Workflow page renders a run-level delegated evidence section from the curated DTO. | LiveView smoke | `mix test test/scoria_web/live/workflow_live_test.exs` | ✅ green |
| 42-02-02 | 02 | 2 | EVID-01, ADPT-01 | T-42-04 | Delegated inspection remains compact, progressive, and aligned with existing tree/detail responsibilities. | LiveView regression | `mix test test/scoria_web/live/workflow_live_test.exs` | ✅ green |
| 42-03-01 | 03 | 3 | ADPT-01 | T-42-05 | README, runtime example, and bounded handoff guide teach the same runtime-first delegated evidence story. | docs/source smoke | `mix test test/scoria/adoption_surface_test.exs test/scoria/handoff_example_source_test.exs` | ✅ green |
| 42-03-02 | 03 | 3 | ADPT-01, EVID-01 | T-42-06 | Remaining adopter-facing gap is either explicitly closed or explicitly deferred with checked support truth. | docs/source regression | `mix test test/scoria/adoption_surface_test.exs test/scoria/handoff_example_source_test.exs` | ✅ green |

## Wave 0 Requirements

- [x] Existing runtime, LiveView, and support-truth test lanes cover the delegated evidence and adoption-story seams.
- [x] `test/scoria/runtime_test.exs` and `test/scoria/runtime_view_test.exs` cover curated runtime DTO behavior.
- [x] `test/scoria_web/live/workflow_live_test.exs` covers workflow-surface delegated inspection.
- [x] `test/scoria/adoption_surface_test.exs` and `test/scoria/handoff_example_source_test.exs` cover docs/source alignment.

## Manual-Only Verifications

None required for Phase 42 acceptance if the runtime, LiveView, and docs/source lanes remain green.

## Validation Sign-Off

- [x] All tasks have automated verify lanes
- [x] Sampling continuity covers every plan
- [x] No watch-mode flags
- [x] Task-local smokes stay inside the phase latency target
- [x] `nyquist_compliant: true` is set in frontmatter
