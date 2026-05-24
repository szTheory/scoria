---
phase: 40-online-scoring-review-queue
plan: 05
subsystem: liveview
tags: [liveview, review-queue, workflow, runtime]
requires:
  - phase: 40-04
    provides: review queue projection rows and detail DTOs
provides:
  - dedicated `/scoria/reviews` queue surface
  - workflow-page review candidate evidence strip
  - runtime landing-page review candidate context strip
affects: [phase-40-06, phase-40-07, review-queue-ui]
tech-stack:
  added: []
  patterns: [projection-backed liveview state, deep-link evidence preservation]
key-files:
  created:
    - lib/scoria_web/live/review_queue_live.ex
    - .planning/phases/40-online-scoring-review-queue/40-online-scoring-review-queue-05-SUMMARY.md
  modified:
    - lib/scoria_web/router.ex
    - lib/scoria_web/live/orchestrator_live.ex
    - lib/scoria_web/live/workflow_live/show.ex
    - test/scoria_web/live/review_queue_live_test.exs
    - test/scoria_web/live/orchestrator_live_test.exs
    - test/scoria_web/live/workflow_live_test.exs
key-decisions:
  - "The queue lives at `/scoria/reviews` under the existing dashboard macro instead of overloading the main orchestrator route."
  - "Queue-selected evidence is preserved on both workflow and runtime deep links through `review_candidate_id` query params."
  - "Optional dashboard components stay guarded with `function_exported?/3` checks so this slice does not depend on unrelated connector UI modules being present."
patterns-established:
  - "The review queue LiveView owns only filter/selection state and delegates all domain reads to `Scoria.Eval.ReviewQueue`."
  - "Workflow and runtime landing surfaces display queue-selected rationale/provenance strips instead of forcing operators to reconstruct context."
requirements-completed: [SCOR-03]
completed: 2026-05-24
---

# Phase 40 Plan 05: Review Queue UI Summary

**Rendered a dedicated operator review queue and preserved queue-selected evidence across both workflow and runtime deep-link surfaces.**

## Accomplishments
- Added `ScoriaWeb.ReviewQueueLive` and the `/scoria/reviews` route with summary strip, filters, list/detail layout, and queue actions.
- Extended `WorkflowLive.Show` to render queue-selected evidence when opened through `?review_candidate_id=...`.
- Extended `OrchestratorLive` to preserve queue-selected runtime context on `/scoria?runtime=...&review_candidate_id=...`.
- Added LiveView coverage for queue rendering and both deep-link landing surfaces.

## Verification
- `mix test test/scoria_web/live/review_queue_live_test.exs test/scoria_web/live/orchestrator_live_test.exs test/scoria_web/live/workflow_live_test.exs`

## Notes
- This summary reconciles an already-implemented working-tree slice during phase closeout; no new git commit was created in this run.

## Self-Check: PASSED

- Verified LiveView queue and deep-link coverage in the targeted Phase 40 UI tests.
- Verified `.planning/phases/40-online-scoring-review-queue/40-online-scoring-review-queue-05-SUMMARY.md` exists on disk.

---
*Phase: 40-online-scoring-review-queue*
*Completed: 2026-05-24*
