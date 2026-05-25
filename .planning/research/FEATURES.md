# Project Research - Features

**Milestone:** `v2.1 Tenant-scoped semantic fast path`
**Date:** 2026-05-25
**Question:** How should a semantic fast path behave in a Phoenix-first AI quality layer, and which features are table stakes versus differentiators?

## Category 1: Cache Eligibility And Safety

**Table stakes**

- Limit cache reuse to explicitly safe read-only classes of work
- Partition cached answers by tenant at minimum
- Reject caching when provenance or personalization status is unclear
- Make freshness and invalidation state explicit

**Differentiators**

- Admission rules that inspect runtime policy, tool usage, and provenance before caching
- Durable explanations for why a request was cacheable or rejected

**Research notes**

Provider prompt caching is not the same thing as semantic answer caching. Provider prompt caching accelerates repeated prompt prefixes; Scoria still needs application-level truth about who can reuse which answer and why.

## Category 2: Semantic Lookup And Match Policy

**Table stakes**

- Embed incoming query text and compare against stored candidate queries
- Require threshold-based similarity before reuse
- Bind lookup to prompt / source / policy compatibility, not just query similarity
- Support stale / miss / hit outcomes distinctly

**Differentiators**

- Source-fingerprint-aware compatibility checks
- Hybrid matching that combines semantic similarity with exact policy/runtime constraints

**Research notes**

The first version should bias toward false negatives over false positives. Fast misses are acceptable. Incorrect hits erode trust quickly.

## Category 3: Invalidation And Freshness

**Table stakes**

- Expiration / TTL support
- Invalidate when source material changes
- Invalidate when prompt version or policy changes
- Never reuse rows already marked invalidated or stale

**Differentiators**

- Source-derived fingerprints that invalidate affected entries automatically
- Explicit invalidation lineage visible to operators

**Research notes**

Because Scoria already version-controls prompt and dataset surfaces, invalidation should align to those durable boundaries instead of ad hoc app cache clears.

## Category 4: Operator Evidence And Diagnostics

**Table stakes**

- Operators can see hit / miss / stale / rejected outcomes
- Operators can inspect which evidence and source fingerprint justified reuse
- Operators can inspect the partition keys that constrained the cache decision

**Differentiators**

- Runtime detail strips for semantic cache provenance beside existing workflow evidence
- Review affordances for suspicious hits or drift-prone thresholds

**Research notes**

Scoria wins by making runtime truth inspectable. A semantic fast path that hides its reasoning would feel off-brand.

## Anti-Features

- Cross-tenant reuse
- Opaque "AI magic" cache behavior
- Automatic reuse of answers that involved personalized tools, approvals, or mutable write-side effects
- Treating cache hits as canonical truth without storing evidence about why the hit was allowed

## Recommended Scope Shape

`v2.1` should focus on:

1. safe cache admission
2. tenant-scoped lookup
3. prompt / source-aware invalidation
4. operator diagnostics

Defer:

- aggressive ANN optimization
- actor-private long-tail personalization strategies
- provider-specific cache integrations as first-class milestone scope

## External References

- OpenAI prompt caching: https://platform.openai.com/docs/guides/prompt-caching
- Anthropic prompt caching: https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching
- pgvector official docs: https://github.com/pgvector/pgvector
