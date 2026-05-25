# Phase 42 Gap Ledger

## Closeout Decision

There is no remaining adopter-facing gap required to ship the runtime-first bounded handoff lane for `v2.0 Relay` closeout.

## Why

- `Scoria.get_run_detail/1` now exposes a curated `delegated_handoffs` projection instead of forcing apps to reconstruct handoff lineage from raw workflow rows.
- `/scoria/workflows/:run_id` now includes a run-level `Delegated Evidence` section for the same durable run.
- README, the Phoenix runtime example, and the bounded handoff guide now teach bounded handoffs as an extension of the canonical `identity -> start -> inspect -> resume` path.

## Deferred Follow-Up

Richer notebook-style delegated forensics remain deferred follow-up work beyond this closeout. They should stay out of current milestone scope unless real operator confusion appears after the current DTO and workflow-page evidence surfaces are used in practice.
