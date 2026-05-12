# Phase 06 Plan 02: Retrieval Backend Boundary Summary

## Summary
Built the retrieval-engine seam for Phase 6 with pgvector as the boring default and Scrypath kept behind a normalization boundary. Chunking, embedding, and retrieval backend responsibilities are now explicit and option-driven instead of hard-coded into one path.

## Delivered
- Added `Scoria.Knowledge.Chunker` and `Scoria.Knowledge.Embedder` behaviors with conservative deterministic defaults.
- Added `Scoria.Knowledge.Backends.Pgvector` for embedding persistence, similarity lookup, and source reindex cleanup.
- Added `Scoria.Knowledge.Retrievers.Scrypath` as an optional adapter that only accepts Scoria-owned provenance.
- Added backend-focused tests in `test/scoria/knowledge/pgvector_test.exs` and `test/scoria/knowledge/scrypath_test.exs`.

## Verification
- `env SCORIA_DB_HOST=localhost SCORIA_DB_PORT=55432 SCORIA_DB_USERNAME=postgres SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria/knowledge/pgvector_test.exs test/scoria/knowledge/scrypath_test.exs`

## Notes
- pgvector remains the default retrieval backend, but the public `Scoria.Knowledge` API accepts `chunker:`, `embedder:`, `backend:`, and retriever options explicitly.
