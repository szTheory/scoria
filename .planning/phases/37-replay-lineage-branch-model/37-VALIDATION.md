---
phase: 37
slug: replay-lineage-branch-model
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-22
executed_on: 2026-05-23
---

# Phase 37 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` plus repo Ecto sandbox setup |
| **Quick run command** | `mix test test/scoria/workflows/replay_branch_test.exs test/scoria/runtime_test.exs` |
| **Full suite command** | `mix test test/scoria/workflows_test.exs test/scoria/workflows/replay_branch_test.exs test/scoria_web/live/workflow_live_test.exs test/scoria_web/live/orchestrator_live_test.exs` |
| **Estimated runtime** | ~60-120 seconds |

## Sampling Rate

- **After every task commit:** Run `mix test test/scoria/workflows/replay_branch_test.exs test/scoria/runtime_test.exs`
- **After every plan wave:** Run `mix test test/scoria/workflows_test.exs test/scoria/workflows/replay_branch_test.exs test/scoria_web/live/workflow_live_test.exs test/scoria_web/live/orchestrator_live_test.exs`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 37-01-01 | 01 | 1 | RPLY-01 | T-37-01 / T-37-02 | Branch run stores typed source lineage and does not mutate source run truth | integration | `mix test test/scoria/workflows/replay_branch_test.exs` | ✅ | ✅ green |
| 37-02-01 | 02 | 2 | RPLY-01 | T-37-01 | Replay branch dispatch reuses existing workflow runtime path | integration | `mix test test/scoria/workflows/replay_branch_test.exs test/scoria/workflows_test.exs` | ✅ | ✅ green |
| 37-03-01 | 03 | 3 | RPLY-01 | T-37-02 / T-37-03 | Public run detail and workflow page expose replay lineage clearly | liveview | `mix test test/scoria/runtime_view_test.exs test/scoria_web/live/workflow_live_test.exs` | ✅ | ✅ green |
| 37-03-02 | 03 | 3 | RPLY-01 | T-37-03 | Trace-facing operator reads can query replay lineage from run-linked evidence | liveview/integration | `mix test test/scoria_web/live/orchestrator_live_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

## Wave 0 Requirements

- Existing infrastructure covers all phase requirements.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Migration applies and rolls back cleanly on a real local database | RPLY-01 | Ecto schema changes need one real migrate/rollback/migrate proof | Completed with `mix ecto.migrate`, `mix ecto.rollback --step 1`, `mix ecto.migrate` on 2026-05-23 |

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or existing infrastructure coverage
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** executed on 2026-05-23. Replay branches now have durable typed lineage, runtime reuse proof, UI/operator visibility, and a reversible migration lane.
