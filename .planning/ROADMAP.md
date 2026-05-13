# Roadmap: Scoria

## Milestones

- ✅ **v1.0 MVP** — Phases 1-4 (shipped 2026-05-10)
- ✅ **v1.1 Caldera** — Phase 5 (shipped 2026-05-11)
- ✅ **v1.2 Corpus** — Phase 6 (shipped 2026-05-11)
- ✅ **v1.3 Seismograph** — Phases 7-11 (shipped 2026-05-12)
- 🟡 **v1.4 Keystone** — Phases 12-15 (planned)

## Active Milestone: v1.4 Keystone

**Theme:** Embedded app defaults, identity, and public runtime surface

**Goal:** Make Scoria feel like the obvious way for a Phoenix app to add identity-aware AI runs, durable workflow state, policy-backed governance, and operator-visible evidence without guessing at internal boundaries.

**Why this milestone exists**

Scoria has already shipped the substrate: workflows, approvals, knowledge grounding, SRE controls, telemetry, and operator evidence. `v1.4 Keystone` turns that internal capability into a coherent product surface by defining runtime identity, public entrypoints, and adoption defaults before expanding into broader connector or release-ops work.

## Phases

### Phase 12: Canonical Runtime Identity

**Goal**: Define first-class actor, tenant, and session identity so Scoria runs have stable application-facing nouns instead of ad hoc attrs.
**Depends on**: Phases 5, 7, 9, and 10 for workflow truth, audit lineage, approvals, and runtime telemetry
**Plans**: 3 plans

Plans:

- [ ] 12-01: Identity Envelope and Public Runtime Nouns
- [ ] 12-02: Workflow and Approval Identity Propagation
- [ ] 12-03: Telemetry and Audit Identity Alignment

**Requirement coverage:** `IDEN-01`, `IDEN-02`

### Phase 13: Public Runtime API and Session Lifecycle

**Goal**: Expose a documented public API for starting, resuming, and inspecting app-facing runs on top of the durable workflow substrate.
**Depends on**: Phase 12
**Plans**: 4 plans

Plans:

- [ ] 13-01: Top-Level `Scoria` Runtime API Surface
- [ ] 13-02: Start and Resume Run Contracts
- [ ] 13-03: Run Inspection and Host-App References
- [ ] 13-04: Session Continuity Verification

**Requirement coverage:** `IDEN-03`, `RUNT-01`, `RUNT-02`, `RUNT-03`

### Phase 14: Policy Defaults and Install Ergonomics

**Goal**: Make provider, model, prompt-policy, and runtime defaults feel predictable and installable for a normal Phoenix app integration.
**Depends on**: Phases 12 and 13
**Plans**: 3 plans

Plans:

- [ ] 14-01: Application-Facing Policy Configuration Surface
- [ ] 14-02: Identity-Aware Runtime Default Composition
- [ ] 14-03: Default-Lane Install and Verification Hardening

**Requirement coverage:** `POLY-01`, `POLY-02`, `POLY-03`

### Phase 15: Adoption Surface, Docs, and Example Flow

**Goal**: Align the public-facing docs and example integration story with the shipped Keystone runtime surface.
**Depends on**: Phases 12 through 14
**Plans**: 3 plans

Plans:

- [ ] 15-01: README and Public Module Alignment
- [ ] 15-02: End-to-End Phoenix Integration Example
- [ ] 15-03: Operator-Facing Verification Story and Closeout

**Requirement coverage:** `ADOP-01`, `ADOP-02`, `ADOP-03`, `ADOP-04`

## Progress

| Phase | Milestone | Plans Complete | Status |
|-------|-----------|----------------|--------|
| 12. Canonical Runtime Identity | v1.4 | 0/3 | Pending |
| 13. Public Runtime API and Session Lifecycle | v1.4 | 0/4 | Pending |
| 14. Policy Defaults and Install Ergonomics | v1.4 | 0/3 | Pending |
| 15. Adoption Surface, Docs, and Example Flow | v1.4 | 0/3 | Pending |

## Forward Look

- `v1.5 Switchyard` remains the likely next milestone after Keystone for MCP/tool connector productization.
- `v1.6 Flightpath` remains the likely follow-on for prompt lifecycle and eval-release operations.
