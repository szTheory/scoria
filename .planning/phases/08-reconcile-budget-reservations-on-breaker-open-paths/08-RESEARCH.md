# Phase 8: Reconcile Budget Reservations on Breaker-Open Paths - Research

**Researched:** 2026-05-12
**Domain:** Breaker-open reservation reconciliation across workflow and MCP execution seams
**Confidence:** High

<phase_scope>
## Phase Goal

Close the Phase 7 gap where Scoria reserves budget before an external effect, then exits early on an open breaker without reconciling the durable reservation row.

This phase is intentionally narrow. It is not a general budget-engine rewrite, a telemetry phase, or an approval/audit repair phase. Its job is to make the `reserve -> breaker-open -> reconcile` path behave as durably and predictably as the existing success, timeout, and execution-failure paths.
</phase_scope>

<requirements>
## Requirement Focus

| ID | Requirement | Phase 8 interpretation |
|----|-------------|------------------------|
| SRE-01 | Reservation reconciliation is incomplete on breaker-open exits. | Breaker-open paths must leave no reservation stuck in `reserved` state. |
| SRE-02 | The reserve -> breaker-open -> reconcile loop is incomplete. | Both workflow runtime and MCP executor must reconcile the row created during preflight before returning/failing. |
| SRE-03 | Breaker-open exits do not reliably close reservation state. | Breaker-open outcomes need a consistent durable outcome marker and regression tests at both seams. |
</requirements>

<current_findings>
## Current Code Findings

### `lib/scoria/workflows/runtime.ex`

- `reserve_budget/3` creates a reservation before execution when budget controls apply.
- Success, approval wait, handoff, handler error, timeout, and execution failure paths all call `reconcile_budget/4`.
- The breaker-open branch:

```elixir
{:error, %{status: :breaker_open} = envelope} ->
  Workflows.fail_step(step.id, attach_budget_evidence(normalize_budget_envelope(envelope), reservation_context))
```

does **not** call `reconcile_budget/4` first, so a durable reservation can remain in `reserved` status after the step is failed.

### `lib/scoria/mcp/executor.ex`

- `reserve_budget/3` creates a reservation before tool execution when the context is budget-governed.
- Timeout and execution failure paths reconcile via `reconcile_budget/4`.
- The breaker-open branch:

```elixir
{:error, %{status: :breaker_open} = envelope} ->
  :telemetry.execute([:scoria, :tool, :failed], %{duration: 0}, Map.put(metadata, :reason, :breaker_open))
  {:error, envelope}
```

does **not** reconcile the reservation first, so durable reservation state can remain open even though the tool never ran.

### `lib/scoria/sre/budget_engine.ex`

- `BudgetEngine.reconcile_usage/2` already provides the correct durable seam for closing a reservation.
- The current reconciliation metadata only requires `actual_units` plus arbitrary metadata. That is enough to mark breaker-open exits as reconciled with `actual_units = 0` and an explicit outcome reason.

### Existing test surface

- `test/scoria/workflows/runtime_test.exs` already proves breaker-open handlers fail fast without rerunning the side effect, but it does not assert reservation cleanup.
- `test/scoria/mcp/executor_test.exs` already distinguishes breaker-open from timeout, but it does not assert breaker-open reservation reconciliation.
- `test/scoria/sre/budget_engine_test.exs` and `test/scoria/sre_test.exs` already prove the reconciliation API and durable reservation model exist, so Phase 8 should reuse those semantics rather than inventing a second closure path.
</current_findings>

<recommended_changes>
## Recommended Implementation Shape

### 1. Treat breaker-open as a first-class reconciliation outcome

Use the same durable closeout pattern already used for timeout and execution failure:

- call `BudgetEngine.reconcile_usage/2`
- set `actual_units` to `0`
- persist metadata with an explicit outcome such as `"breaker_open"`

This keeps the reservation history append-only and explainable: the system reserved budget, the breaker blocked the external effect, and the reservation was reconciled to zero actual usage.

### 2. Keep reconciliation at the execution seams

