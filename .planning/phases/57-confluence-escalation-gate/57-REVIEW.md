---
phase: 57-confluence-escalation-gate
reviewed: 2026-07-29T00:00:00Z
depth: standard
files_reviewed: 33
files_reviewed_list:
  - lib/scoria/adopter_doc_contract.ex
  - lib/scoria/confluence.ex
  - lib/scoria/confluence/evidence.ex
  - lib/scoria/mcp/executor.ex
  - lib/scoria/observe/approval.ex
  - lib/scoria/observe/semconv.ex
  - lib/scoria/runtime/params.ex
  - lib/scoria/trust/scan.ex
  - lib/scoria/trust/verdict.ex
  - lib/scoria/workflows.ex
  - lib/scoria/workflows/remote_approval_projection.ex
  - lib/scoria/workflows/run.ex
  - lib/scoria/workflows/runtime.ex
  - lib/scoria_web/approval_copy.ex
  - lib/scoria_web/live/approvals_live/index.ex
  - priv/repo/migrations/20260728140000_add_confluence_columns.exs
  - guides/scoria-vs-external-llm-ops.md
  - test/scoria/confluence_test.exs
  - test/scoria/confluence_audit_test.exs
  - test/scoria/confluence_concurrency_test.exs
  - test/scoria/confluence_reviewer_evidence_test.exs
  - test/scoria/mcp/executor_confluence_test.exs
  - test/scoria/workflows/remote_approval_projection_test.exs
  - test/scoria_web/approval_copy_test.exs
  - test/scoria_web/live/approvals_live_test.exs
  - test/scoria/adoption_surface_test.exs
  - test/scoria/connectors/invocation_test.exs
  - test/scoria/mcp/executor_test.exs
  - test/scoria/observe/approval_test.exs
  - test/scoria/observe/semconv_test.exs
  - test/scoria/trust/verdict_test.exs
  - test/scoria/workflows/approval_write_invariant_guard_test.exs
  - test/scoria/workflows/run_test.exs
  - test/scoria/workflows/runtime_span_test.exs
  - test/scoria/workflows_test.exs
findings:
  critical: 1
  warning: 2
  info: 0
  total: 3
status: issues_found
---

# Phase 57: Code Review Report

**Reviewed:** 2026-07-29T00:00:00Z
**Depth:** standard
**Files Reviewed:** 33
**Status:** issues_found

## Summary

Reviewed the full Confluence Escalation Gate surface: the pure classifier
(`Scoria.Confluence`/`Evidence`), the executor's gate/accumulator/audit wiring
(`Scoria.MCP.Executor`), the workflow lifecycle additions (halt-with-pending-
approval, retry guard, resume widening in `Scoria.Workflows`/`Run`/`Runtime`),
the new reviewer-facing evidence projection (`RemoteApprovalProjection`,
`ApprovalCopy`, `ApprovalsLive.Index`), the migration, and the adoption-surface
doc/test contract.

The security invariant the phase context called out most explicitly — that
`RemoteApprovalProjection.confluence_evidence_fields/2` must scope the
`blocker_audit_outbox_event_id` back-link lookup by both `event_type` and the
approval's own `workflow_run_id`, must never call `String.to_atom/1` or
`String.to_existing_atom/1` on persisted JSON leg-source strings, must never
fabricate evidence for an unreadable back-link, and must batch the audit read
once per page — is implemented correctly and is exercised by direct tests
(cross-run pointer resolves to nil, unknown-source string resolves to
`:unknown`, single-query batch load proven via telemetry counting). No defect
was found in that specific code path.

Two real defects were found elsewhere in the same phase's surface: an
exception-safety gap in the new `halt_run/3` D-52 cleanup that can misreport
a successful halt as a failure (or crash the caller) under a race that this
codebase otherwise handles carefully everywhere else it appears, and a missing
server-side authorization check on the new bounded run-scoped approve action
that relies entirely on client-side UI gating.

## Critical Issues

### CR-01: `halt_run/3`'s D-52 pending-confluence-approval cleanup is not exception-safe and can misreport a successful halt or crash the caller

**File:** `lib/scoria/workflows.ex:672` (call site), `lib/scoria/workflows.ex:681-683` (the function-level rescue that unintentionally also covers this call), `lib/scoria/workflows.ex:698-708` (`resolve_pending_confluence_approvals/1`)

**Issue:**

