---
phase: 34-real-time-operator-dashboards
plan: 01
subsystem: eval
tags: [phoenix, pubsub, ecto, dashboard, fallback, circuit-breaker]
requires:
  - phase: 33-distributed-evaluation-fan-out
    provides: durable eval campaign and worker truth
provides:
  - traced orchestrator result metadata for fallback-aware consumers
  - eval dashboard projection APIs and tenant-scoped refresh broadcasts
  - durable fallback provenance columns on eval runs and campaign targets
  - breaker snapshot API for model-health projections
affects: [dashboard, liveview, eval, operator-ux]
tech-stack:
  added: []
  patterns: [tenant-scoped pubsub refresh, traced fallback provenance, projection-first dashboard queries]
key-files:
  created: [priv/repo/migrations/20260521000100_add_eval_dashboard_provenance.exs, .planning/phases/34-real-time-operator-dashboards/34-01-SUMMARY.md]
  modified: [lib/scoria/orchestrator.ex, lib/scoria/eval.ex, lib/scoria/eval/judge_runner.ex, lib/scoria/observe/circuit_breaker.ex]
key-decisions:
  - "Kept the existing orchestrator public API stable and added traced variants for fallback-aware consumers."
  - "Projected dashboard state from durable campaign/target truth rather than UI-local counters."
  - "Broadcast campaign and model-health refreshes on tenant-scoped PubSub topics after durable transitions commit."
patterns-established:
  - "Use resolved_provider/resolved_model plus fallback_used as the durable provenance seam for operator-visible fallback truth."
  - "Merge configured fallback-chain catalog with observed campaign/run truth to build model-health matrices."
requirements-completed: [OBS-01, OBS-02]
duration: 1h
completed: 2026-05-21
---

# Phase 34 Plan 01 Summary

**Fallback-aware eval provenance, dashboard projection queries, and tenant-scoped refresh broadcasts now exist as durable operator seams.**

## Performance

- **Duration:** 1h
- **Completed:** 2026-05-21T19:56:26Z
- **Tasks:** 4
- **Files modified:** 12

## Accomplishments
- Added `generate_text_with_trace/3` and `generate_object_with_trace/4` while preserving the old orchestrator API shape.
- Added provenance columns and schema support for `fallback_used`, `resolved_provider`, and `resolved_model` on eval runs and campaign targets.
- Implemented dashboard projection queries, breaker snapshots, and tenant-scoped PubSub refresh hooks for campaign and model-health surfaces.
- Verified the provenance migration against both the test and dev databases with migrate, rollback, and re-apply cycles.

## Files Created/Modified
- `lib/scoria/orchestrator.ex` - traced fallback-aware orchestrator results
- `lib/scoria/eval.ex` - dashboard projections, refresh broadcasts, and campaign rollup hooks
- `lib/scoria/eval/judge_runner.ex` - live judge persistence of resolved model provenance
- `lib/scoria/observe/circuit_breaker.ex` - stable snapshot API for dashboard health queries
- `lib/scoria/req/steps/resiliency.ex` - model-health PubSub broadcasts after breaker-affecting responses
- `lib/scoria/eval/eval_run.ex` - durable provenance fields in schema/changeset
- `lib/scoria/eval/eval_campaign_target.ex` - durable provenance fields in schema/changeset
- `priv/repo/migrations/20260521000100_add_eval_dashboard_provenance.exs` - adds six provenance columns
- `test/scoria/orchestrator_test.exs` - traced orchestrator contract coverage
- `test/scoria/eval/campaign_worker_test.exs` - durable provenance and tenant-scoped progress broadcast coverage
- `test/scoria/eval/dashboard_projection_test.exs` - projection query contract coverage
- `test/scoria/req/steps/resiliency_test.exs` - model-health broadcast coverage

## Decisions Made
- Kept fallback provenance on both `ai_eval_runs` and `ai_eval_campaign_targets` so campaign detail queries can stay shallow and durable.
- Reloaded shared dashboard state from canonical query APIs on broadcasts instead of mutating counters incrementally.
- Scoped campaign-progress broadcasts to the target tenant used by the worker contract so operator subscribers see the correct tenant feed.

## Deviations from Plan

None in scope. The only workflow deviation was manual orchestration because the local `gsd-sdk query` interface referenced by `gsd-execute-phase` was unavailable in this environment.

## Issues Encountered

- The delegated executor stalled after partial edits and no summary output; the plan was resumed and completed locally from the in-progress diff.
- The dashboard projection seed originally violated duplicate-runtime-target validation, so the new test fixture was adjusted to use distinct target models while preserving the same fallback/failed/operator truth.

## Verification

- `mix test test/scoria/orchestrator_test.exs test/scoria/eval/campaign_worker_test.exs test/scoria/eval/dashboard_projection_test.exs test/scoria/req/steps/resiliency_test.exs`
- `MIX_ENV=test mix ecto.migrate`
- `mix ecto.migrate`
- `mix ecto.rollback --step 1`
- `mix ecto.migrate`

## Next Phase Readiness

Plan 34-02 can proceed. The blocking migration checkpoint passed: the dev database accepted migrate, rollback, and re-apply, and both `ai_eval_runs` and `ai_eval_campaign_targets` now expose `fallback_used`, `resolved_provider`, and `resolved_model`.
