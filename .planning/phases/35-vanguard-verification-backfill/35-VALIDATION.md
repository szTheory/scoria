---
phase: 35
slug: vanguard-verification-backfill
status: executed
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-21
executed_on: 2026-05-21
---

# Phase 35 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `ExUnit` plus planning-doc grep verification |
| **Config file** | `config/test.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/scoria/oban_config_test.exs test/scoria/workflows/batch_enqueue_test.exs test/scoria/observe/circuit_breaker_test.exs test/scoria/observe/circuit_breaker_manager_test.exs test/scoria/req/steps/circuit_breaker_test.exs test/scoria/req/steps/resiliency_test.exs test/scoria/req/steps_test.exs test/scoria/orchestrator_test.exs test/scoria/compaction/summarize_worker_test.exs test/scoria/eval/judge_runner_test.exs test/scoria/eval/eval_campaign_persistence_test.exs test/scoria/eval/eval_run_persistence_test.exs test/scoria/eval/campaign_enqueue_test.exs test/scoria/eval/campaign_worker_test.exs test/scoria/eval/dashboard_projection_test.exs test/scoria_web/live/orchestrator_live_test.exs` |
| **Full suite command** | `MIX_ENV=test mix test` |
| **Estimated runtime** | ~120 seconds |

---

## Sampling Rate

