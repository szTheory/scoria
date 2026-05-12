# Phase 8: Reconcile Budget Reservations on Breaker-Open Paths - Pattern Map

**Mapped:** 2026-05-12
**Files analyzed:** 4
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/scoria/workflows/runtime.ex` | runtime/orchestration | event-driven | `lib/scoria/workflows/runtime.ex` timeout/execution-failed branches | exact |
| `lib/scoria/mcp/executor.ex` | integration boundary | request-response | `lib/scoria/mcp/executor.ex` timeout/execution-failed branches | exact |
| `test/scoria/workflows/runtime_test.exs` | regression test | event-driven | existing breaker-open and budget-trip tests in same file | exact |
| `test/scoria/mcp/executor_test.exs` | regression test | request-response | existing timeout/crash reconciliation tests in same file | exact |

## Reuse Patterns

### `lib/scoria/workflows/runtime.ex`

Use the existing terminal-branch reconciliation pattern:

```elixir
{:error, {:timeout}} ->
  reconcile_budget(reservation_context, budget_context, %{}, "timeout")
  Workflows.fail_step(step.id, attach_budget_evidence(%{"reason" => "timeout"}, reservation_context))

{:error, {:execution_failed, reason}} ->
  reconcile_budget(reservation_context, budget_context, %{}, "execution_failed")
  Workflows.fail_step(step.id, attach_budget_evidence(%{"reason" => inspect(reason)}, reservation_context))
```

Phase 8 should make the breaker-open branch follow the same shape before the step is failed.

### `lib/scoria/mcp/executor.ex`

Reuse the existing reconciliation pattern:

```elixir
{:error, {:timeout, duration}} ->
  reconcile_budget(execution_context, access_context, %{}, "timeout")
  :telemetry.execute([:scoria, :tool, :timeout], %{duration: duration}, metadata)
  {:error, :timeout}

{:error, {:execution_failed, duration, reason}} ->
  reconcile_budget(execution_context, access_context, %{}, "execution_failed")
  :telemetry.execute([:scoria, :tool, :failed], %{duration: duration}, Map.put(metadata, :reason, reason))
  {:error, :execution_failed}
```

Phase 8 should add the missing `reconcile_budget/4` call to the breaker-open branch while keeping breaker-open distinct from timeout/crash telemetry.

### `test/scoria/workflows/runtime_test.exs`

Combine the existing patterns:

- budget-trip tests already create a real policy and reservation path
- breaker-open tests already prove the second side effect is blocked

The new regression should assert both together: breaker-open blocks rerun *and* closes the durable reservation row.

### `test/scoria/mcp/executor_test.exs`

Combine the existing patterns:

- timeout/crash tests already assert `status == "reconciled"` and `metadata["outcome"]`
- breaker-open tests already assert breaker-open is distinct from timeout

The new regression should reuse the same reservation assertions for the breaker-open path.
