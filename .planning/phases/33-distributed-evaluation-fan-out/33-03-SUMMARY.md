---
phase: 33-distributed-evaluation-fan-out
plan: 03
subsystem: evals
tags: [oban, orchestrator, evals, idempotency, campaign-rollup]
requires:
  - phase: 33-02
    provides: replay-safe campaign worker envelope on the `:evals` queue
provides:
  - worker execution path for one campaign target through `Scoria.Orchestrator`
  - durable target/run finalization with idempotent score replacement
  - eager campaign counter rollups with partial versus fatal terminal semantics
affects: [distributed-evaluation-fan-out, evals, oban, orchestrator]
tech-stack:
  added: []
  patterns:
    - persisted lineage over job-envelope tenant identity
    - campaign rollup recomputed from durable target states
    - idempotent retry handling via score replacement plus terminal-target guards
key-files:
  created:
    - .planning/phases/33-distributed-evaluation-fan-out/33-03-SUMMARY.md
  modified:
    - lib/scoria/eval.ex
    - lib/scoria/eval/campaign_worker.ex
    - lib/scoria/eval/judge_runner.ex
    - test/scoria/eval/campaign_worker_test.exs
key-decisions:
  - "Campaign workers resolve campaign, target, and run identity from persisted lineage first; envelope tenant data remains inspectable but non-authoritative."
  - "Campaign aggregate counters are recalculated from durable target states on each transition so retries cannot double-count completion or failure."
  - "Worker retries replace prior score rows for the same EvalRun instead of appending duplicate score truth."
patterns-established:
  - "Oban workers stay queue-pinned at `:evals` even when callers pass alternate queue opts."
  - "Fatal campaign status is reserved for explicit credential, contract, quota/configuration, and persistence/integrity classes."
requirements-completed: [EVAL-02]
duration: 27min
completed: 2026-05-21
---

# Phase 33 Plan 03: Distributed Evaluation Fan-out Summary

**Campaign worker execution through `Scoria.Orchestrator` with idempotent target finalization and durable partial-versus-fatal campaign rollups**

## Performance

- **Duration:** 27 min
- **Started:** 2026-05-21T16:30:00Z
- **Completed:** 2026-05-21T16:57:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Implemented `Scoria.Eval.CampaignWorker.perform/1` so one persisted campaign target now executes through `Scoria.Orchestrator` as the only model boundary and finalizes against durable campaign/target/run lineage.
- Added `Scoria.Eval` helpers for lineage loading, running/complete/failed target transitions, idempotent score replacement, and eager parent rollups derived from persisted target states.
- Extended `JudgeRunner` with an existing-run execution path that propagates orchestrator failures cleanly instead of crashing on non-success tuples.
- Locked the worker contract with focused coverage for queue normalization, success persistence, shard-local partial completion, fatal failure classes, replay idempotency, and envelope-tenant mismatch handling.

## Task Commits

1. **Task 1: Define worker execution and rollup behavior with focused tests** - `d4126a6` (`test`)
2. **Task 2: Implement the `:evals` worker, orchestrator-backed execution path, and campaign finalization APIs** - `9e68f36` (`feat`)

## Files Created/Modified

- `lib/scoria/eval/campaign_worker.ex` - executes one persisted target shard, pins queue normalization, and routes failures into shard-local or fatal finalization.
- `lib/scoria/eval/judge_runner.ex` - adds existing-run execution and explicit orchestrator error propagation for campaign workers.
- `lib/scoria/eval.ex` - adds lineage resolution, idempotent score replacement, target transition helpers, and campaign rollup recomputation.
- `test/scoria/eval/campaign_worker_test.exs` - covers durable truth updates, partial/fatal rollups, replay idempotency, and tenant-lineage precedence.

## Decisions Made

- Used score replacement for campaign-worker retries instead of append-only inserts so replayed jobs cannot create duplicate `Score` truth for the same `EvalRun`.
- Recomputed campaign counters from persisted target rows on each transition rather than trying to infer deltas from Oban attempts or envelope state.
- Treated replayed envelope `tenant_id` as inspectable only; the worker never retargets execution away from the persisted campaign target and eval run lineage.

## Deviations from Plan

None - plan executed within scope and preserved the intended worker seam.

## Known Stubs

None.

## Threat Flags

None.

## Verification

- `mix test test/scoria/eval/campaign_worker_test.exs` - passed

## Self-Check: PASSED

- Summary file exists at `.planning/phases/33-distributed-evaluation-fan-out/33-03-SUMMARY.md`.
- Task commits `d4126a6` and `9e68f36` are present in git history.
