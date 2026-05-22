# Phase 19: Remote Connector Boundary and Auth Discovery - Patterns

**Mapped:** 2026-05-17
**Source:** Local Scoria codebase

## Strongest Reusable Patterns

### Public boundary and normalization

- Keep the host-facing API thin like `Scoria` and `Scoria.Runtime`.
- Normalize edge input once through a dedicated params/identity seam before runtime logic executes.
- Relevant anchors:
  - `lib/scoria.ex`
  - `lib/scoria/runtime.ex`
  - `lib/scoria/runtime/params.ex`
  - `lib/scoria/identity.ex`

### Durable truth through service contexts

- Durable truth lives in service/context modules, not Phoenix routers or LiveViews.
- Use `Ecto.Multi` and transactional writes for coordinated row creation plus audit/event side effects.
- Relevant anchors:
  - `lib/scoria/workflows.ex`
  - `lib/scoria/workflows/run.ex`
  - `lib/scoria/sre.ex`

### Schema and migration conventions

- Binary UUID primary keys
- `utc_datetime_usec` timestamps
- explicit status fields and constraints
- map fields default to `%{}`
- DB constraints mirrored in changesets
- Relevant anchors:
  - `lib/scoria/workflows/run.ex`
  - `lib/scoria/sre/audit_outbox_event.ex`
  - `priv/repo/migrations/20260511000100_create_workflow_tables.exs`
  - `priv/repo/migrations/20260511171000_create_sre_incident_and_audit_tables.exs`

### Secret-bearing audit and redaction

- Redact sensitive payloads before persistence/export while keeping durable audit creation tied to the truth-changing transaction.
- Relevant anchors:
  - `lib/scoria/observe/redactor.ex`
  - `lib/scoria/sre.ex`
  - `test/scoria/sre/audit_outbox_test.exs`

### Background work posture

- The repo currently uses supervised tasks and small coordinators rather than an existing job framework.
- If Phase 19 adds discovery/refresh background work, it should either follow that posture or deliberately introduce a new queueing layer as part of the plan.
- Relevant anchors:
  - `lib/scoria/workflows/reconciler.ex`
  - `lib/scoria/sre/relay.ex`
  - `lib/scoria/application.ex`

### MCP integration seam

- Transport stays thin at the router boundary.
- Policy, breaker, budget, and audit-sensitive behavior belongs deeper in execution/service seams.
- Remote connector/auth work should feed those seams rather than leak into request or UI code.
- Relevant anchors:
  - `lib/scoria/mcp/router.ex`
  - `lib/scoria/mcp/executor.ex`

## Testing Patterns To Reuse

- Public/runtime boundary tests:
  - `test/scoria/runtime_test.exs`
  - `test/scoria/runtime_integration_test.exs`
- Durable workflow truth tests:
  - `test/scoria/workflows_test.exs`
  - `test/scoria/workflows/integration_test.exs`
- Audit/redaction tests:
  - `test/scoria/sre/audit_outbox_test.exs`
- MCP boundary tests:
  - `test/scoria/mcp/executor_test.exs`

## Likely File Targets For Phase 19

- `lib/scoria.ex`
- `lib/scoria/runtime.ex`
- `lib/scoria/runtime/params.ex`
- `lib/scoria/runtime/defaults.ex`
- `lib/scoria/workflows.ex`
- `lib/scoria/workflows/runtime.ex`
- `lib/scoria/workflows/reconciler.ex`
- `lib/scoria/mcp/router.ex`
- `lib/scoria/mcp/executor.ex`
- `lib/scoria/sre.ex`
- `lib/scoria/sre/audit_outbox_event.ex`
- `lib/scoria/sre/relay.ex`
- `priv/repo/migrations/20260511000100_create_workflow_tables.exs`
- `priv/repo/migrations/20260511171000_create_sre_incident_and_audit_tables.exs`

---

*Phase: 19-remote-connector-boundary-and-auth-discovery*
*Pattern map completed: 2026-05-17*
