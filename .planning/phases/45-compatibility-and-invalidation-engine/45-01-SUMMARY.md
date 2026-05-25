---
phase: 45-compatibility-and-invalidation-engine
plan: 01
subsystem: semantic-cache
tags: [semantic-cache, pgvector, compatibility, lookup, testing]
requires:
  - phase: 45-00
    provides: verification lane assessment
provides:
  - Compatibility-aware semantic-cache schema
  - Exact-first semantic lookup with reason-coded rejects
  - Lookup-focused cache tests
affects: [semantic-cache, runtime, phase-46]
tech-stack:
  added: []
  patterns: [exact-first-lookup, policy-fingerprint, source-fingerprint, explicit-rejects]
key-files:
  created:
    - lib/scoria/semantic_cache/compatibility.ex
    - lib/scoria/semantic_cache/lookup.ex
    - priv/repo/migrations/20260525090000_add_semantic_cache_compatibility_fields.exs
    - test/scoria/semantic_cache/lookup_test.exs
  modified:
    - lib/scoria/semantic_cache.ex
    - lib/scoria/semantic_cache/entry.ex
    - test/scoria/semantic_cache_test.exs
key-decisions:
  - "Compatibility truth now fences reuse on prompt version, policy fingerprint, source fingerprint, scope, and persisted lifecycle state."
  - "Semantic fallback only runs after tenant/lane/scope partitioning, and stale or invalidated rows return explicit rejects instead of disappearing into `:miss`."
patterns-established:
  - "Pure compatibility helpers compute stable fingerprints and reject codes."
  - "Lookup returns `{:hit, entry}`, `{:reject, reason_code, entry}`, `:miss`, or `{:bypass, reason_code}`."
requirements-completed: [LOOK-01, INVD-02]
duration: session
completed: 2026-05-25
---

# Phase 45-01 Summary

**Compatibility-aware lookup foundation with vector-backed storage and reason-coded rejects**

## Accomplishments

- Added the Phase 45 schema upgrade for `policy_fingerprint`, `state_reason_code`, and `vector(3)` query embeddings.
- Split semantic-cache behavior into dedicated `Compatibility` and `Lookup` modules while keeping `Scoria.SemanticCache` as the public facade.
- Implemented exact-text-first lookup plus compatibility-checked semantic fallback with explicit `policy_mismatch`, `source_fingerprint_mismatch`, `entry_stale`, and `entry_invalidated` rejects.
- Added targeted lookup tests covering exact-hit priority, semantic fallback, malformed direct-caller bypass, and persisted stale/invalidated truth.

## Deviations from Plan

- The migration had to use an explicit `ALTER COLUMN ... USING NULL` conversion because PostgreSQL could not auto-cast the old `bytea` embedding column to `vector(3)`.

## Verification

- `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria/semantic_cache_test.exs test/scoria/semantic_cache/lookup_test.exs`

## Next Phase Readiness

Runtime wiring can now consume explicit hit/reject/miss outcomes instead of inferring compatibility from old exact-match behavior.
