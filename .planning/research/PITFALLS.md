# Project Research - Pitfalls

**Milestone:** `v2.1 Tenant-scoped semantic fast path`
**Date:** 2026-05-25
**Question:** What are the main risks when adding a semantic fast path to Scoria?

## 1. Confusing provider prompt caching with application semantic caching

**Why it happens**

Provider prompt caching is easy to over-credit because it already improves latency and cost for repeated prefixes.

**Why it is dangerous**

It does not answer Scoria's core questions:

- who is allowed to reuse an answer
- whether the answer depended on tenant-private or actor-private state
- whether the underlying source or prompt version changed

**Prevention**

- keep provider prompt caching out of the milestone's core requirement language
- model semantic cache reuse as Scoria-owned durable state

## 2. Cross-tenant or over-broad reuse

**Why it happens**

Vector similarity can tempt teams to store one "best answer" and reuse it globally.

**Why it is dangerous**

This is the fastest way to create privacy and correctness failures.

**Prevention**

- require tenant partitioning on every cache read/write
- add actor scoping for personalized-safe lanes
- consider PostgreSQL row-security or equivalent invariant tests if query surfaces expand

## 3. Silent false-positive hits

**Why it happens**

Similarity thresholds look clean in isolated demos but degrade under real prompt drift and source churn.

**Why it is dangerous**

A wrong cache hit is harder to notice than a miss because it appears "fast and correct" until someone spots the stale or mismatched answer.

**Prevention**

- bias initial thresholds conservative
- require prompt / source / policy compatibility gates in addition to similarity
- expose hit reasons and evidence in operator surfaces

## 4. Approximate ANN before trust instrumentation

**Why it happens**

HNSW / IVFFlat are attractive for performance and are easy to adopt prematurely.

**Why it is dangerous**

pgvector's own docs note that filtering is applied after approximate index scans, so filtered searches can miss expected matches without additional tuning.

**Prevention**

- ship exact-first or heavily constrained indexing first
- defer ANN tuning until hit quality and invalidation behavior are measured

## 5. Weak invalidation semantics

**Why it happens**

Teams often invalidate on TTL only and ignore prompt, source, or policy evolution.

**Why it is dangerous**

Scoria already has versioned prompts, datasets, and durable operator evidence. Reusing answers across those boundaries without explicit invalidation would violate support truth.

**Prevention**

- fingerprint source/version inputs
- tie entries to prompt/version/policy metadata
- record invalidation cause explicitly

## 6. Cache writes for unsafe tool-backed or approval-sensitive flows

**Why it happens**

A generic "cache all successful outputs" rule is simpler to implement.

**Why it is dangerous**

Scoria has explicit approval, replay, and workflow-owned truth seams. Unsafe caching can bypass those semantics.

**Prevention**

- restrict `v2.1` to safe read-only classes
- reject write-side, approval-sensitive, or personalized-tool-backed answers by default

## Which Phase Should Address What

- Phase 1: eligibility, partitioning, and persistence invariants
- Phase 2: lookup compatibility and invalidation
- Phase 3: operator diagnostics, threshold review, and support-truth proof

## External References

- OpenAI prompt caching: https://platform.openai.com/docs/guides/prompt-caching
- pgvector official docs: https://github.com/pgvector/pgvector
- PostgreSQL row security policies: https://www.postgresql.org/docs/current/ddl-rowsecurity.html
