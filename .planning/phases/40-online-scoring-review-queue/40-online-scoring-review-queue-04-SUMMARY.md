---
phase: 40-online-scoring-review-queue
plan: 04
subsystem: review-queue
tags: [online-scoring, review-queue, projection, eval]
requires:
  - phase: 40-03
    provides: durable candidate score summaries and review-state derivation
provides:
  - operator-ready review queue projection rows and detail DTOs
  - queue summary strip counts and severity ranking
  - workflow and runtime deep-link generation from durable candidate lineage
affects: [phase-40-05, phase-40-06, orchestrator, workflow-live]
tech-stack:
  added: []
  patterns: [projection-first queue reads, durable deep-link DTOs, severity ordering]
key-files:
  created:
    - lib/scoria/eval/review_queue.ex
    - .planning/phases/40-online-scoring-review-queue/40-online-scoring-review-queue-04-SUMMARY.md
  modified:
    - lib/scoria/eval.ex
    - test/scoria/eval/review_queue_test.exs
key-decisions:
  - "The review queue is exposed as a backend projection module instead of assembled ad hoc in LiveView templates."
  - "Runtime and workflow deep links are emitted directly from candidate DTOs so operator surfaces do not rebuild lineage."
patterns-established:
  - "Queue rows sort by severity first, then insertion order."
  - "Promotion and approval actions resolve through candidate projection context rather than duplicating dataset-promotion payload shaping in the UI."
requirements-completed: [SCOR-03]
completed: 2026-05-24
---

# Phase 40 Plan 04: Review Queue Projection Summary

**Added a dedicated review-queue projection that turns persisted online-scoring candidates into operator-ready list, detail, and summary DTOs.**

## Accomplishments
- Added `Scoria.Eval.ReviewQueue` as the single backend seam for queue rows, detail rails, counts, and action context.
- Projected durable workflow/runtime deep links and promotion context from `OnlineScoreCandidate` lineage instead of rebuilding them in LiveView.
- Added explicit backend actions for dismiss, open-dataset promotion, and sealed-baseline approval requests.
- Locked projection behavior with dedicated backend tests for detail DTOs, queue ordering, and deep-link preservation.

## Verification
- `mix test test/scoria/eval/review_queue_test.exs`

## Notes
- This summary reconciles an already-implemented working-tree slice during phase closeout; no new git commit was created in this run.

## Self-Check: PASSED

- Verified queue projection coverage in `test/scoria/eval/review_queue_test.exs`.
- Verified `.planning/phases/40-online-scoring-review-queue/40-online-scoring-review-queue-04-SUMMARY.md` exists on disk.

---
*Phase: 40-online-scoring-review-queue*
*Completed: 2026-05-24*
