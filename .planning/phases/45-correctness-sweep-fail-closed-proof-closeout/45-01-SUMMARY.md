---
phase: 45-correctness-sweep-fail-closed-proof-closeout
plan: 01
subsystem: knowledge
tags: [pgvector, cosine, retrieval, tenant-scope]
requires:
  - phase: 43-knowledge-tenant-isolation
    provides: tenant-scoped knowledge retrieval and persistence
provides:
  - DB-projected pgvector cosine similarity scores
  - Nil-embedding exclusion before retrieval ranking
  - Persisted `Knowledge.retrieve/2` score proof
affects: [knowledge, retrieval, pgvector, phase-45]
tech-stack:
  added: []
  patterns: [project score from DB metric used for ranking]
key-files:
  created: []
  modified:
    - lib/scoria/knowledge/backends/pgvector.ex
    - test/scoria/knowledge/pgvector_test.exs
    - test/scoria/knowledge/retrieval_test.exs
key-decisions:
  - "Use `1.0 - cosine_distance` projected from PostgreSQL/pgvector instead of recomputing a private score."
  - "Exclude nil embeddings before ranking instead of returning fabricated zero evidence."
patterns-established:
  - "Retrieval score evidence must come from the same database expression used for ranking."
requirements-completed: [FIX-01]
duration: 1h
completed: 2026-07-07
status: complete
---

# Phase 45-01: Pgvector Cosine Score Summary

**Pgvector retrieval now persists DB-projected raw cosine similarity instead of component-sum score evidence.**

## Performance

- **Duration:** 1h
- **Started:** 2026-07-07
- **Completed:** 2026-07-07
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Replaced the private component-sum `score_chunk` path with a DB projection of `1.0 - cosine_distance(chunk.embedding, ^query_vector)`.
- Preserved Phase 43 tenant visibility by applying `Scope.visible_to(scope)` before source filtering, nil-embedding filtering, ordering, and limiting.
- Added direct backend and `Knowledge.retrieve/2` persistence tests for exact, orthogonal, nil embedding, dimension mismatch, and persisted score behavior.

## Task Commits

1. **Pgvector cosine retrieval scores** - `b36953d5` (`fix`)

## Files Created/Modified

- `lib/scoria/knowledge/backends/pgvector.ex` - Projects cosine score from the pgvector query and excludes nil embeddings.
- `test/scoria/knowledge/pgvector_test.exs` - Direct backend proof for cosine scoring, nil exclusion, and loud dimension mismatch.
- `test/scoria/knowledge/retrieval_test.exs` - Persisted retrieval-result score proof through `Knowledge.retrieve/2`.

## Decisions Made

The score is raw cosine similarity, not probability or confidence. It is not clamped, rounded, or normalized beyond the pgvector `1.0 - cosine_distance` expression.

## Deviations from Plan

The plan's direct `MIX_ENV=test mix test --include knowledge ...` command was not the canonical knowledge harness in this repo and failed before tests because knowledge migrations were not applied. Verification used `MIX_ENV=test mix test.knowledge ... --warnings-as-errors`, matching the repository's knowledge lane.

## Issues Encountered

None beyond the command-lane adjustment above.

## Verification

- `MIX_ENV=test mix test.knowledge test/scoria/knowledge/pgvector_test.exs test/scoria/knowledge/retrieval_test.exs --warnings-as-errors` - PASS, 13 tests, 0 failures.

## User Setup Required

None.

## Next Phase Readiness

FIX-01 is ready for final closeout proof and source-scan prohibition checks.

---
*Phase: 45-correctness-sweep-fail-closed-proof-closeout*
*Completed: 2026-07-07*
