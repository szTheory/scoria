# Phase 05 Plan 01: Durable Workflow Persistence Foundation Summary

## Summary
Implemented the phase-5 persistence layer around `Scoria.Workflows` with Ecto-backed workflow runs, steps, checkpoints, events, and handoffs. Added additive migrations for the new workflow tables and approval linkage so durable pauses can participate in the same source of truth.

## Delivered
- Added `ai_workflow_runs`, `ai_workflow_steps`, `ai_workflow_checkpoints`, `ai_workflow_events`, and `ai_workflow_handoffs`.
- Added `workflow_run_id`, `step_id`, `checkpoint_id`, and `lock_version` to `ai_approvals`.
- Implemented workflow schemas with lifecycle validation and optimistic locking on root/operator-facing records.
- Implemented `Scoria.Workflows` transactional APIs for run creation, checkpoint and event appends, step completion, failure, retry, and approval waits.
- Added focused persistence tests in `test/scoria/workflows_test.exs`.

## Verification
- `MIX_ENV=test mix test test/scoria/workflows_test.exs`

## Notes
- Workflow truth is now database-first; PubSub is only used for projection refresh.
