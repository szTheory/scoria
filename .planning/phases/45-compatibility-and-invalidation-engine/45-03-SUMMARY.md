---
phase: 45-compatibility-and-invalidation-engine
plan: 03
subsystem: invalidation
tags: [semantic-cache, invalidation, stale-state, runtime, testing]
requires:
  - phase: 45-02
    provides: runtime reject/miss/hit truth
provides:
  - Transactional stale and invalidation helpers
  - Lookup-triggered stale/invalidation state changes
  - Dedicated invalidation coverage
affects: [semantic-cache, runtime, operator-truth, phase-46]
tech-stack:
  added: []
  patterns: [ecto-multi-invalidation, append-only-events, reason-coded-state]
key-files:
  created:
    - lib/scoria/semantic_cache/invalidation.ex
    - test/scoria/semantic_cache/invalidation_test.exs
  modified:
    - lib/scoria/semantic_cache.ex
    - lib/scoria/workflows/runtime.ex
    - test/scoria/runtime/semantic_fast_path_test.exs
key-decisions:
  - "Age-based decay is persisted as `stale/freshness_window_elapsed`, while prompt/policy/source drift becomes `invalidated` with stable reason codes."
  - "Lookup-triggered rejects mutate durable state before the runtime falls through to live execution."
patterns-established:
  - "Bulk invalidation stays scoped by tenant and lane compatibility slices."
  - "Entry lifecycle remains append-only through paired invalidation events."
requirements-completed: [INVD-01, INVD-02]
duration: session
completed: 2026-05-25
---

# Phase 45-03 Summary

**Explicit stale and invalidation engine with durable runtime fallthrough semantics**

## Accomplishments

- Added transactional `mark_stale/3`, `invalidate_entry/3`, `invalidate_by_prompt/1`, `invalidate_by_policy/1`, `invalidate_by_source/1`, and `revoke_entry/2` helpers under `Scoria.SemanticCache`.
- Wired runtime reject handling so stale candidates become `stale` and prompt/policy/source mismatches become `invalidated` before live execution continues.
- Added dedicated invalidation coverage for per-entry transitions, tenant/lane-scoped bulk invalidation, and runtime stale/invalidation fallthrough behavior.

## Verification

- `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria/semantic_cache/invalidation_test.exs test/scoria/runtime/semantic_fast_path_test.exs`

## Issues Encountered

- The bulk invalidation helper originally returned raw `Repo.update_all/3` results from an `Ecto.Multi.run/3` callback; the transaction now wraps that result in `{:ok, ...}` so invalidation remains atomic and executable.

## Next Phase Readiness

Phase 46 can project explicit stale versus invalidated operator truth without redefining the underlying lifecycle model.
