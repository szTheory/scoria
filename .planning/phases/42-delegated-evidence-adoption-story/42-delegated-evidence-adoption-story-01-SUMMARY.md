---
phase: 42-delegated-evidence-adoption-story
plan: 01
requirements-completed: [EVID-01]
completed: 2026-05-24
---

# Plan 42-01 Summary

## Completed

- Added `delegated_handoffs` to `Scoria.Runtime.RunDetail` as the primary curated delegated evidence projection.
- Encoded explicit precedence inside the runtime DTO by linking each handoff to its parent handoff step and same-run delegated child step when present.
- Surfaced explicit `child_step_pending` status plus deterministic sequence ordering for multi-handoff runs.
- Preserved raw `handoffs` and `steps` arrays as secondary evidence.
- Extended runtime tests to cover delegated projection shape, empty non-handoff runs, and pending child lineage behavior.

## Verification

- `mix test test/scoria/runtime_test.exs test/scoria/runtime_view_test.exs`

## Notes

- Projected context in the delegated projection is read back from the delegated child step, not reconstructed from `handoff_input`.
- `capability_tags` remain secondary metadata on the curated delegated object rather than replacing lineage/status facts.
