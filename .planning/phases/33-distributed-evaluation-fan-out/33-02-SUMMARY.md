---
phase: 33-distributed-evaluation-fan-out
plan: 02
subsystem: evals
tags: [oban, ecto, evals, batch-enqueue, fan-out]
requires:
  - phase: 33-01
    provides: durable campaign/target tables and eval-run lineage columns
provides:
  - campaign coordinator API that persists targets, eval runs, and jobs together
  - dedicated `CampaignWorker` envelope on the `:evals` queue
  - normalization guardrails for semantic overrides and duplicate runtime targets
affects: [distributed-evaluation-fan-out, evals, oban, queueing]
tech-stack:
  added: []
  patterns: [eval coordinator fan-out via BatchEnqueue, worker new_job normalization]
key-files:
  created:
    - .planning/phases/33-distributed-evaluation-fan-out/33-02-SUMMARY.md
    - lib/scoria/eval/campaign_enqueuer.ex
    - lib/scoria/eval/campaign_worker.ex
    - test/scoria/eval/campaign_enqueue_test.exs
  modified:
    - lib/scoria/eval.ex
key-decisions:
  - "Campaign fan-out stays in `Scoria.Eval` and delegates only the batch-building seam to `CampaignEnqueuer`."
  - "All target work is normalized onto a fixed replay-safe worker envelope before enqueueing, with semantic override keys rejected before any write."
patterns-established:
  - "Campaign coordinator flow persists campaign, targets, and child eval runs before batch-enqueueing jobs through `Scoria.Workflows.BatchEnqueue`."
  - "Dedicated Oban workers expose `new_job/2` as the stable normalization seam for async contracts."
requirements-completed: [EVAL-02]
duration: 16min
completed: 2026-05-21
---

# Phase 33 Plan 02: Distributed Evaluation Fan-out Summary

**Campaign coordinator fan-out that persists target/run lineage and batch-enqueues replay-safe `:evals` jobs through `BatchEnqueue`**

## Performance

- **Duration:** 16 min
- **Started:** 2026-05-21T16:10:00Z
- **Completed:** 2026-05-21T16:26:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Added `Scoria.Eval.create_and_enqueue_campaign/2` as the canonical coordinator entrypoint for one immutable eval contract plus many runtime targets.
- Added `Scoria.Eval.CampaignEnqueuer` to normalize targets, reject semantic drift and duplicates, create one pending `EvalRun` per target, and enqueue all jobs through `Scoria.Workflows.BatchEnqueue`.
- Added `Scoria.Eval.CampaignWorker.new_job/2` and focused enqueue tests proving campaign identity, tenant identity, queue assignment, and replay-safe job args.

## Task Commits

1. **Task 1: Lock the coordinator contract with focused campaign enqueue tests** - `f9054df` (`test`)
2. **Task 2: Implement campaign creation, target normalization, and batch fan-out through `BatchEnqueue`** - `a9eb4a9` (`feat`)

## Files Created/Modified
- `lib/scoria/eval.ex` - public `create_and_enqueue_campaign/2` coordinator API
- `lib/scoria/eval/campaign_enqueuer.ex` - target normalization, lineage persistence, and batch enqueue orchestration
- `lib/scoria/eval/campaign_worker.ex` - dedicated `:evals` worker envelope and normalized `new_job/2`
- `test/scoria/eval/campaign_enqueue_test.exs` - focused fan-out contract coverage

## Decisions Made
- Kept fan-out orchestration under the existing `Scoria.Eval` context instead of introducing a second domain root.
- Normalized all target queues back to the dedicated `evals` lane so operators can pass only bounded runtime hints, not arbitrary queue routing.

## Deviations from Plan

None - plan executed within scope and followed the intended TDD flow.

## Known Stubs

- `lib/scoria/eval/campaign_worker.ex:18` - `perform/1` intentionally returns `{:error, :execution_not_implemented}` because actual shard execution semantics are deferred to Plan 33-03; this plan establishes the durable enqueue contract only.

## Issues Encountered

- `CampaignWorker.new_job/2` returns an Oban job changeset rather than a persisted job struct, so the worker contract assertion was aligned to the existing repo pattern already used by other workers.

## User Setup Required

None.

## Next Phase Readiness

- Plan `33-03` can implement shard execution and aggregate rollup against a stable async envelope carrying campaign, target, run, spec, provider, model, and tenant identity.
- Coordinator fan-out now uses the dedicated `:evals` queue and shared batch enqueue seam, so worker execution can focus on runtime behavior rather than job construction.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/33-distributed-evaluation-fan-out/33-02-SUMMARY.md`.
- Task commits `f9054df` and `a9eb4a9` are present in git history.

---
*Phase: 33-distributed-evaluation-fan-out*
*Completed: 2026-05-21*
