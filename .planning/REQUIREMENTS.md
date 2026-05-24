# Requirements: Scoria v2.0 Relay

**Defined:** 2026-05-24
**Core Value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

## v1 Requirements

### Bounded Handoff Contract

- [x] **HAND-01**: Developer can start a bounded delegated run through `Scoria.start_handoff_run/3` with explicit root role, delegated role, delegated kind, and host-supplied handoff input.
- [x] **HAND-02**: Delegated work remains rooted under the same durable run, with a persisted handoff step, durable handoff record, and queued child step instead of transferring root ownership.

### Delegated Evidence

- [ ] **EVID-01**: Developer or operator can inspect delegated lineage, delegated role, delegated kind, and projected context through public run-detail DTOs and the workflow surface.

### Projected Context Safety

- [ ] **SAFE-01**: Public bounded handoffs reject unsafe projected-context keys such as transcript/session/secrets state instead of silently accepting broad delegated context.
- [ ] **SAFE-02**: The public handoff lane stays intentionally narrow and host-controlled, avoiding broad autonomous multi-agent platform behavior in the default Scoria surface.

### Adoption Proof

- [ ] **ADPT-01**: Adoption docs and checked source fragments show how bounded handoffs fit into the normal identity -> start -> inspect -> resume runtime flow for Phoenix apps.
- [ ] **ADPT-02**: `mix test.adoption` canonically covers the public runtime facade, bounded handoff guide/source alignment, and adoption-lane verification without requiring optional knowledge-lane setup.

## v2 Requirements

### Future Candidates

- **FAST-01**: Scoria can provide a tenant-scoped semantic fast path with explicit cache provenance, invalidation, and operator-visible diagnostics.
- **ADPT-03**: Scoria ships stronger bounded-handoff examples only if `v2.0 Relay` proves the current public lane still creates real adopter confusion after verification.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Broad autonomous multi-agent orchestration surface | Would widen Scoria's product boundary beyond the narrow bounded-handoff lane this milestone is meant to formalize. |
| Browser or code-execution productization | Separate privileged-execution risk class that still does not outrank boring bounded-handoff proof. |
| Hosted connector marketplace or broker behavior | Continues to drift away from embedded Phoenix-first product shape. |
| Tenant-scoped semantic caching | Valuable, but still a follow-on capability bet after the handoff lane is formally shipped or consciously closed. |
| Additional handoff examples beyond the current guide and adoption lane | Only worth adding if the active milestone proves a real support burden remains. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| HAND-01 | Phase 41 | Complete |
| HAND-02 | Phase 41 | Complete |
| EVID-01 | Phase 42 | Pending |
| SAFE-01 | Phase 41 | Pending |
| SAFE-02 | Phase 41 | Pending |
| ADPT-01 | Phase 42 | Pending |
| ADPT-02 | Phase 43 | Pending |

**Coverage:**
- v1 requirements: 7 total
- Mapped to phases: 7
- Unmapped: 0

---
*Requirements defined: 2026-05-24*
*Last updated: 2026-05-24 after milestone initialization*
