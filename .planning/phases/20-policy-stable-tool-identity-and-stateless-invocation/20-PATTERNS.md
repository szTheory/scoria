# Phase 20: Policy, Stable Tool Identity, and Stateless Invocation - Patterns

**Mapped:** 2026-05-17
**Source:** Local Scoria codebase

## Strongest Reusable Patterns

### Durable truth through connector context modules

- `Scoria.Connectors` already uses `Ecto.Multi`, explicit row ownership, and audit side effects for truth-changing operations.
- Discovery refresh already writes durable connector and snapshot truth transactionally.
- Relevant anchors:
  - `lib/scoria/connectors.ex`
  - `lib/scoria/connectors/discovery.ex`
  - `lib/scoria/connectors/connector.ex`
  - `lib/scoria/connectors/grant.ex`
  - `lib/scoria/connectors/capability_snapshot.ex`

### Typed execution envelopes and policy-sensitive audit seams

- `Scoria.MCP.Executor` already models typed blocked outcomes, budget and breaker coordination, and pre-execution audit writes.
- Phase 20 should mirror this style for remote connector invocation rather than inventing a parallel error or evidence shape.
- Relevant anchors:
  - `lib/scoria/mcp/executor.ex`
  - `test/scoria/mcp/executor_test.exs`
  - `test/scoria/mcp/executor_telemetry_test.exs`

### Audit and evidence posture

- Security-sensitive paths emit durable audit rows with redacted refs and stable policy metadata.
- Phase 20 should extend these audit envelopes with connector and local-tool-specific metadata rather than adding a second evidence style.
- Relevant anchors:
  - `lib/scoria/sre.ex`
  - `lib/scoria/sre/audit_outbox_event.ex`
  - `test/scoria/sre/audit_outbox_test.exs`

### Schema conventions

- Binary UUID primary keys
- `utc_datetime_usec` timestamps
- explicit enum-like status fields
- optimistic locking on mutable durable truth
- `%{}` defaults for metadata maps
- encrypted secret-bearing fields separated from queryable metadata
- Relevant anchors:
  - `lib/scoria/connectors/connector.ex`
  - `lib/scoria/connectors/grant.ex`
  - `lib/scoria/connectors/capability_snapshot.ex`
  - `priv/repo/migrations/20260517000100_create_connector_boundary_tables.exs`

## Testing Patterns To Reuse

- Connector context integration and job trigger tests:
  - `test/scoria/connectors_test.exs`
  - `test/scoria/connectors/discovery_job_test.exs`
- Connector schema and encrypted-at-rest expectations:
  - `test/scoria/connectors/schema_test.exs`
  - `test/scoria/connectors/auth_test.exs`
- Policy-sensitive execution and audit envelope expectations:
  - `test/scoria/mcp/executor_test.exs`
  - `test/scoria/mcp/executor_telemetry_test.exs`

## Likely File Targets For Phase 20

- `lib/scoria/connectors.ex`
- `lib/scoria/connectors/discovery.ex`
- `lib/scoria/connectors/connector.ex`
- `lib/scoria/connectors/grant.ex`
- `lib/scoria/connectors/capability_snapshot.ex`
- `lib/scoria/mcp/executor.ex`
- `lib/scoria/sre.ex`
- `lib/scoria/sre/audit_outbox_event.ex`
- `test/scoria/connectors_test.exs`
- `test/scoria/connectors/schema_test.exs`
- `test/scoria/connectors/auth_test.exs`
- `test/scoria/mcp/executor_test.exs`
- `test/scoria/mcp/executor_telemetry_test.exs`
- `priv/repo/migrations/20260517000100_create_connector_boundary_tables.exs`
- a new connector-tool or invocation-specific migration in `priv/repo/migrations/`

## Likely New Modules

- a durable local tool schema such as `lib/scoria/connectors/local_tool.ex`
- a reconciliation service such as `lib/scoria/connectors/tool_reconciliation.ex`
- an invocation or policy seam such as `lib/scoria/connectors/invocation.ex`
- optionally a small risk or classification helper if local action class derivation needs a dedicated boundary

## Planning Implications

- Keep plan boundaries aligned to durable seams, not UI seams.
- Put migration and schema work ahead of reconciliation logic.
- Keep refresh reconciliation separate from invocation enforcement so the execution path can rely on durable local tool truth.
- Reuse existing ExUnit and audit-envelope patterns instead of adding a new verification style.

---

*Phase: 20-policy-stable-tool-identity-and-stateless-invocation*
*Pattern map completed: 2026-05-17*
