---
phase: 40-online-scoring-review-queue
plan: 03
subsystem: evals
tags: [online-scoring, evals, campaign-worker, judge]
requires:
  - phase: 40-02
    provides: durable candidate persistence and async campaign enqueue
provides:
  - deterministic-first online scoring inside the existing campaign worker lane
  - optional judge rationale appended without overwriting deterministic evidence
  - durable candidate review-state derivation from persisted score rows
affects: [phase-40-04, phase-40-05, review-queue, evals]
tech-stack:
  added: []
  patterns: [deterministic-first scoring, additive judge evidence, candidate-state derivation]
key-files:
  created: [.planning/phases/40-online-scoring-review-queue/40-online-scoring-review-queue-03-SUMMARY.md]
  modified:
    - lib/scoria/eval.ex
    - lib/scoria/eval/online_scoring.ex
    - lib/scoria/eval/judge_runner.ex
    - test/scoria/eval/campaign_worker_test.exs
key-decisions:
  - "Online scoring reuses the existing `CampaignWorker` and `Eval.execute_campaign_target/1` path instead of introducing a second worker type."
  - "Judge-backed scores are appended onto the eval run alongside deterministic scores by passing base score attrs through the existing judge runner."
  - "Candidate status and rationale are re-derived from persisted score rows after each worker completion or retry."
patterns-established:
  - "Policy-triggered traces finish deterministically and skip judge execution."
  - "Judge retries rebuild the eval run score set idempotently instead of accumulating duplicate score rows."
requirements-completed: [SCOR-02]
completed: 2026-05-24
---

# Phase 40 Plan 03: Online Scoring Execution Summary

**Extended the existing eval worker path so sampled traces score deterministically first, append optional judge rationale second, and persist durable candidate review state from score evidence.**

## Accomplishments
- Routed online scoring targets through `Scoria.Eval.OnlineScoring.execute_candidate/2` from the existing `Eval.execute_campaign_target/1` seam.
- Persisted deterministic scorer evidence with scorer kind/version, explanation, and sampling provenance before any optional judge call.
- Appended judge-backed rationale without replacing deterministic rows by extending `JudgeRunner.run_existing/2` to accept base score attrs.
- Locked retry behavior with worker tests proving score replacement remains idempotent across reruns.

## Verification
- `mix test test/scoria/eval/campaign_worker_test.exs`

## Notes
- This summary reconciles an already-implemented working-tree slice during phase closeout; no new git commit was created in this run.

## Self-Check: PASSED

- Verified deterministic policy-trigger and judge-augmentation worker coverage in `test/scoria/eval/campaign_worker_test.exs`.
- Verified `.planning/phases/40-online-scoring-review-queue/40-online-scoring-review-queue-03-SUMMARY.md` exists on disk.

---
*Phase: 40-online-scoring-review-queue*
*Completed: 2026-05-24*
