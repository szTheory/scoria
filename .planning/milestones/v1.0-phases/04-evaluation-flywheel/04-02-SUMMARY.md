---
phase: 04-evaluation-flywheel
plan: 02
subsystem: Eval
tags: [eval, mix, testing]
dependencies:
  requires: [01]
  provides: [03]
  affects: [Mix, ExUnit]
tech-stack:
  added: []
  patterns: [ExUnit.CaseTemplate, Mix.Task]
key-files:
  created:
    - test/support/eval_case.ex
    - test/support/eval_case_test.exs
    - lib/mix/tasks/scoria.eval.ex
    - test/mix/tasks/scoria.eval_test.exs
  modified: []
decisions:
  - Created an ExUnit case template macro `Scoria.EvalCase` to segregate fast unit tests from slow evaluation runs.
  - Set up a Mix task `scoria.eval` that starts the Ecto repository and parses the `--dataset` argument to serve as a shell for triggering full evaluations.
metrics:
  duration: "10m"
  tasks_completed: 2
  files_modified: 4
---

# Phase 04 Plan 02: LLM-as-Judge Flywheel Execution Engine Summary

Integrated Tribunal into Scoria to act as the execution engine for evaluations, enabling deterministic ExUnit unit testing and a dedicated Mix task.

## Key Changes
- Scaffolded `Scoria.EvalCase` implementing `ExUnit.CaseTemplate` to provide Sandbox isolation and Tribunal functionality for evaluation tests.
- Scaffolded `Mix.Tasks.Scoria.Eval` to parse `--dataset` CLI argument and initialize the application (starting DB).

## Deviations from Plan
None - plan executed exactly as written.

## Known Stubs
- `lib/mix/tasks/scoria.eval.ex`: Line 28: `# TODO: Fetch dataset using Scoria.Eval and iterate over items using Tribunal` - The plan requested to implement basic CLI parsing and the runner shell for now. The actual evaluation implementation will be completed in a future step.

## Self-Check: PASSED
- `test/support/eval_case.ex` (created)
- `test/support/eval_case_test.exs` (created)
- `lib/mix/tasks/scoria.eval.ex` (created)
- `test/mix/tasks/scoria.eval_test.exs` (created)
- Commits `fee33a3` and `5b6c1d8` exist.