```elixir
def halt_run(run_id, step_id, envelope) do
  ...
  Repo.transaction(fn repo -> ... end)
  |> case do
    {:ok, {run, audit_outbox_event}} ->
      broadcast(run.id, {:workflow_updated, run.id})
      emit_rail_tripped(run, audit_outbox_event, envelope)
      maybe_emit_rail_observed(run)
      resolve_pending_confluence_approvals(run)   # <-- new, D-52
      {:ok, run}
    ...
  end
rescue
  _e in Ecto.StaleEntryError -> {:error, :already_halted}
end
```

```elixir
defp resolve_pending_confluence_approvals(%Run{} = run) do
  Approval
  |> where([a], a.workflow_run_id == ^run.id and a.status == "pending" and a.blocker_kind == "confluence")
  |> Repo.all()
  |> Enum.each(fn approval ->
    approve(approval.id, "expired", %{reason: "run halted"})
  end)
end
```

This is called **after** the halt transaction has already committed and after
`broadcast/2`, `emit_rail_tripped/3`, and `maybe_emit_rail_observed/1` have
already fired. Unlike those three sibling post-commit calls — which are each
individually wrapped in their own `try/rescue -> :ok` (see
`emit_rail_tripped/3` and `maybe_emit_rail_observed/1` immediately above it in
this same file) — `resolve_pending_confluence_approvals/1` has no defensive
wrapper of its own.

It calls `approve/3` for every pending confluence approval on the run.
`approve/3`'s own transaction reads the approval row and later calls
`Approval.changeset(update_attrs) |> repo.update!()`, and `Observe.Approval`'s
schema uses `optimistic_lock(:lock_version)`. If a genuinely concurrent write
to the **same** approval row lands between `resolve_pending_confluence_approvals/1`'s
`Repo.all()` read and that particular `approve/3` call's own internal update —
e.g. a reviewer clicks Approve/Deny in `ApprovalsLive.Index` at the same moment
a sibling step trips a rail and halts the run — `repo.update!/1` raises
`Ecto.StaleEntryError`. This is exactly the same class of race the phase
already treats seriously and handles explicitly elsewhere: compare
`mark_confluence_waiting_for_approval/3` in `lib/scoria/mcp/executor.ex:1127-1137`
(D-28), which wraps the identical `Workflows.mark_waiting_for_approval/3` call
in `rescue _e in Ecto.StaleEntryError -> ...` specifically because an uncaught
`StaleEntryError` here would otherwise crash an unlinked dispatch task.

Because `resolve_pending_confluence_approvals/1` runs inside `halt_run/3`'s own
function body, and `halt_run/3`'s **only** rescue clause is the narrowly-typed
`rescue _e in Ecto.StaleEntryError -> {:error, :already_halted}` around the
*entire* function, two bad outcomes are reachable:

1. If the raised exception is `Ecto.StaleEntryError` (the realistic case
   above), `halt_run/3` returns `{:error, :already_halted}` even though the
   halt **did** succeed and its broadcast/telemetry already fired. Any caller
   that trusts the documented `@spec` (`{:ok, Run.t()} | {:error, :already_halted} | ...`)
   is told the halt failed/was a no-op when it was not.
2. If the underlying failure inside `approve/3` raises anything **other**
   than `Ecto.StaleEntryError` (e.g. a changeset/constraint error surfaced by
   `SRE.insert_audit_outbox_event/2`'s `repo.rollback/1` propagating in an
   unexpected shape, or any future change to `approve/3`), the exception is
   not caught at all and propagates out of `halt_run/3` uncaught. None of
   `halt_run/3`'s three current call sites
   (`lib/scoria/connectors/invocation.ex:116`, `lib/scoria/workflows/runtime.ex:268,302`,
   `lib/scoria/mcp/executor.ex:229`) wrap that call in their own rescue, so
   this crashes the calling process (a rail-tripped tool-call dispatch or
   step-execution task).

No test exercises this interleaving — `test/scoria/workflows_test.exs`'s and
`test/scoria/confluence_concurrency_test.exs`'s D-52 tests only cover the
single-writer, no-race case.

**Fix:** wrap the D-52 cleanup the same way every other post-commit side
effect in this function already is, and make it tolerate a failed/aborted
resolution rather than let it affect `halt_run/3`'s own return value:

```elixir
defp resolve_pending_confluence_approvals(%Run{} = run) do
  Approval
  |> where([a], a.workflow_run_id == ^run.id and a.status == "pending" and a.blocker_kind == "confluence")
  |> Repo.all()
  |> Enum.each(fn approval ->
    try do
      approve(approval.id, "expired", %{reason: "run halted"})
    rescue
      _e in Ecto.StaleEntryError -> :ok
      other -> Logger.warning("D-52 confluence cleanup failed for approval #{approval.id}: #{inspect(other)}")
    end
  end)
end
```