- **After every task commit:** Run the task-local command plus a grep check on the touched planning artifacts.
- **After every plan wave:** Run the quick run command.
- **Before `$gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** 120 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 35-01-01 | 01 | 1 | `EVAL-01`, `EVAL-03` | `T-35-01`, `T-35-02` | Phase 30 verification cites exact queue and batch-enqueue proof instead of summary-only claims | docs + unit | `rg -n "EVAL-01|EVAL-03|MIX_ENV=test mix test test/scoria/oban_config_test.exs|MIX_ENV=test mix test test/scoria/workflows/batch_enqueue_test.exs" .planning/phases/30-oban-infrastructure-and-queue-segregation/30-VERIFICATION.md .planning/phases/30-oban-infrastructure-and-queue-segregation/30-VALIDATION.md && MIX_ENV=test mix test test/scoria/oban_config_test.exs test/scoria/workflows/batch_enqueue_test.exs` | ✅ | ⬜ pending |
| 35-01-02 | 01 | 1 | `ORCH-02`, `ORCH-03` | `T-35-01`, `T-35-02` | Phase 31 verification ties circuit-breaker and retry behavior to targeted lanes with current wording | docs + unit | `rg -n "ORCH-02|ORCH-03|MIX_ENV=test mix test test/scoria/observe/circuit_breaker_test.exs test/scoria/observe/circuit_breaker_manager_test.exs|MIX_ENV=test mix test test/scoria/req/steps_test.exs" .planning/phases/31-model-routing-and-resiliency-foundation/31-VERIFICATION.md .planning/phases/31-model-routing-and-resiliency-foundation/31-VALIDATION.md && MIX_ENV=test mix test test/scoria/observe/circuit_breaker_test.exs test/scoria/observe/circuit_breaker_manager_test.exs test/scoria/req/steps_test.exs` | ✅ | ⬜ pending |
| 35-02-01 | 02 | 2 | `ORCH-01` | `T-35-01`, `T-35-02` | Phase 32 verification closes fallback-routing proof with exact orchestrator and caller-integration lanes | docs + integration | `rg -n "ORCH-01|MIX_ENV=test mix test test/scoria/orchestrator_test.exs|test/scoria/compaction/summarize_worker_test.exs|test/scoria/eval/judge_runner_test.exs" .planning/phases/32-multi-model-fallback-orchestration/32-VERIFICATION.md .planning/phases/32-multi-model-fallback-orchestration/32-VALIDATION.md && MIX_ENV=test mix test test/scoria/orchestrator_test.exs test/scoria/compaction/summarize_worker_test.exs test/scoria/eval/judge_runner_test.exs` | ✅ | ⬜ pending |
| 35-02-02 | 02 | 2 | `EVAL-02` | `T-35-01`, `T-35-03` | Phase 33 gains a modern validation map and canonical verification tied to durable campaign, enqueue, and worker proof | docs + integration | `rg -n "phase: 33|EVAL-02|MIX_ENV=test mix test test/scoria/eval/eval_campaign_persistence_test.exs|test/scoria/eval/campaign_enqueue_test.exs|test/scoria/eval/campaign_worker_test.exs" .planning/phases/33-distributed-evaluation-fan-out/33-VALIDATION.md .planning/phases/33-distributed-evaluation-fan-out/33-VERIFICATION.md && MIX_ENV=test mix test test/scoria/eval/eval_campaign_persistence_test.exs test/scoria/eval/eval_run_persistence_test.exs test/scoria/eval/campaign_enqueue_test.exs test/scoria/eval/campaign_worker_test.exs` | ✅ | ⬜ pending |
| 35-03-01 | 03 | 3 | `OBS-01`, `OBS-02` | `T-35-01`, `T-35-04` | Phase 34 validation and verification use the current supported environment and exact dashboard proof lanes | docs + liveview | `rg -n "OBS-01|OBS-02|MIX_ENV=test mix test test/scoria/eval/dashboard_projection_test.exs|test/scoria_web/live/orchestrator_live_test.exs" .planning/phases/34-real-time-operator-dashboards/34-VALIDATION.md .planning/phases/34-real-time-operator-dashboards/34-VERIFICATION.md && ! rg -n "SCORIA_DB_PORT=55432" .planning/phases/34-real-time-operator-dashboards/34-VALIDATION.md .planning/phases/34-real-time-operator-dashboards/34-VERIFICATION.md && MIX_ENV=test mix test test/scoria/eval/dashboard_projection_test.exs test/scoria_web/live/orchestrator_live_test.exs` | ✅ | ⬜ pending |
| 35-03-02 | 03 | 3 | `EVAL-01`, `EVAL-02`, `EVAL-03`, `ORCH-01`, `ORCH-02`, `ORCH-03`, `OBS-01`, `OBS-02` | `T-35-02`, `T-35-03`, `T-35-04` | The stitched v1.8 proof lane and phase-local verification docs agree, with no remaining orphaned requirement ids across phases 30 through 34 | docs + integration | `MIX_ENV=test mix test test/scoria/oban_config_test.exs test/scoria/workflows/batch_enqueue_test.exs test/scoria/observe/circuit_breaker_test.exs test/scoria/observe/circuit_breaker_manager_test.exs test/scoria/req/steps/circuit_breaker_test.exs test/scoria/req/steps/resiliency_test.exs test/scoria/req/steps_test.exs test/scoria/orchestrator_test.exs test/scoria/compaction/summarize_worker_test.exs test/scoria/eval/judge_runner_test.exs test/scoria/eval/eval_campaign_persistence_test.exs test/scoria/eval/eval_run_persistence_test.exs test/scoria/eval/campaign_enqueue_test.exs test/scoria/eval/campaign_worker_test.exs test/scoria/eval/dashboard_projection_test.exs test/scoria_web/live/orchestrator_live_test.exs && rg -n "EVAL-01|EVAL-02|EVAL-03|ORCH-01|ORCH-02|ORCH-03|OBS-01|OBS-02" .planning/phases/30-oban-infrastructure-and-queue-segregation/30-VERIFICATION.md .planning/phases/31-model-routing-and-resiliency-foundation/31-VERIFICATION.md .planning/phases/32-multi-model-fallback-orchestration/32-VERIFICATION.md .planning/phases/33-distributed-evaluation-fan-out/33-VERIFICATION.md .planning/phases/34-real-time-operator-dashboards/34-VERIFICATION.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing test infrastructure already covers all v1.8 requirement proof lanes.
- [x] Existing summaries and validation docs provide the input evidence for the backfill.
- [x] No new framework or fixture installation is required.

---

## Manual-Only Verifications

All phase behaviors should be automatable. Manual verification is not expected unless a current repo-level environment issue blocks one of the cited proof lanes, in which case the exact blocker must be recorded in the affected `*-VERIFICATION.md` instead of being hidden in summary prose.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify paths
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all dependencies
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** Executed during Phase 35 closeout.
