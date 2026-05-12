# Phase 06 Plan 04: Grounding Evaluation Ladder Summary

## Summary
Implemented the deterministic-first grounding ladder for Phase 6, with versioned judge review appended as an optional second layer. Citation presence, citation validity, unsupported claims, and retrieval hit/rank checks now persist explicit score records before any softer semantic review.

## Delivered
- Added `Scoria.Knowledge.Grounding` deterministic scoring functions for citation integrity and retrieval metrics.
- Extended `Scoria.Knowledge.score_grounding/2` to persist deterministic results first and append optional judge review.
- Persisted rubric version, prompt version, model, reasoning, and evidence refs on `GroundingScore`.
- Added grounding-focused tests in `test/scoria/knowledge/grounding_test.exs`.

## Verification
- `env SCORIA_DB_HOST=localhost SCORIA_DB_PORT=55432 SCORIA_DB_USERNAME=postgres SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria/knowledge/grounding_test.exs`

## Notes
- Judge review does not replace deterministic failures; it is appended after them for reproducible auditability.
