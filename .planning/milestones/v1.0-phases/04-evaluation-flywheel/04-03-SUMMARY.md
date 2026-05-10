---
phase: 04-evaluation-flywheel
plan: 03
subsystem: scoria_eval
tags: [LiveView, UI, Evaluation, Dataset, Ecto]
requires: [04-01]
provides: [Scoria.Eval.promote_trace_to_dataset/2, ScoriaWeb.DatasetLive.PromoteComponent, ScoriaWeb.EvalSpecLive.Index]
affects: [UI, Evaluation Workflow]
tech-stack-added: []
patterns-added: [LiveView Component promotion form]
key-files-created:
  - lib/scoria_web/live/dataset_live/promote_component.ex
  - test/scoria_web/live/dataset_live/promote_component_test.exs
  - lib/scoria_web/live/eval_spec_live/index.ex
  - test/scoria_web/live/eval_spec_live/index_test.exs
key-files-modified:
  - lib/scoria/eval.ex
  - test/scoria/eval_test.exs
  - lib/scoria_web/components/trace_tree_component.ex
  - lib/scoria_web/live/orchestrator_live.ex
  - test/scoria_web/live/orchestrator_live_test.exs
key-decisions:
  - Dataset promotion uses an immutable logic extracting spans mapped to trace for creating versioned ai_datasets via Scoria.Eval.
duration: 15m
tasks-completed: 3
tasks-total: 3
date: 2024-05-10
---

# Phase 4 Plan 03: LiveView UI Integration for Dataset Promotion Summary

Implemented LiveView components and logic to allow operators to promote a failed trace into a versioned dataset directly from the UI, and to manage evaluation rubrics.

## Tasks Completed
1. **Task 1: Promotion Context Logic** - Added `promote_trace_to_dataset/2` to map trace spans into immutable datasets.
2. **Task 2: Promote Trace LiveComponent** - Created `ScoriaWeb.DatasetLive.PromoteComponent` to render promotion form.
3. **Task 3: EvalSpec Rubric Editor UI** - Implemented `ScoriaWeb.EvalSpecLive.Index` dashboard to view and immutably edit rubrics.

## Commits
- `c213d0e`: feat(04-03): implement dataset promotion and evalspec rubrics

## Deviations from Plan
- None - plan executed exactly as written.

## Known Stubs
- None

## Threat Flags
- None
