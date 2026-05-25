# Scoria Roadmap

**Milestone:** `v2.1 Tenant-scoped semantic fast path`
**Status:** approved for execution on 2026-05-25
**Latest shipped milestone:** `v2.0 Relay` on 2026-05-25
**Historical roadmap:** `.planning/milestones/v2.0-ROADMAP.md`
**Historical requirements:** `.planning/milestones/v2.0-REQUIREMENTS.md`

## Summary

- **3 phases**
- **9 requirements mapped**
- **Coverage:** 100%
- **Starting phase number:** 44

## Phase Plan

| Phase | Name | Goal | Requirements | Success Criteria |
|------|------|------|--------------|------------------|
| 44 | Semantic cache contract and persistence | 3/3 | Complete    | 2026-05-25 |
| 45 | Compatibility and invalidation engine | Enforce compatibility checks, stale handling, and invalidation truth before reuse | LOOK-01, LOOK-02, INVD-01, INVD-02 | 4 |
| 46 | Operator evidence and verification | Surface semantic cache outcomes to operators and prove the milestone through checked verification | EVID-01, PROOF-01 | 4 |

## Phase Details

### Phase 44: Semantic cache contract and persistence

**Goal:** Establish the semantic cache as a Scoria-owned core surface with explicit eligibility rules, tenant partitioning, and persistence primitives.

**Requirements:** `FAST-01`, `SAFE-01`, `FAST-02`

**Success criteria:**
1. Developers can route only explicitly safe read-only lanes through semantic fast-path evaluation.
2. Unsafe write-side, approval-sensitive, or personalized-tool-backed responses are rejected from cache admission by default.
3. Semantic cache entries persist durable tenant-partitioned lookup state and compatibility metadata.
4. Miss or ineligible requests continue through the normal runtime path without mutating workflow truth.

### Phase 45: Compatibility and invalidation engine

**Goal:** Make semantic reuse conservative and explainable by combining similarity checks with prompt, policy, source, and freshness compatibility.

**Requirements:** `LOOK-01`, `LOOK-02`, `INVD-01`, `INVD-02`

**Success criteria:**
1. Cache hits require semantic similarity plus prompt, policy, and source compatibility.
2. Stale, incompatible, or rejected candidates fall through cleanly to the normal execution path.
3. Prompt-version, source-fingerprint, and policy changes invalidate affected entries explicitly.
4. Active, stale, and invalidated entry states remain distinguishable in persisted truth.

### Phase 46: Operator evidence and verification

**Goal:** Project semantic cache behavior into Scoria's operator surfaces and close the milestone with checked proof.

**Requirements:** `EVID-01`, `PROOF-01`

**Success criteria:**
1. Operators can inspect semantic cache hit, miss, stale, and rejection outcomes with provenance context.
2. Runtime or workflow detail surfaces expose the partitioning and compatibility reasons behind each semantic outcome.
3. Scoria ships a checked verification lane that proves partitioning, fallback, and invalidation semantics.
4. Milestone docs align the fast-path setup, constraints, and troubleshooting story to the shipped behavior.

## Traceability Check

| Requirement | Phase |
|-------------|-------|
| FAST-01 | 44 |
| SAFE-01 | 44 |
| FAST-02 | 44 |
| LOOK-01 | 45 |
| LOOK-02 | 45 |
| INVD-01 | 45 |
| INVD-02 | 45 |
| EVID-01 | 46 |
| PROOF-01 | 46 |

All active requirements map to exactly one phase.
