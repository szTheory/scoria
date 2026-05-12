# Phase 06 Plan 05: Trace-First Evidence Projection Summary

## Summary
Projected retrieval evidence and grounding signals into the existing operator surface instead of creating a second RAG UI. The orchestrator LiveView now exposes async evidence loading, replay/promote affordances, and a side-by-side citation/evidence component through the existing dashboard route and install path.

## Delivered
- Added `ScoriaWeb.CitationEvidenceComponent` for side-by-side citation, ranked chunk, freshness, and unsupported-claim presentation.
- Extended `ScoriaWeb.OrchestratorLive` with async evidence loading and `replay_retrieval` / `promote_retrieval` actions.
- Kept route and installer changes additive through the existing `scoria_dashboard` surface.
- Added UI and install coverage in `test/scoria_web/live/orchestrator_live_test.exs`, `test/scoria_web/router_test.exs`, and `test/mix/tasks/scoria.install_test.exs`.

## Verification
- `env SCORIA_DB_HOST=localhost SCORIA_DB_PORT=55432 SCORIA_DB_USERNAME=postgres SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_test.exs test/scoria_web/router_test.exs test/mix/tasks/scoria.install_test.exs`

## Notes
- Evidence is loaded on demand with `assign_async/3` to avoid turning long chunk bodies into permanent socket-state bloat.
