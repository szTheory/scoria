# Requirements: Scoria v1.9 Crucible

**Defined:** 2026-05-22
**Core Value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

## v1 Requirements

### Replayable Debugging

- [ ] **RPLY-01**: Operator can branch a new replay run from a durable source run and chosen checkpoint without mutating original run history.
- [x] **RPLY-02**: Replay execution defaults to safe modes that block or stub external-write and approval-sensitive effects while preserving explicit replay provenance.
- [ ] **RPLY-03**: Operator can inspect replay provenance and compare replay output against the original run, including source checkpoint, overrides, and execution-mode evidence.

### Dataset Promotion

- [ ] **DATA-01**: Operator can promote an original or replayed trace into a draft dataset item backed by a frozen evidence snapshot.
- [ ] **DATA-02**: Sealed datasets remain immutable, and promotion into release-driving baseline datasets always requires explicit operator approval.

### Online Scoring

- [ ] **SCOR-01**: Scoria can asynchronously sample eligible production traces and attach online scoring evidence without adding latency to the request path.
- [ ] **SCOR-02**: Online scoring supports deterministic-first rules and optional judge-based scoring while storing scorer version, judge model, and sampling provenance on every score.
- [ ] **SCOR-03**: Operators can review low-quality or policy-triggered traces in a dedicated queue with deep links back to trace evidence and scoring rationale.
- [ ] **SCOR-04**: Draft promotion candidates created from online scoring remain reviewable and separate from sealed baseline datasets until explicitly approved.

## v2 Requirements

### Delegation

- **HAND-01**: Developer can expose bounded public role handoffs over Scoria's existing durable workflow seams without turning Scoria into a hosted orchestration platform.
- **HAND-02**: Operator can inspect delegated role lineage, projected context, and effective tool scope for handoff-driven runs.

### Performance

- **CACH-01**: Developer can opt into tenant-scoped semantic caching for safe grounded read-only flows with durable hit/miss evidence.
- **CACH-02**: Operator can inspect cache provenance, invalidation, and near-threshold misses from the LiveView surface.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Broad branchable sandbox platform or notebook IDE | Too much product-surface expansion for the next milestone; replay should stay focused on operator remediation and eval compounding. |
| Automatic mutation of sealed baseline datasets | Damages eval integrity and operator trust; release-driving truth must stay explicit and reviewable. |
| Broad multi-agent runtime productization | Valuable, but broader than the current operator-loop milestone and more likely to cause platform drift. |
| General semantic caching for arbitrary runs or tool outputs | Optimization-oriented and correctness-sensitive; defer until replay and scoring loops are proven boring. |
| First-party browser/code-exec replay surfaces | Separate privileged-execution risk class already deferred in project state. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| RPLY-01 | Phase 37 | Pending |
| RPLY-02 | Phase 38 | Complete |
| RPLY-03 | Phase 39 | Pending |
| DATA-01 | Phase 39 | Pending |
| DATA-02 | Phase 39 | Pending |
| SCOR-01 | Phase 40 | Pending |
| SCOR-02 | Phase 40 | Pending |
| SCOR-03 | Phase 40 | Pending |
| SCOR-04 | Phase 40 | Pending |

**Coverage:**
- v1 requirements: 9 total
- Mapped to phases: 9
- Unmapped: 0

---
*Requirements defined: 2026-05-22*
*Last updated: 2026-05-22 after opening v1.9 Crucible*