Do not move this logic into `BreakerRegistry` or into the underlying tool/handler modules.

- `Scoria.Workflows.Runtime` owns workflow-step failure semantics and already knows the reservation context.
- `Scoria.MCP.Executor` owns tool-call failure semantics and already knows the reservation context plus telemetry metadata.

The narrowest safe fix is to add the missing reconcile call in each breaker-open branch before the failure/return is finalized.

### 3. Preserve outcome parity across all terminal branches

The phase should make terminal outcomes symmetrical:

- `completed`
- `waiting_for_approval`
- `handoff`
- `handler_error`
- `timeout`
- `execution_failed`
- `breaker_open`

That symmetry matters more than the exact helper shape. If a small shared helper makes the branches clearer, use it. If not, keep the explicit branch-local reconcile call.
</recommended_changes>

<data_contracts>
## Durable Reservation Expectations

For breaker-open exits, the reservation row should end in:

- `status: "reconciled"`
- `actual_units: 0`
- `metadata["outcome"] == "breaker_open"`

Optional but useful additions:

- preserve the breaker key or reason code in metadata if the current context makes that cheap
- keep the existing `budget_reservation_id` evidence attached to the workflow failure envelope or MCP metadata

Avoid introducing a new reservation status such as `blocked` or `breaker_open`. The existing `reconciled` status already models "reserved estimate was closed against final actuals," and the outcome metadata captures why.
</data_contracts>

<testing_strategy>
## Test Strategy

### Workflow runtime

Add a regression test that:

1. creates an active budget policy
2. executes one failing external-effect step to open the breaker
3. executes a second step with budget context and the same breaker key
4. asserts:
   - the second step fails with `reason_code == "breaker_open"`
   - the side effect does not run
   - the reservation found by `trace_id` is `reconciled`
   - the reservation has `actual_units == 0`
   - the reservation metadata contains `outcome == "breaker_open"`

### MCP executor

Add a regression test that:

1. creates an active budget policy
2. opens the remote-MCP breaker with a crashing call
3. calls the same remote target again with budget context
4. asserts:
   - the second call returns breaker-open
   - the durable reservation row exists
   - the reservation is reconciled to zero actual units
   - metadata captures the breaker-open outcome

### Focused verification commands

- `MIX_ENV=test mix test test/scoria/workflows/runtime_test.exs`
- `MIX_ENV=test mix test test/scoria/mcp/executor_test.exs`
- `MIX_ENV=test mix test test/scoria/sre/budget_engine_test.exs test/scoria/sre_test.exs`

The SRE-focused suite remains relevant because Phase 8 must preserve the reservation contract already established by the SRE context.
</testing_strategy>

<risks>
## Risks and Pitfalls

- Do not reconcile before the reservation exists. The fix must only run when `reservation_context` contains a real reservation.
- Do not regress the policy-sensitive audit-only path in `MCP.Executor`, where `execution_context` can contain `audit_outbox_event` without a reservation.
- Do not classify breaker-open as timeout or execution failure. The outcome needs its own metadata so later telemetry and incidenting phases can distinguish policy block from runtime crash.
- Do not expand the phase into telemetry wiring or incident delivery. Those are Phase 9 and Phase 10 concerns.
</risks>

<recommended_plan_shape>
## Recommended Plan Breakdown

Three plans are enough:

1. Add shared reservation-closeout expectations and seam-local regression coverage.
2. Fix workflow runtime breaker-open reconciliation and evidence.
3. Fix MCP executor breaker-open reconciliation and verify parity with the workflow path.

The plans should keep the write set tight around:

- `lib/scoria/workflows/runtime.ex`
- `lib/scoria/mcp/executor.ex`
- `test/scoria/workflows/runtime_test.exs`
- `test/scoria/mcp/executor_test.exs`

Optional shared touch:

- `lib/scoria/sre/budget_engine.ex` only if a tiny helper improves clarity without widening scope.
</recommended_plan_shape>

## RESEARCH COMPLETE
