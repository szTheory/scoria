---
phase: 28
plan: 01
subsystem: "Runtime"
tags: ["compaction", "schema", "pgvector"]
requires: []
provides: ["Scoria.Runtime.CompactedMemory", "ai_compacted_memories", "ai_workflow_events.compacted_at"]
affects: ["Scoria.Workflows.Event", "Scoria.Runtime"]
tech-stack:
  added: ["pgvector"]
  patterns: ["Ecto Schema", "Core Migration"]
key-files:
  created:
    - "lib/scoria/runtime/compacted_memory.ex"
    - "priv/repo/migrations/20260519010000_add_compacted_at_to_workflow_events.exs"
    - "priv/repo/migrations/20260519010100_create_ai_compacted_memories.exs"
    - "test/scoria/workflows/event_test.exs"
    - "test/scoria/runtime/compacted_memory_test.exs"
  modified:
    - "lib/scoria/workflows/event.ex"
decisions:
  - "Added `compacted_at` to workflow events rather than deleting raw history so compaction remains reversible and auditable."
  - "Introduced `Scoria.Runtime.CompactedMemory` as a core Ecto schema with pgvector-backed embeddings and run/session sequence metadata."
  - "Verified the new core migration lane against the repo's bundled pgvector Postgres instead of weakening the schema for non-pgvector environments."
metrics:
  tasks: 2
  files: 6
---

# Phase 28 Plan 01: Schema Foundation Summary

Implemented the storage layer for async session compaction.

## Work Completed
- Added `compacted_at` to `ai_workflow_events` and exposed it through `Scoria.Workflows.Event`.
- Created the `ai_compacted_memories` table plus the `Scoria.Runtime.CompactedMemory` schema.
- Added focused tests covering `compacted_at` casting and compacted-memory validation/insertion.

## Deviations from Plan
None. The plan executed as intended.

## Self-Check: PASSED
- Verified with `env MIX_BUILD_ROOT=.mix-build-pgvector SCORIA_DB_HOST=localhost SCORIA_DB_PORT=55432 SCORIA_DB_USERNAME=postgres SCORIA_DB_PASSWORD=postgres mix test test/scoria/workflows/event_test.exs test/scoria/runtime/compacted_memory_test.exs`.
