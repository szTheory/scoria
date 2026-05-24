---
status: complete
mode: shift-left
phase: 37-replay-lineage-branch-model
source:
  - 37-01-SUMMARY.md
  - 37-02-SUMMARY.md
  - 37-03-SUMMARY.md
started: 2026-05-24T10:27:01Z
updated: 2026-05-24T10:27:01Z
human_steps_required: 0
automation_deferred: []
---

## Current Test

[testing complete]

## Automation Map

1. Cold Start Smoke Test
   - Evidence: `mix test test/scoria/bootstrap/migration_lane_compatibility_test.exs`
   - Historical proof: `mix ecto.migrate`, `mix ecto.rollback --step 1`, `mix ecto.migrate` completed on 2026-05-23 per `37-VALIDATION.md`
2. Persist Replay Branch Lineage
   - Evidence: `mix test test/scoria/workflows_test.exs test/scoria/workflows/replay_branch_test.exs`
3. Replay Runtime Reuse
   - Evidence: `mix test test/scoria/workflows_test.exs test/scoria/workflows/replay_branch_test.exs test/scoria/runtime_test.exs`
4. Workflow Replay Provenance Surface
   - Evidence: `mix test test/scoria/runtime_view_test.exs test/scoria_web/live/workflow_live_test.exs`
5. Trace-Facing Replay Lineage Surface
   - Evidence: `mix test test/scoria_web/live/orchestrator_live_test.exs`

## Tests

### 1. Cold Start Smoke Test
expected: Kill any running server/service. Clear ephemeral state for the migration lane. Start from a fresh schema state and confirm migration/bootstrap paths complete without errors.
result: pass

### 2. Persist Replay Branch Lineage
expected: Creating a replay branch stores typed source lineage on the new run, rejects invalid run/checkpoint pairing, and leaves the source run unchanged.
result: pass

### 3. Replay Runtime Reuse
expected: Starting a replay branch reuses the normal workflow runtime path, records replay-start evidence before dispatch, and keeps the branch visible through normal runtime reads.
result: pass

### 4. Workflow Replay Provenance Surface
expected: Public run detail and workflow page show replay provenance from stable DTO fields, including source run, source checkpoint, execution mode, and overrides.
result: pass

### 5. Trace-Facing Replay Lineage Surface
expected: Trace-facing operator views project replay lineage from run-linked workflow truth and show replay branch context without template-side scraping.
result: pass

## Summary

total: 5
passed: 5
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

None.
