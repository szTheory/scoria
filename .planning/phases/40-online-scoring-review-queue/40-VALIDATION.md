---
phase: 40
slug: online-scoring-review-queue
status: in_review
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-23
---

# Phase 40 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/scoria/eval/campaign_enqueue_test.exs test/scoria/eval/online_score_sampler_test.exs test/scoria/eval/campaign_worker_test.exs test/scoria/eval/review_queue_test.exs test/scoria/eval_test.exs test/scoria/workflows/dataset_promotion_test.exs test/scoria/workflows/remote_approval_projection_test.exs test/scoria_web/live/review_queue_live_test.exs test/scoria_web/live/orchestrator_live_test.exs test/scoria_web/live/workflow_live_test.exs test/scoria_web/live/dataset_live/promote_component_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run the task-local smoke command in that task's `<verify>` block.
- **After every plan wave:** Run `mix test`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Target task-local latency:** under 30 seconds
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 40-01-01 | 01 | 1 | SCOR-01, SCOR-02 | T-40-01 | Score rows and candidate rows persist the richer rationale, provenance, and dedupe fields Phase 40 requires before any async flow uses them. | migration + persistence smoke | `mix test test/scoria/eval/campaign_worker_test.exs` | ✅ | ✅ green |
| 40-02-01 | 02 | 2 | SCOR-01 | T-40-03 | Eligibility selection runs from an async sampler trigger after durable trace/workflow persistence, and each selected trace stores sampler provenance before scoring fan-out. | sampler smoke | `mix test test/scoria/eval/online_score_sampler_test.exs` | ✅ | ✅ green |
| 40-02-02 | 02 | 2 | SCOR-01 | T-40-04 | Candidate creation is idempotent enough to avoid duplicate queueing for the same sampled trace window and always persists before enqueueing work. | enqueue + repo smoke | `mix test test/scoria/eval/campaign_enqueue_test.exs test/scoria/eval/online_score_sampler_test.exs` | ✅ | ✅ green |
| 40-03-01 | 03 | 3 | SCOR-02 | T-40-05 | Deterministic-first scoring persists scorer kind, version, and sampling provenance on each reviewable score record. | eval backend smoke | `mix test test/scoria/eval/campaign_worker_test.exs` | ✅ | ✅ green |
| 40-03-02 | 03 | 3 | SCOR-02 | T-40-06 | Optional judge scoring appends model-backed rationale without overwriting deterministic evidence. | judge pipeline smoke | `mix test test/scoria/eval/campaign_worker_test.exs` | ✅ | ✅ green |
| 40-04-01 | 04 | 4 | SCOR-03 | T-40-07 | Review queue projection returns operator-ready rows with workflow and runtime deep-link DTOs plus rationale/provenance detail data. | projection smoke | `mix test test/scoria/eval/review_queue_test.exs` | ✅ | ✅ green |
| 40-05-01 | 05 | 5 | SCOR-03 | T-40-09 | Queue UI renders the dedicated queue, detail rail, and both `/scoria/workflows/:id` and `/scoria?runtime=...` deep links from projection DTOs. | LiveView smoke | `mix test test/scoria_web/live/review_queue_live_test.exs test/scoria_web/live/orchestrator_live_test.exs test/scoria_web/live/workflow_live_test.exs` | ✅ | ✅ green |
| 40-06-01 | 06 | 6 | SCOR-04 | T-40-11 | Draft promotion candidates remain reviewable and route to open-dataset draft promotion only after explicit operator action. | promotion smoke | `mix test test/scoria/eval_test.exs test/scoria_web/live/review_queue_live_test.exs test/scoria_web/live/dataset_live/promote_component_test.exs` | ✅ | ✅ green |
| 40-07-01 | 07 | 7 | SCOR-04 | T-40-13 | Sealed baseline targets stay approval-gated and never auto-mutate from online scoring completion. | workflow approval smoke | `mix test test/scoria/workflows/dataset_promotion_test.exs test/scoria/workflows/remote_approval_projection_test.exs test/scoria_web/live/review_queue_live_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing infrastructure covers all phase requirements.
- [x] Add `test/scoria/eval/online_score_sampler_test.exs` for eligibility, async trigger, and provenance coverage.
- [x] Add `test/scoria/eval/review_queue_test.exs` for review-queue projection coverage.
- [x] Add `test/scoria_web/live/review_queue_live_test.exs` for queue selection, triage, and deep-link rendering coverage.

---

## Manual-Only Verifications

None for Phase 40 acceptance.

Phase 40 shifts the former browser/UAT checks into CI-backed LiveView assertions:

- `test/scoria_web/live/review_queue_live_test.exs` now locks in the queue surface copy, action labels, `phx-disable-with` submit states, and the distinction between open-dataset promotion and sealed-baseline approval CTAs.
- The same LiveView coverage verifies success feedback keeps promoted candidates visible with the resulting dataset reference.
- `test/scoria/workflows/dataset_promotion_test.exs` and `test/scoria/workflows/remote_approval_projection_test.exs` cover the sealed-baseline approval path and prove that no sealed dataset mutation happens on queue approval request.

Residual visual polish concerns remain non-blocking design feedback, not release-gating UAT.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or existing coverage lanes
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Task-local smoke lanes target < 30s
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-23

## Execution Closeout

- Targeted Phase 40 validation lanes passed on 2026-05-23 and 2026-05-24.
- The required human checkpoint for Plan `40-06` was approved by the user on 2026-05-24.
- Full-suite verification remains open: `mix test` finished on 2026-05-24 with `330 tests, 6 failures (13 excluded)`, including at least one unrelated sandbox ownership failure in `test/scoria/eval/eval_campaign_persistence_test.exs`.
