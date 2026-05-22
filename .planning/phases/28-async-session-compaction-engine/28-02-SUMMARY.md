---
phase: 28
plan: 02
subsystem: "Workflows"
tags: ["compaction", "oban", "req-llm"]
requires: ["28-01"]
provides: ["Scoria.Workflows.EventCompactor", "Scoria.Compaction.SummarizeWorker", "Scoria.Compaction.Tokenizer"]
affects: ["Scoria.Workflows", "Oban"]
tech-stack:
  added: []
  patterns: ["Oban Worker", "Injected LLM Adapter", "Async Trigger"]
key-files:
  created:
    - "lib/scoria/compaction/tokenizer.ex"
    - "lib/scoria/workflows/event_compactor.ex"
    - "lib/scoria/compaction/summarize_worker.ex"
    - "test/scoria/workflows/event_compactor_test.exs"
    - "test/scoria/compaction/summarize_worker_test.exs"
  modified:
    - "config/config.exs"
    - "lib/scoria/workflows.ex"
decisions:
  - "Kept compaction enqueueing on the event-write seam so event producers stay synchronous while summarization remains async."
  - "Used Oban unique jobs keyed by `run_id` to debounce repeated enqueue attempts for hot sessions."
  - "Injected ReqLLM text and embedding modules through app env in tests so compaction can be verified deterministically without live model calls."
metrics:
  tasks: 2
  files: 7
---

# Phase 28 Plan 02: Async Compaction Summary

Implemented token-based enqueueing and the asynchronous summarization worker for workflow event history.

## Work Completed
- Added `Scoria.Compaction.Tokenizer` and `Scoria.Workflows.EventCompactor` to measure uncompacted history and queue compaction jobs.
- Wired `Scoria.Workflows.insert_event/4` to opportunistically enqueue `Scoria.Compaction.SummarizeWorker`.
- Added `SummarizeWorker` to summarize uncompacted events, persist a `CompactedMemory`, create an embedding, and stamp `compacted_at` on the source events.
- Added focused Oban-backed tests covering threshold enqueueing, uniqueness debouncing, and the full worker persistence path.

## Deviations from Plan
None. The plan executed as intended.

## Self-Check: PASSED
- Verified with `env MIX_BUILD_ROOT=.mix-build-pgvector SCORIA_DB_HOST=localhost SCORIA_DB_PORT=55432 SCORIA_DB_USERNAME=postgres SCORIA_DB_PASSWORD=postgres mix test test/scoria/workflows/event_compactor_test.exs test/scoria/compaction/summarize_worker_test.exs`.
