---
phase: 40-online-scoring-review-queue
plan: 07
subsystem: approvals
tags: [review-queue, workflows, approvals, dataset-promotion]
requires:
  - phase: 40-06
    provides: approved review-queue action loop and shared promotion payload builder
  - phase: 39-04
    provides: sealed-baseline approval boundary and projection patterns
provides:
  - sealed-baseline approval requests from review candidates
  - durable approval lineage preserved on review queue detail DTOs
  - queue copy that keeps additive score evidence distinct from sealed release truth
affects: [workflow-approvals, review-queue-ui, dataset-baselines]
tech-stack:
  added: []
  patterns: [approval-gated baseline requests, queue-visible approval lineage]
key-files:
  created: [.planning/phases/40-online-scoring-review-queue/40-online-scoring-review-queue-07-SUMMARY.md]
  modified:
    - lib/scoria/eval/review_queue.ex
    - lib/scoria/workflows/dataset_promotion.ex
    - lib/scoria/workflows/remote_approval_projection.ex
    - lib/scoria_web/live/review_queue_live.ex
    - test/scoria/workflows/dataset_promotion_test.exs
    - test/scoria/workflows/remote_approval_projection_test.exs
    - test/scoria_web/live/review_queue_live_test.exs
key-decisions:
  - "Sealed-baseline requests continue to use the exact `dataset_baseline_promotion` workflow approval identity."
  - "Candidate state can move to `approval_requested`, but online scoring completion itself never invokes the baseline-approval path automatically."
patterns-established:
  - "Queue detail DTOs carry approval lineage so operators can continue review after requesting sealed-baseline promotion."
  - "Review-candidate promotion context is reused for both open-dataset promotion and sealed-baseline approval, with the workflow boundary deciding mutability."
requirements-completed: [SCOR-04]
completed: 2026-05-24
---

# Phase 40 Plan 07: Sealed-Baseline Approval Summary

**Finished the sealed-baseline half of the review loop by routing queue actions through workflow approvals and preserving approval lineage on the queue surface.**

## Accomplishments
- Added sealed-baseline approval requests from review candidates through `Scoria.Workflows.request_baseline_promotion/1`.
- Preserved queue-visible approval lineage after request creation through review queue detail DTOs and approval projection reads.
- Kept sealed datasets immutable from online scoring completion paths while distinguishing additive score evidence from release-truth mutation.
- Locked the path with targeted workflow approval and review queue tests.

## Verification
- `mix test test/scoria/workflows/dataset_promotion_test.exs test/scoria/workflows/remote_approval_projection_test.exs test/scoria_web/live/review_queue_live_test.exs`

## Notes
- This summary reconciles an already-implemented working-tree slice during phase closeout; no new git commit was created in this run.

## Self-Check: PASSED

- Verified sealed-baseline approval coverage in the targeted Phase 40 workflow lanes.
- Verified `.planning/phases/40-online-scoring-review-queue/40-online-scoring-review-queue-07-SUMMARY.md` exists on disk.

---
*Phase: 40-online-scoring-review-queue*
*Completed: 2026-05-24*
