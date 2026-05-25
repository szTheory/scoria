# Project Research - Architecture

**Milestone:** `v2.1 Tenant-scoped semantic fast path`
**Date:** 2026-05-25
**Question:** How should a semantic fast path integrate with Scoria's existing architecture?

## Existing Integration Points

- Retrieval and grounding already persist durable evidence in `Scoria.Knowledge`.
- Runtime defaults and prompt policy are already normalized in `Scoria.Runtime.Defaults`.
- Tenant / actor / session identity already enters at runtime start and handoff boundaries.
- Operator-facing runtime detail and workflow detail surfaces already project curated evidence DTOs.

## Proposed Flow

### 1. Request classification

At the public runtime boundary, classify whether the request is eligible for semantic fast-path evaluation.

Inputs:

- identity (`tenant_id`, `actor_id`, `session_id`)
- runtime defaults / prompt policy
- request payload
- tool / grounding / approval requirements

Output:

- `eligible`
- `eligible_actor_scoped`
- `rejected`

### 2. Cache lookup

If eligible, compute the query embedding and search the semantic cache table with:

- vector similarity
- tenant filter
- actor filter when required
- prompt / policy compatibility filters
- freshness / invalidation filters

If no acceptable match exists, continue down the normal execution path.

### 3. Cache hit projection

If a match passes threshold and compatibility checks:

- return the cached answer payload
- persist durable hit evidence
- expose cache provenance in runtime detail / operator surfaces

### 4. Cache write-back

After a normal successful response in an eligible lane:

- derive reusable evidence refs
- compute source fingerprint
- persist a semantic cache entry

### 5. Invalidation

Invalidate affected entries when:

- source versions change
- prompt version changes
- policy compatibility widens or narrows incompatibly
- operators explicitly revoke bad entries

## Recommended Boundaries

### Core

- cache eligibility engine
- cache persistence schema
- lookup / threshold logic
- invalidation logic
- runtime evidence projection

### Companion / later

- dashboard-heavy analytics beyond basic hit/miss diagnostics
- approximate-index tuning controls
- cross-runtime or external cache adapters

## Packaging Ledger

| Surface | Classification | Reason |
|---------|----------------|--------|
| `Scoria.SemanticCache` core modules | `core` | Native capability inside the embedded runtime boundary |
| Ecto schema + migrations for semantic cache entries | `core` | Durable truth is part of the product promise |
| Runtime / workflow diagnostic projection | `core` | Operator evidence is first-class, not optional |
| Advanced tuning panels / cache analytics | `defer` | Useful, but not needed for first milestone proof |
| External cache backends | `defer` | Adds operational surface area before default truth is proven |

## Build Order

1. persistence schema + eligibility rules
2. lookup path + miss fallback
3. write-back + invalidation hooks
4. operator-visible diagnostics and tests

## External References

- pgvector official docs: https://github.com/pgvector/pgvector
- PostgreSQL `CREATE POLICY`: https://www.postgresql.org/docs/17/sql-createpolicy.html
- Phoenix LiveView async assigns: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#assign_async/3
- Ecto.Multi: https://hexdocs.pm/ecto/Ecto.Multi.html