## Warnings

### WR-01: `approve_run_scoped` LiveView event has no server-side check that the target approval is actually confluence-kind

**File:** `lib/scoria_web/live/approvals_live/index.ex:161-163` (handler), `lib/scoria_web/live/approvals_live/index.ex:780-793` (`maybe_set_confluence_scope/2`), `lib/scoria_web/live/approvals_live/index.ex:795` (`confluence_approval?/1`, defined but never called from the handler)

**Issue:** The D-50 bounded run-scoped approve action is gated **only** in
the template: the button is rendered with `:if={confluence_approval?(@active_approval)}`
(line ~317). The `handle_event("approve_run_scoped", _, socket)` callback
itself does not check `confluence_approval?(socket.assigns.active_approval)`
before calling `record_approval_decision(socket, "approved", confluence_scope: "run_tool")`,
and `maybe_set_confluence_scope/2` unconditionally writes
`confluence_scope: "run_tool"` via a raw `Repo.update_all` for whatever
approval is currently the active one:

```elixir
def handle_event("approve_run_scoped", _, socket) do
  {:noreply, record_approval_decision(socket, "approved", confluence_scope: "run_tool")}
end
```

A LiveView client can push any event name for the currently-mounted socket
regardless of what the server most recently rendered (e.g. via
`view |> render_click("approve_run_scoped", %{})` against a socket whose
`active_approval` is a non-confluence approval — exactly the shape
`test/scoria_web/live/approvals_live_test.exs`'s own "does not render for a
non-confluence approval" test proves is reachable, just without checking what
happens if the event is sent anyway). Today this is inert because
`Scoria.MCP.Executor.run_tool_scope_granted?/3` only ever queries for
`blocker_kind == "confluence"` rows, so setting `confluence_scope` on a
non-confluence approval has no downstream effect. But the invariant ("a
run-scoped grant only ever exists for a confluence approval") is currently
enforced in exactly one place — client-rendered markup — with no
server-side backstop, unlike every other confluence security invariant in
this phase (which are all enforced at the query/changeset layer, per the
phase's own `confluence_scope`/`consumed_at` LOAD-BEARING comments in
`Scoria.Observe.Approval`).

**Fix:** guard the handler itself, mirroring the template condition:

```elixir
def handle_event("approve_run_scoped", _, socket) do
  if confluence_approval?(socket.assigns.active_approval) do
    {:noreply, record_approval_decision(socket, "approved", confluence_scope: "run_tool")}
  else
    {:noreply, socket}
  end
end
```

### WR-02: `Confluence.grade/1`/`decide/2`-derived `decision` is discarded (as telemetry `"allow"`) for every non-`"exfiltration_path"` combination, with no test asserting this is intentional

**File:** `lib/scoria/mcp/executor.ex:601-659` (`evaluate_confluence/5`)

**Issue:** `Confluence.decide/2`'s shipped default enforces the `"declared"`
grade unconditionally (`config[:declared]` defaults to `:escalate`), and
`grade/1` computes a grade from whichever legs are lit regardless of how many
legs are lit. So a two-leg combination such as `"private_data_and_untrusted_content"`
with both legs `:declared` resolves `decision` to `"escalate"` inside
`evaluate_confluence/5`, exactly like a real `"exfiltration_path"` case would.
The `cond` in `evaluate_confluence/5`, however, only ever escalates or blocks
when `combination == "exfiltration_path"`; every other combination — including
one whose computed `decision` was `"escalate"` or `"block"` — falls through to
the `true ->` branch, which unconditionally emits the `:observed` telemetry
event with a hardcoded `"allow"` disposition, discarding the actual resolved
`decision` value entirely. This reading is consistent with the module's
"lethal trifecta requires all three legs" design intent (and is very likely
correct), but no test in `test/scoria/mcp/executor_confluence_test.exs` or
`test/scoria/confluence_audit_test.exs` exercises a two-leg, `"declared"`-grade
combination to confirm the gate genuinely never pauses on it and that the
telemetry's `"allow"` tag (rather than the computed `"escalate"`/`"block"`) is
the intended operator-facing signal for that case, so a future refactor that
starts branching on `decision` instead of `combination` (a very natural-looking
simplification given `confluence_decision/2` already exists) could silently
turn partial-leg combinations into blocking/escalating ones. Add a regression
test pinning the current (believed-correct) behavior.

---

_Reviewed: 2026-07-29T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
