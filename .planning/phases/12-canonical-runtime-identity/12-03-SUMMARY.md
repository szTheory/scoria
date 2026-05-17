---
phase: 12
plan: 03
subsystem: telemetry-audit-alignment
tags: [identity, telemetry, audit]
completed: 2026-05-13
---

# Phase 12 Plan 03 Summary

**Telemetry and audit projections now read from the same canonical root identity contract, while keeping actor and session out of high-cardinality SRE label dimensions.**

## Accomplishments
- Aligned workflow runtime, MCP executor, and telemetry identity helpers so tenant, run, actor, and session projections come from canonical root identity first.
- Preserved the low-cardinality telemetry posture by keeping `actor_id` and `session_id` in refs and evidence metadata rather than label keys.
- Tightened audit evidence and telemetry regression assertions around approval lineage, tool execution, and metadata-secondary behavior.
- Updated stale router and public API smoke tests so the repo test surface reflects the new canonical identity contract.

## Verification
- `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/workflows/runtime_telemetry_test.exs test/scoria/mcp/executor_telemetry_test.exs test/scoria/sre/telemetry_test.exs`
- `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/sre/audit_outbox_test.exs`
- `SCORIA_DB_PORT=55432 MIX_ENV=test mix test`
