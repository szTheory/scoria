# Phase 20 Plan 03: Policy-Gated Stateless Invocation Summary

## Summary
Implemented a connector-aware invocation gate that enforces local policy plus current remote grant state before execution. Auth failures, policy denials, scope escalation, and unavailable tools now return stable Scoria-owned outcomes with durable audit and workflow lineage, while the default invocation path remains request-scoped and stateless.

## Delivered
- Added `Scoria.Connectors.Invocation` and exposed `Scoria.Connectors.invoke_local_tool/5`.
- Added pre-execution blocked outcomes for `:policy_denied`, `:auth_required`, `:scope_escalation_required`, and `:tool_unavailable`.
- Extended `Scoria.Connectors.Auth` to persist remote auth failure and scope escalation evidence with workflow lineage.
- Added `Scoria.Workflows.record_connector_auth_failure/3` and `record_connector_scope_escalation/3`.
- Updated `Scoria.MCP.Executor` telemetry mapping to handle connector-gated blocked outcomes.
- Added coverage in `test/scoria/connectors/invocation_test.exs`, `test/scoria/connectors/auth_test.exs`, `test/scoria/workflows_test.exs`, and related executor tests.

## Verification
- `SCORIA_DB_PORT=55432 mix test test/scoria/connectors/auth_test.exs test/scoria/connectors/invocation_test.exs test/scoria/mcp/executor_test.exs test/scoria/workflows_test.exs`
- `SCORIA_DB_PORT=55432 mix test test/scoria/connectors/schema_test.exs test/scoria/connectors_test.exs test/scoria/connectors/tool_reconciliation_test.exs test/scoria/connectors/auth_test.exs test/scoria/connectors/invocation_test.exs test/scoria/mcp/executor_test.exs test/scoria/workflows_test.exs`

## Notes
- Audit payload details continue to live under `audit_event.metadata["metadata"]` to match the existing SRE envelope shape.
- No commit was created during this execution.
