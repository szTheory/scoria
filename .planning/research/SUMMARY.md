# Project Research Summary

**Milestone:** `v2.1 Tenant-scoped semantic fast path`
**Date:** 2026-05-25

## Recommendation

Build the semantic fast path as a Scoria-owned, Ecto-backed, tenant-partitioned semantic cache that compounds the existing retrieval, runtime identity, and operator-evidence surfaces.

Do not frame `v2.1` around provider prompt caching or a generic invisible middleware cache.

## Stack Additions

- add a dedicated semantic cache schema and service layer
- reuse `pgvector` for query similarity
- start exact-first or conservatively indexed
- carry prompt / policy / source compatibility into the lookup key
- project cache evidence into the existing LiveView operator surfaces

## Feature Table Stakes

- tenant-scoped cache reuse
- eligibility rules for safe read-only work
- prompt/version/source-aware invalidation
- explicit hit / miss / stale / rejected outcomes
- operator-visible diagnostics and provenance

## Watch Out For

- cross-tenant leaks
- false-positive semantic hits
- confusing provider prompt caching with application answer reuse
- ANN tuning before trust instrumentation
- invalidation that ignores prompt or source evolution

## Architecture Direction

Keep the capability inside the embedded Scoria boundary:

- `core`: semantic cache persistence, eligibility, lookup, invalidation, evidence projection
- `defer`: external cache backends, aggressive ANN tuning, broad analytics surfaces

## Suggested Requirement Categories

1. Eligibility and partitioning
2. Lookup and compatibility
3. Invalidation and freshness
4. Operator evidence and diagnostics

## Sources

- STACK: `.planning/research/STACK.md`
- FEATURES: `.planning/research/FEATURES.md`
- ARCHITECTURE: `.planning/research/ARCHITECTURE.md`
- PITFALLS: `.planning/research/PITFALLS.md`
- pgvector official docs: https://github.com/pgvector/pgvector
- PostgreSQL row security policies: https://www.postgresql.org/docs/current/ddl-rowsecurity.html
- PostgreSQL `CREATE POLICY`: https://www.postgresql.org/docs/17/sql-createpolicy.html
- OpenAI prompt caching: https://platform.openai.com/docs/guides/prompt-caching
- Anthropic prompt caching: https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching
- Phoenix LiveView async assigns: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#assign_async/3
- Ecto.Multi: https://hexdocs.pm/ecto/Ecto.Multi.html
