---
phase: 33
slug: distributed-evaluation-fan-out
status: executed
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-21
executed_on: 2026-05-21
verified_by_phase: 35-vanguard-verification-backfill
---

# Phase 33 — Validation Strategy

> Backfilled Nyquist validation map derived from the landed Phase 33 implementation and summaries.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `ExUnit` plus planning-doc grep verification |
| **Config file** | `config/test.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/scoria/eval/eval_campaign_persistence_test.exs test/scoria/eval/eval_run_persistence_test.exs test/scoria/eval/campaign_enqueue_test.exs test/scoria/eval/campaign_worker_test.exs test/scoria/eval/judge_runner_test.exs` |
| **Full suite command** | `MIX_ENV=test mix test` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- Run the plan-local command after each evidence change to the phase-local docs.
- Re-run the quick run command before citing the validation map as canonical proof input.
- Use grep verification to confirm `EVAL-02` and every primary proof file remain explicit in the doc set.

---

## Per-Task Verification Map

| Task ID | Plan | Requirement | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|-------------|-----------------|-----------|-------------------|-------------|--------|
| 33-01-01 | 01 | `EVAL-02` | Campaign schema, target schema, and eval-run lineage remain durable and migration-safe | persistence + migration | `MIX_ENV=test mix test test/scoria/eval/eval_campaign_persistence_test.exs test/scoria/eval/eval_run_persistence_test.exs` | ✅ | ✅ green |
| 33-02-01 | 02 | `EVAL-02` | Coordinator persists campaign truth and batch-enqueues replay-safe worker jobs on `:evals` | integration | `MIX_ENV=test mix test test/scoria/eval/campaign_enqueue_test.exs` | ✅ | ✅ green |
| 33-03-01 | 03 | `EVAL-02` | Worker execution finalizes durable target/run truth and campaign rollups through the orchestrator seam | integration | `MIX_ENV=test mix test test/scoria/eval/campaign_worker_test.exs test/scoria/eval/judge_runner_test.exs` | ✅ | ✅ green |

*Status: ✅ green · ❌ red*

---

## Automated Operator Closure

The canonical proof package for `EVAL-02` is:

1. `test/scoria/eval/eval_campaign_persistence_test.exs`
   Proves durable campaign schema, target schema, and eval-run lineage persistence.
2. `test/scoria/eval/eval_run_persistence_test.exs`
   Proves legacy-compatible lineage persistence and migration-safe run truth.
3. `test/scoria/eval/campaign_enqueue_test.exs`
   Proves coordinator fan-out, normalized `:evals` queue routing, and replay-safe enqueue payloads.
4. `test/scoria/eval/campaign_worker_test.exs` and `test/scoria/eval/judge_runner_test.exs`
   Prove worker execution, durable finalization, rollups, and orchestrator-backed shard execution.

---

## Validation Sign-Off

- [x] All primary proof lanes use current executable `MIX_ENV=test` commands
- [x] `EVAL-02` maps to durable persistence, enqueue, and worker-execution seams
- [x] The validation map reflects landed implementation, not a blank planning stub
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** Executed during the Phase 35 verification-chain backfill on 2026-05-21. Canonical closure is recorded in `33-VERIFICATION.md`.
