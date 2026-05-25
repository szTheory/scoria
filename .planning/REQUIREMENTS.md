# Requirements: Scoria

**Defined:** 2026-05-25
**Core Value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.
**Milestone:** `v2.1 Tenant-scoped semantic fast path`

## v2.1 Requirements

### Eligibility And Safety

- [ ] **FAST-01**: Developer can enable semantic fast-path evaluation only for explicitly safe read-only runtime lanes.
- [ ] **SAFE-01**: Scoria refuses to cache or reuse answers from write-side, approval-sensitive, or personalized-tool-backed flows unless they are explicitly classified as safe.

### Partitioning And Lookup

- [ ] **FAST-02**: Semantic cache lookups are always partitioned by `tenant_id`, with stricter actor or policy scoping when compatibility requires it.
- [ ] **LOOK-01**: Scoria reuses a cached answer only when semantic similarity, prompt compatibility, policy compatibility, and source compatibility all pass.
- [ ] **LOOK-02**: Cache miss, stale, or rejected outcomes fall through to the normal execution path without changing workflow truth.

### Invalidation And Freshness

- [ ] **INVD-01**: Cache entries invalidate when prompt version, source fingerprint, or policy compatibility changes.
- [ ] **INVD-02**: Developers and operators can distinguish active, stale, and invalidated cache entries with explicit reasons.

### Operator Evidence And Proof

- [ ] **EVID-01**: Operators can inspect cache hit, miss, stale, and rejection outcomes with provenance and partitioning context in Scoria runtime or workflow surfaces.
- [ ] **PROOF-01**: Scoria ships a checked verification lane that proves semantic fast-path partitioning, fallback semantics, and invalidation behavior.

## Future Requirements

### Adoption Follow-up

- **ADPT-03**: Scoria ships stronger bounded-handoff examples only if `v2.0 Relay` verification proves the current public lane still creates real adopter confusion.

### Defer

- **FAST-03**: Scoria supports external cache backends beyond the default Ecto-native semantic cache truth store.
- **FAST-04**: Scoria exposes advanced ANN tuning and analytics controls once exact-first proof and operator trust are established.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Provider prompt caching as the primary milestone deliverable | Improves prefix reuse but does not solve tenant isolation, provenance, or invalidation truth |
| Cross-tenant semantic reuse | Violates Scoria's privacy and support-truth bar |
| Automatic caching of write-side, approval-sensitive, or personalized-tool-backed flows | Too risky for the first semantic fast-path milestone |
| Hosted cache service or external cache tier as default truth | Widens the product boundary before the embedded default path is proven |
| Advanced cache analytics and ANN tuning controls | Useful later, but not required for first milestone proof |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| FAST-01 | Phase 44 | Pending |
| SAFE-01 | Phase 44 | Pending |
| FAST-02 | Phase 44 | Pending |
| LOOK-01 | Phase 45 | Pending |
| LOOK-02 | Phase 45 | Pending |
| INVD-01 | Phase 45 | Pending |
| INVD-02 | Phase 45 | Pending |
| EVID-01 | Phase 46 | Pending |
| PROOF-01 | Phase 46 | Pending |

**Coverage:**
- v2.1 requirements: 9 total
- Mapped to phases: 9
- Unmapped: 0

---
*Requirements defined: 2026-05-25*
*Last updated: 2026-05-25 after initial v2.1 definition*
