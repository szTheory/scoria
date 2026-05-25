---
phase: 41
slug: bounded-handoff-contract-safety
status: planned
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-24
---

# Phase 41 — Validation Strategy

> Per-phase validation contract for bounded handoff contract truth, projected-context safety, and support-truth proof.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/scoria/runtime_test.exs test/scoria/workflows/runtime_test.exs test/scoria/adoption_surface_test.exs test/scoria/handoff_example_source_test.exs test/mix/tasks/test.adoption_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30 seconds |

## Sampling Rate

- **After every task commit:** run the task-local smoke command in that task's `<verify>` block.
- **After every plan wave:** run the full Phase 41 quick lane.
- **Before `$gsd-verify-work`:** `mix test` should be attempted, with unrelated failures called out explicitly if they remain outside the phase lane.
- **Target task-local latency:** under 30 seconds.
- **Max feedback latency:** 60 seconds.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|--------|
| 41-01-01 | 01 | 1 | HAND-01, HAND-02 | T-41-01 | Public handoff start requires explicit contract inputs and still produces same-run root-step plus child-step lineage. | runtime facade smoke | `mix test test/scoria/runtime_test.exs` | ⬜ pending |
| 41-01-02 | 01 | 1 | HAND-02 | T-41-02 | Durable handoff/readback truth exposes delegated role, delegated kind, handoff input, and parent/child lineage without raw workflow inspection. | workflow/runtime smoke | `mix test test/scoria/runtime_test.exs test/scoria/workflows/runtime_test.exs` | ⬜ pending |
| 41-02-01 | 02 | 2 | SAFE-01 | T-41-03 | Unsafe projected-context keys are rejected before durable handoff execution accepts them, including nested/broad runtime-state aliases. | validation smoke | `mix test test/scoria/runtime_test.exs test/scoria/workflows/runtime_test.exs` | ⬜ pending |
| 41-02-02 | 02 | 2 | SAFE-01, SAFE-02 | T-41-04 | Public failure surfaces explain the narrow bounded-context contract explicitly instead of silently coercing or hiding unsafe delegated state. | regression smoke | `mix test test/scoria/runtime_test.exs` | ⬜ pending |
| 41-03-01 | 03 | 3 | SAFE-02 | T-41-05 | Bounded handoff docs and checked source fragments teach one narrow host-controlled lane with no implicit payload projection or broad runtime-state delegation. | adoption docs smoke | `mix test test/scoria/adoption_surface_test.exs test/scoria/handoff_example_source_test.exs` | ⬜ pending |
| 41-03-02 | 03 | 3 | HAND-01, HAND-02, SAFE-01, SAFE-02 | T-41-06 | The canonical adoption lane proves the public facade, docs/source alignment, and explicit handoff contract remain green together. | adoption lane smoke | `mix test test/mix/tasks/test.adoption_test.exs test/scoria/adoption_surface_test.exs test/scoria/runtime_test.exs` | ⬜ pending |

## Wave 0 Requirements

- [x] Existing runtime, workflow, and docs/test infrastructure already covers the target bounded handoff seams.
- [x] `test/scoria/runtime_test.exs` and `test/scoria/workflows/runtime_test.exs` already provide the seed runtime/workflow regression lanes to extend.
- [x] `test/scoria/adoption_surface_test.exs`, `test/scoria/handoff_example_source_test.exs`, and `test/mix/tasks/test.adoption_test.exs` already define the support-truth lane to tighten.

## Manual-Only Verifications

None required for Phase 41 acceptance if the runtime/workflow/adoption lanes remain green.

## Validation Sign-Off

- [x] All tasks have automated verify lanes
- [x] Sampling continuity covers every plan
- [x] No watch-mode flags
- [x] Task-local smokes stay under the repo's normal bounded-runtime test latency target
- [x] `nyquist_compliant: true` is set in frontmatter

