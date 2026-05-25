# Project Research - Stack

**Milestone:** `v2.1 Tenant-scoped semantic fast path`
**Date:** 2026-05-25
**Question:** What stack additions or changes are needed to add a tenant-scoped semantic fast path to Scoria without weakening provenance, privacy, or operator trust?

## Existing Scoria Assets To Reuse

- `pgvector` is already a first-class dependency in [mix.exs](/Users/jon/projects/scoria/mix.exs:47).
- `Scoria.Knowledge` already persists retrieval runs, retrieval results, citations, and grounding scores in durable Ecto-backed tables via [lib/scoria/knowledge.ex](/Users/jon/projects/scoria/lib/scoria/knowledge.ex:101).
- The current pgvector backend already supports cosine-distance search and filter maps, but only filters by `source_id` today in [lib/scoria/knowledge/backends/pgvector.ex](/Users/jon/projects/scoria/lib/scoria/knowledge/backends/pgvector.ex:18).
- Scoria already has durable tenant / actor / session identity and operator-facing runtime detail surfaces via [lib/scoria/runtime/params.ex](/Users/jon/projects/scoria/lib/scoria/runtime/params.ex:12), [lib/scoria/runtime/run_detail.ex](/Users/jon/projects/scoria/lib/scoria/runtime/run_detail.ex:38), and the dashboard LiveViews under `lib/scoria_web/live/`.

## Recommended Additions

### 1. New semantic cache persistence schema

Add a dedicated Ecto-backed cache store rather than overloading retrieval tables.

Recommended fields:

- `tenant_id` - required cache partition key
- `actor_id` - optional stricter partition for personalized-safe lanes
- `policy_key`
- `prompt_ref`
- `prompt_version`
- `provider`
- `model`
- `query_text`
- `query_embedding`
- `answer_payload`
- `evidence_refs`
- `source_fingerprint`
- `eligibility_reason`
- `cache_status` (`eligible`, `rejected`, `hit`, `stale`, `invalidated`)
- `expires_at`
- `invalidated_at`
- `last_hit_at`
- `hit_count`
- `metadata`

Use a dedicated table so cache lifecycle and operator evidence stay explicit instead of being inferred from general retrieval rows.

### 2. pgvector-backed lookup, exact-first default

Use pgvector for semantic lookup, but start with exact nearest-neighbor semantics before approximate ANN defaults.

Rationale:

- pgvector defaults to exact nearest-neighbor search, which preserves recall and is safer for a trust-sensitive first release.
- Approximate HNSW / IVFFlat can be added later for scale once the admissibility and invalidation story is proven.
- If the cache is always filtered by tenant and often by actor/policy/prompt version, correctness mistakes from approximate scans would be harder to diagnose.

### 3. Strong filter keys alongside vector similarity

The cache read path should filter on:

- `tenant_id` always
- `actor_id` when the answer was marked personalized or actor-scoped
- `policy_key`
- `prompt_ref` / `prompt_version`
- model family or runtime profile when output compatibility matters
- non-invalidated / non-expired rows only

This follows pgvector guidance: filter columns still matter even when you have a vector index, and approximate scans with `WHERE` clauses can miss matches unless you tune scanning aggressively.

### 4. Provenance and invalidation helpers

Add helper modules rather than embedding cache logic directly into `Scoria.Knowledge`:

- `Scoria.SemanticCache`
- `Scoria.SemanticCache.Entry`
- `Scoria.SemanticCache.Lookup`
- `Scoria.SemanticCache.Invalidation`
- `Scoria.SemanticCache.Eligibility`

This keeps retrieval grounding and semantic answer reuse adjacent but not collapsed into one abstraction.

### 5. Operator UI integration via existing async LiveView patterns

Use the current operator-surface patterns:

- async load sections with `assign_async/3`
- runtime / workflow DTO-driven rendering
- explicit notices, hit/miss reasons, and invalidation provenance

Do not add a hidden middleware-only cache with no operator evidence lane.

## What Not To Add In This Milestone

- No Redis-first or external cache tier as the default truth store
- No provider prompt-cache coupling as the product primitive
- No global cross-tenant cache
- No silent caching for tool-backed or personalized responses
- No ANN-only path that trades recall for speed before visibility and invalidation are proven

## External References

- pgvector official docs: https://github.com/pgvector/pgvector
- PostgreSQL row security policies: https://www.postgresql.org/docs/current/ddl-rowsecurity.html
- OpenAI prompt caching: https://platform.openai.com/docs/guides/prompt-caching
- Phoenix LiveView async assigns: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#assign_async/3
