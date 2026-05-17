---
phase: 12
plan: 02
subsystem: identity-propagation
tags: [identity, approvals, runtime, mcp]
completed: 2026-05-13
---

# Phase 12 Plan 02 Summary

**Approval, runtime, and MCP execution seams now inherit immutable root identity from the workflow run instead of rebuilding identity from request-scoped fallbacks.**

## Accomplishments
- Added `actor_id` and `tenant_id` columns to `ai_approvals` and updated the approval schema to treat canonical identity as durable row data.
- Refactored workflow approval creation and decision handling so approval lineage and audit context derive from persisted run and approval truth.
- Updated runtime and MCP execution flows to separate canonical root identity from transient execution metadata while preserving compatibility for loose caller attrs.
- Extended workflow, integration, executor, and audit regression coverage around approval propagation and execution-time identity handling.

## Verification
- `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/workflows/runtime_test.exs test/scoria/workflows/integration_test.exs test/scoria/sre/audit_outbox_test.exs`
- `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/mcp/executor_test.exs`

