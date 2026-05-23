---
phase: 40
slug: online-scoring-review-queue
status: draft
nyquist_compliant: true
wave_0_complete: false
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
| **Quick run command** | `mix test test/scoria/eval/campaign_enqueue_test.exs test/scoria/eval/campaign_worker_test.exs test/scoria/workflows/remote_approval_projection_test.exs` |
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
| 40-01-01 | 01 | 1 | SCOR-01 | T-40-01 | Sampling and candidate persistence stay off the request path and enqueue durable scoring work through Oban. | async backend smoke | `mix test test/scoria/eval/campaign_enqueue_test.exs` | ✅ | ⬜ pending |
| 40-01-02 | 01 | 1 | SCOR-01 | T-40-02 | Candidate creation is idempotent enough to avoid duplicate queueing for the same sampled trace window. | worker + repo smoke | `mix test test/scoria/eval/campaign_enqueue_test.exs test/scoria/eval/campaign_worker_test.exs` | ✅ | ⬜ pending |
| 40-02-01 | 02 | 2 | SCOR-02 | T-40-03 | Deterministic-first scoring persists scorer kind, version, and sampling provenance on each reviewable score record. | eval backend smoke | `mix test test/scoria/eval/campaign_worker_test.exs` | ✅ | ⬜ pending |
| 40-02-02 | 02 | 2 | SCOR-02 | T-40-04 | Optional judge scoring appends model-backed rationale without overwriting deterministic evidence. | judge pipeline smoke | `mix test test/scoria/eval/campaign_worker_test.exs` | ✅ | ⬜ pending |
| 40-03-01 | 03 | 3 | SCOR-03 | T-40-05 | Review queue projection returns operator-ready rows with deep links to workflow and trace evidence. | projection smoke | `mix test test/scoria/workflows/remote_approval_projection_test.exs` | ✅ | ⬜ pending |
| 40-03-02 | 03 | 3 | SCOR-03 | T-40-06 | Queue UI triage actions show rationale and preserve dismiss/review state without dropping evidence. | LiveView smoke | `mix test test/scoria_web/live/workflow_live_test.exs test/scoria_web/live/dataset_live/promote_component_test.exs` | ✅ | ⬜ pending |
| 40-04-01 | 04 | 4 | SCOR-04 | T-40-07 | Draft promotion candidates remain reviewable and route to open-dataset draft promotion only after operator action. | promotion smoke | `mix test test/scoria/eval_test.exs test/scoria_web/live/dataset_live/promote_component_test.exs` | ✅ | ⬜ pending |
| 40-04-02 | 04 | 4 | SCOR-04 | T-40-08 | Sealed baseline targets stay approval-gated and never auto-mutate from online scoring completion. | workflow approval smoke | `mix test test/scoria/workflows/dataset_promotion_test.exs test/scoria/workflows/remote_approval_projection_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing infrastructure covers all phase requirements.
- [ ] Add any missing score-evidence storage tests if `Scoria.Eval.Score` expands beyond the current schema surface.
- [ ] Add review-queue projection coverage if Phase 40 introduces a new projection module rather than extending an existing one.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Review queue layout keeps low-score severity, rationale, and deep-link actions readable on desktop and narrow widths. | SCOR-03 | Current automated coverage can verify state and content presence, but not operator readability and hierarchy. | Open the Phase 40 queue surface in the browser, inspect several candidate states, and confirm rationale, severity, and workflow/trace links remain legible at desktop and mobile widths. |
| Promotion and dismissal copy clearly distinguishes additive score evidence from any mutation of sealed baseline truth. | SCOR-04 | This is a UX/comprehension check rather than a pure state assertion. | Review candidate actions for both open datasets and sealed baselines, and confirm the UI makes draft promotion explicit while sealed baselines stay approval-gated. |

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
