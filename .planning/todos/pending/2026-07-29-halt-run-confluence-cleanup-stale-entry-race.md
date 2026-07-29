---
created: 2026-07-29T00:00:00Z
title: halt_run/3's D-52 confluence approval cleanup is unguarded against StaleEntryError
area: correctness
files:
  - lib/scoria/workflows.ex
---

## Problem

Surfaced as finding **CR-01** in `.planning/phases/57-confluence-escalation-gate/57-REVIEW.md`
(phase 57 code-review gate, 2026-07-29). Not a regression from plans 57-11/57-12 —
the code was introduced earlier in phase 57 by the D-52 work.

`resolve_pending_confluence_approvals/1` is called from `halt_run/3`
(`lib/scoria/workflows.ex:672`, 681-683, 698-708) **post-commit**, with no
`try/rescue` of its own — unlike its sibling post-commit calls
(`emit_rail_tripped/3`, `maybe_emit_rail_observed/1`), which are each
individually wrapped.

Failure interleaving: a reviewer decides a confluence approval at the same
moment a sibling step trips a rail. `approve/3`'s optimistic-locked update
raises `Ecto.StaleEntryError`, which `halt_run/3`'s lone function-level
`rescue _e in Ecto.StaleEntryError -> {:error, :already_halted}` then
mis-catches — reporting a halt that **already succeeded** (broadcasts and
telemetry have fired) as `{:error, :already_halted}`. Any other exception type
isn't caught at all and crashes the calling process; none of `halt_run/3`'s
three call sites wrap it.

The codebase already treats this exact race class carefully elsewhere —
`mark_confluence_waiting_for_approval/3` (D-28) — but not here. No test
exercises the interleaving.

## Solution

Wrap the `resolve_pending_confluence_approvals/1` post-commit call in its own
`try/rescue` the way `emit_rail_tripped/3` and `maybe_emit_rail_observed/1`
already are, so a cleanup failure cannot rewrite an already-successful halt's
return value or escape to the caller. Add a regression test driving the
concurrent decide-vs-rail-trip interleaving, mirroring the D-28 approach in
`mark_confluence_waiting_for_approval/3`.

## Notes

- Deferred out of the phase 57 gap-closure run to keep that lane scoped to the
  reviewer-evidence gap (orchestrator decision, user-approved 2026-07-29).
- Advisory finding: the code-review gate is non-blocking and no test currently
  fails because of it.
- Related lower-severity findings in the same review, both currently inert but
  worth folding into the same pass:
  - **WR-01** `lib/scoria_web/live/approvals_live/index.ex:161-163, 780-795` —
    `approve_run_scoped` has no server-side confluence-kind check before
    granting `confluence_scope: "run_tool"`; enforcement is UI-only.
  - **WR-02** `lib/scoria/mcp/executor.ex:601-659` — `evaluate_confluence/5`
    branches on `combination` rather than `decision`; a two-leg `declared`-grade
    combination resolves to `"escalate"` internally but reports `"allow"`.
    Likely correct by design, but nothing pins it.
