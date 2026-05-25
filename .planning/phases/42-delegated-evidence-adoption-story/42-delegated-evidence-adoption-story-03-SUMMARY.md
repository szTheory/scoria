---
phase: 42-delegated-evidence-adoption-story
plan: 03
requirements-completed: [ADPT-01, EVID-01]
completed: 2026-05-24
---

# Plan 42-03 Summary

## Completed

- Reordered the public adoption story back to the canonical `identity -> start -> inspect -> resume` flow in `README.md`.
- Aligned the Phoenix runtime example and bounded handoff guide to the curated delegated evidence surfaces: `Scoria.get_run_detail/1`, `detail.delegated_handoffs`, and `/scoria/workflows/:run_id`.
- Added a phase-local `42-GAP-LEDGER.md` that explicitly records the closeout decision: no remaining adopter-facing gap is required for the current bounded handoff lane, while richer delegated forensics remain deferred follow-up work.
- Extended doc/source guard tests so the runtime-first ordering, delegated-evidence wording, and gap/defer language are now checked support truth.

## Verification

- `mix test test/scoria/adoption_surface_test.exs test/scoria/handoff_example_source_test.exs`

## Notes

- `README.md` already contained local user edits in the bounded-handoff area, so the phase changes preserved those updates while restoring the intended runtime-first ordering.
