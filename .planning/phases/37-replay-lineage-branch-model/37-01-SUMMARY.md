---
phase: 37-replay-lineage-branch-model
plan: 01
requirements-completed: [RPLY-01]
completed: 2026-05-23
---

# Phase 37 Plan 01: Replay Lineage Persistence Summary

## Summary
Added first-class replay lineage to workflow runs and implemented transactional replay branch creation as durable workflow truth. Replay branches are now persisted as new run rows with typed provenance, while source runs remain unchanged.

## Delivered
- Extended `Scoria.Workflows.Run` with `source_run_id`, `source_checkpoint_id`, bounded `execution_mode`, and `replay_overrides`.
- Added `Scoria.Workflows.create_replay_branch/3` to validate source run/checkpoint pairing, inherit canonical identity, create a new branch run, seed replay-start evidence, and update branch pointers in one transaction.
- Added the additive migration `20260523000100_add_replay_lineage_to_workflow_runs.exs` with explicit `up/0` and `down/0` plus lineage indexes.
- Added `test/scoria/workflows/replay_branch_test.exs` and extended `test/scoria/workflows_test.exs` for branch durability, invalid pairing rejection, and historical compatibility.

## Verification
- `mix test test/scoria/workflows/replay_branch_test.exs test/scoria/workflows_test.exs`
- `mix ecto.migrate`
- `mix ecto.rollback --step 1`
- `mix ecto.migrate`
- `mix test test/scoria/bootstrap/migration_lane_compatibility_test.exs`

## Notes
- No existing workflow rows were backfilled or mutated; historical runs remain readable through additive nullable lineage columns.
- No commit was created during this execution.
