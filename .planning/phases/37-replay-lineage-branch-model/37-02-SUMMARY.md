# Phase 37 Plan 02: Replay Runtime Reuse Summary

## Summary
Wired replay branches through Scoria's existing workflow runtime path instead of introducing a second execution engine. Replay-start evidence is recorded before dispatch, and branch runs remain visible through the normal runtime APIs.

## Delivered
- Added `Scoria.Runtime.replay_run/3` as the narrow public entry point for branch creation plus dispatch.
- Reused `Scoria.Workflows.create_replay_branch/3` to seed branch state from persisted checkpoint truth and mark the branch `execution_mode` as replay.
- Ensured replay branches inherit canonical identity from the source run and dispatch through the existing runtime/reconciler seam.
- Extended replay-branch and runtime tests to prove runtime reuse, replay-start evidence, and stable queryability through normal runtime reads.

## Verification
- `mix test test/scoria/workflows/replay_branch_test.exs test/scoria/runtime_test.exs`
- `mix test test/scoria/workflows/replay_branch_test.exs test/scoria/workflows_test.exs`

## Notes
- Phase 37 intentionally stops at branch creation and runtime reuse; replay side-effect safety policy remains for later phases.
- No commit was created during this execution.
