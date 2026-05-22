---
phase: 25-ci-cd-regression-and-evaluation-framework
plan: 03
subsystem: testing
tags: [req_llm, evals, mix-task, live-judge]
requires:
  - phase: 25-ci-cd-regression-and-evaluation-framework
    provides: canonical EvalSpec, EvalRun, and Score persistence APIs plus offline replay substrate
provides:
  - explicit live judge execution lane through `mix scoria.eval`
  - structured verdict persistence using the canonical EvalRun and Score truth model
  - injectable `ReqLLM` transport for deterministic live-lane tests
affects: [phase-26, evals, release-ops]
tech-stack:
  added: []
  patterns: [explicit live judge lane, structured verdict projection, injectable transport seam for external judge calls]
key-files:
  created: [.planning/phases/25-ci-cd-regression-and-evaluation-framework/25-03-SUMMARY.md, lib/scoria/eval/judge_runner.ex, test/scoria/eval/judge_runner_test.exs]
  modified: [lib/mix/tasks/scoria.eval.ex, test/mix/tasks/scoria.eval_test.exs]
key-decisions:
  - "Kept `mix scoria.eval` as the explicit online lane and left `mix test` as the deterministic offline regression lane."
  - "Projected judge verdicts into explicit score fields instead of storing opaque judge payloads."
  - "Made the `ReqLLM` dependency injectable so live-lane behavior can be tested without real network calls."
patterns-established:
  - "Live judge runs persist through `Scoria.Eval.create_eval_run/1`, `record_eval_scores/2`, and `complete_eval_run/2` just like offline replay."
  - "The CLI requires dataset, eval spec, prompt, provider, and model identity up front before any online execution starts."
requirements-completed: [EVAL-03, EVAL-04]
duration: 20m
completed: 2026-05-19
---

# Phase 25: CI/CD Regression & Evaluation Framework Summary

**The live evaluation command is now an explicit judge lane that persists the same structured run and score evidence as offline replay runs.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-05-19T14:10:00Z
- **Completed:** 2026-05-19T14:30:10Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Added `Scoria.Eval.JudgeRunner.run_live/1` to execute live judge-backed evals and persist canonical run header and per-item verdict facts.
- Replaced the `mix scoria.eval` placeholder with an explicit online command surface that requires dataset, eval spec, prompt, provider, and model identity.
- Added deterministic tests for structured verdict persistence and Mix task behavior using an injectable `ReqLLM` stub plus a real persisted baseline run anchor.

## Task Commits

1. **Task 1: Use the live judge transport from Plan 25-02 and create the runner with explicit structured verdict fields** - completed in the working tree during Wave 3 execution
2. **Task 2: Upgrade `mix scoria.eval` into the explicit online command surface** - completed in the working tree during Wave 3 execution

## Files Created/Modified
- `lib/scoria/eval/judge_runner.ex` - live judge execution service using `ReqLLM.generate_object/4` and canonical persistence APIs.
- `lib/mix/tasks/scoria.eval.ex` - explicit online Mix task with required identity flags and run header output.
- `test/scoria/eval/judge_runner_test.exs` - structured verdict persistence coverage using an injectable `ReqLLM` stub.
- `test/mix/tasks/scoria.eval_test.exs` - CLI behavior coverage for required options, header output, and baseline-run handling.

## Decisions Made

- Used the shared Phase 25 persistence APIs so live and offline lanes write the same durable truth shape.
- Limited stored judge output to explicit verdict fields such as `status`, `explanation`, `judge_model`, `rubric_version`, and `evidence_refs`.
- Allowed `ReqLLM` transport injection via attrs or application config to keep tests deterministic without weakening the production interface.

## Deviations from Plan

No plan deviations were required in Wave 3.

## Issues Encountered

- No new blockers. Wave 3 implementation completed inline after earlier executor stalls in prior waves.

## User Setup Required

- Live runs still require the normal runtime credentials/configuration for the chosen provider. The automated tests use stubs and do not require external access.

## Next Phase Readiness

- Phase 26 can now compare offline replay and live judge evidence using the same persisted run header and score schema.
- The explicit `mix scoria.eval` lane keeps online evaluation out of the default CI path while preserving auditable release evidence.

## Verification

- `mix test test/scoria/eval/judge_runner_test.exs test/mix/tasks/scoria.eval_test.exs`
- `mix test test/scoria/eval/eval_run_persistence_test.exs test/scoria/eval/replay_contract_test.exs test/scoria/eval/offline_runner_test.exs test/mix/tasks/scoria.eval.refresh_test.exs test/scoria/eval/judge_runner_test.exs test/mix/tasks/scoria.eval_test.exs test/scoria/eval_test.exs`

---
*Phase: 25-ci-cd-regression-and-evaluation-framework*
*Completed: 2026-05-19*
