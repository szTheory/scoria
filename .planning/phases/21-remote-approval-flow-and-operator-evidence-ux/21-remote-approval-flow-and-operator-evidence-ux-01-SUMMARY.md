## Plan 21-01 Summary

- Added migration `priv/repo/migrations/20260518000100_enrich_remote_approval_truth.exs` to enrich `ai_approvals` with connector, local-tool, blocker, scope, replay, and audit/workflow lineage fields.
- Extended `Scoria.Workflows` and `Scoria.Observe.Approval` so remote blockers and risky remote actions write workflow-owned approval truth with durable request audit refs.
- Updated connector auth/scope and invocation flows to pause risky remote paths through workflow-owned approvals instead of UI-only state.
- Added `Scoria.Workflows.RemoteApprovalProjection` for durable inbox/detail reads.

## Verification

- `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/observe/approval_test.exs test/scoria/workflows_test.exs test/scoria/connectors/invocation_test.exs`
