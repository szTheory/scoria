# Phase 06 Plan 01: Durable Knowledge Foundation Summary

## Summary
Implemented the durable corpus, provenance, retrieval-run, and grounding-score foundation for Phase 6. Scoria now owns explicit Ecto nouns for sources, chunks, citations, retrieval runs/results, and grounding scores behind the public `Scoria.Knowledge` context.

## Delivered
- Added `priv/repo/migrations/20260511000300_create_knowledge_tables.exs` with additive knowledge, retrieval, citation, and grounding tables plus `vector` extension setup.
- Added `Scoria.Knowledge.Source`, `Chunk`, `Citation`, `RetrievalRun`, `RetrievalResult`, and `GroundingScore` schemas.
- Implemented `Scoria.Knowledge` lifecycle APIs for source creation, ingest, re-embed, re-index, retrieval persistence, and grounding-score persistence.
- Added knowledge context coverage in `test/scoria/knowledge_test.exs`.

## Verification
- `env SCORIA_DB_HOST=localhost SCORIA_DB_PORT=55432 SCORIA_DB_USERNAME=postgres SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria/knowledge_test.exs`

## Notes
- `Scoria.Knowledge` stays module/function-first and uses `Ecto.Multi` for multi-row persistence boundaries rather than introducing a DSL.
