# Phase 06 Plan 03: Retrieval Provenance and Citation Contract Summary

## Summary
Extended Phase 6 with durable retrieval logging and machine-readable citation anchors. Retrieval operations now persist ordered runs/results, and citations are validated against stored chunk identity and offsets instead of trusting rendered text.

## Delivered
- Extended `Scoria.Knowledge.retrieve/2` to persist one `RetrievalRun` plus ordered `RetrievalResult` rows with trace/span linkage.
- Added `Scoria.Knowledge.CitationFormatter` for anchor construction, inline rendering, and offset/digest validation.
- Kept trace-first provenance explicit through `trace_id` and `span_id` on retrieval and citation records.
- Added retrieval and citation contract tests in `test/scoria/knowledge/retrieval_test.exs` and `test/scoria/knowledge/citation_formatter_test.exs`.

## Verification
- `env SCORIA_DB_HOST=localhost SCORIA_DB_PORT=55432 SCORIA_DB_USERNAME=postgres SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria/knowledge/retrieval_test.exs test/scoria/knowledge/citation_formatter_test.exs`

## Notes
- Rendered citation text is treated as derived output; durable anchor maps remain the source of truth for provenance.
