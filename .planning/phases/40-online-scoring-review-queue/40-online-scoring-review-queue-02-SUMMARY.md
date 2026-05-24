---
phase: 40-online-scoring-review-queue
plan: 02
subsystem: evals
tags: [oban, evals, online-scoring, review-queue]
requires:
  - phase: 40-online-scoring-review-queue
    provides: durable score evidence and candidate storage substrate
provides:
  - explicit async sampler boundary for production traces
  - durable candidate-to-campaign enqueue flow for online scoring
  - active-candidate dedupe before duplicate enqueue
affects: [phase-40-03, phase-40-04, evals, review-queue]
tech-stack:
  added: []
  patterns: [async sampler seam, candidate-first persistence, enqueue-path reuse]
key-files:
  created: [lib/scoria/eval/online_score_sampler.ex, lib/scoria/eval/online_scoring.ex, .planning/phases/40-online-scoring-review-queue/40-online-scoring-review-queue-02-SUMMARY.md]
  modified: [lib/scoria/eval.ex, test/scoria/eval/online_score_sampler_test.exs]
key-decisions:
  - "Kept the request-facing API narrow as `Scoria.Eval.sample_trace_for_online_scoring/2`, which only schedules async work and never scores inline."
  - "Made the sampler read persisted trace and workflow lineage before enqueueing so eligibility is based on durable facts, not caller assertions."
  - "Reused `create_and_enqueue_campaign/2` for worker fan-out and stored candidate lineage in campaign/target metadata instead of introducing a second enqueue mechanism."
patterns-established:
  - "Online scoring candidate insert happens before campaign enqueue, and active dedupe reuses the existing candidate instead of double-enqueueing jobs."
  - "Async tests pass a sandbox repo/owner into the sampler so spawned processes can safely persist and enqueue inside ExUnit."
requirements-completed: [SCOR-01]
duration: 43m
completed: 2026-05-23
---

# Phase 40 Plan 02: Online Scoring Sampler Summary

**Added an explicit off-path sampler and coordinator that turn eligible production traces into durable online-scoring candidates plus one reused campaign enqueue path.**

## Accomplishments
- Added `Scoria.Eval.OnlineScoreSampler` to validate persisted trace/workflow lineage, enforce production-only eligibility, normalize sampler provenance, and trigger the coordinator asynchronously.
- Added `Scoria.Eval.OnlineScoring` to persist one `OnlineScoreCandidate`, reuse `Scoria.Eval.create_and_enqueue_campaign/2` for async worker fan-out, and update candidate lineage with the resulting campaign/eval-run ids.
- Extended `Scoria.Eval.sample_trace_for_online_scoring/2` as the public seam and proved dedupe prevents duplicate active candidate enqueue for the same trace window.

## Verification
- `mix test test/scoria/eval/online_score_sampler_test.exs`
- `mix test test/scoria/eval/campaign_enqueue_test.exs`
- `mix test test/scoria/eval/online_score_sampler_test.exs test/scoria/eval/campaign_enqueue_test.exs`

## Notes
- Existing compile-time warnings for unfinished connector/compaction modules were present during verification and are unrelated to this slice.
