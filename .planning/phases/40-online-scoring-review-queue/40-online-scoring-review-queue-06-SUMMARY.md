---
phase: 40-online-scoring-review-queue
plan: 06
subsystem: review-actions
tags: [review-queue, dataset-promotion, liveview, eval]
requires:
  - phase: 40-05
    provides: dedicated queue UI and review candidate context surfaces
  - phase: 39-05
    provides: frozen workflow-source promotion payload shaping
provides:
  - backend-owned dismiss and open-dataset promotion actions for review candidates
  - queue detail-rail promotion feedback and dataset reference persistence
  - approved human checkpoint for the draft-promotion queue flow
affects: [phase-40-07, dataset-promotion, review-queue-ui]
tech-stack:
  added: []
  patterns: [shared promotion payload builder, backend-owned review-state transitions]
key-files:
  created: [.planning/phases/40-online-scoring-review-queue/40-online-scoring-review-queue-06-SUMMARY.md]
  modified:
    - lib/scoria/eval/review_queue.ex
    - lib/scoria/eval/dataset_promotion.ex
    - lib/scoria/eval.ex
    - lib/scoria_web/live/review_queue_live.ex
    - lib/scoria_web/live/dataset_live/promote_component.ex
    - test/scoria/eval_test.exs
    - test/scoria_web/live/review_queue_live_test.exs
    - test/scoria_web/live/dataset_live/promote_component_test.exs
key-decisions:
  - "Queue-driven open-dataset promotion reuses the existing Phase 39 workflow-source promotion payload contract instead of duplicating snapshot shaping."
  - "Dismiss and promote transitions are owned by the backend projection boundary, not by LiveView-local state."
patterns-established:
  - "Shared promotion payload construction now lives in `Scoria.Eval.DatasetPromotion.build_promotion_attrs/4`."
  - "Promoted review candidates remain visible long enough to show resulting dataset references and success feedback."
requirements-completed: [SCOR-04]
completed: 2026-05-24
---

# Phase 40 Plan 06: Open-Dataset Review Actions Summary

**Finished the open-dataset half of the review loop by adding backend-owned dismiss/promote actions, reusing the Phase 39 promotion contract, and clearing the required human checkpoint.**

## Accomplishments
- Added dismiss and open-dataset promotion actions through `Scoria.Eval.ReviewQueue` and surfaced them in `ReviewQueueLive`.
- Extracted shared promotion payload shaping into `Scoria.Eval.DatasetPromotion.build_promotion_attrs/4` so queue actions and the existing promote component use the same frozen workflow-source contract.
- Kept promoted candidates visible with success feedback and dataset references instead of immediately dropping them from the operator surface.
- Cleared the required manual checkpoint on 2026-05-24 when the user replied `approved`.

## Verification
- `mix test test/scoria/eval_test.exs test/scoria_web/live/review_queue_live_test.exs test/scoria_web/live/dataset_live/promote_component_test.exs`
- Human checkpoint approved on 2026-05-24

## Notes
- This summary reconciles an already-implemented working-tree slice during phase closeout; no new git commit was created in this run.

## Self-Check: PASSED

- Verified queue dismissal/open-dataset promotion coverage in the targeted Phase 40 promotion lanes.
- Recorded checkpoint approval for the draft-promotion flow before sealed-baseline closeout.
- Verified `.planning/phases/40-online-scoring-review-queue/40-online-scoring-review-queue-06-SUMMARY.md` exists on disk.

---
*Phase: 40-online-scoring-review-queue*
*Completed: 2026-05-24*
