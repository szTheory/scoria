# Requirements: Scoria v1.4 Keystone

**Defined:** 2026-05-12
**Core Value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

## v1.4 Requirements

### Identity

- [ ] **IDEN-01**: A Scoria run can carry explicit actor, tenant, and session identifiers through its canonical runtime entrypoint.
- [ ] **IDEN-02**: Workflow, approval, telemetry, and audit paths preserve the same actor, tenant, and session identity without requiring app-specific internal conventions.
- [ ] **IDEN-03**: Session identity supports resumable app-facing flows so a Phoenix app can continue a prior run without reconstructing hidden state manually.

### Runtime API

- [ ] **RUNT-01**: Developers can start a run through a documented public `Scoria` API instead of assembling lower-level workflow modules directly.
- [ ] **RUNT-02**: Developers can resume an interrupted or approval-paused run through the same public runtime surface.
- [ ] **RUNT-03**: Developers can inspect the current state of a run, including status and durable identifiers needed by the host app.

### Policy and Defaults

- [ ] **POLY-01**: Provider, model, and prompt-policy defaults can be configured through a documented application-facing Scoria surface.
- [ ] **POLY-02**: Runtime policy defaults compose cleanly with tenant or actor identity so host apps have a predictable place to attach governance.
- [ ] **POLY-03**: The default configuration path stays installable without forcing optional subsystems beyond the existing documented baseline.

### Adoption Surface

- [ ] **ADOP-01**: `README.md` and install guidance reflect the actual shipped milestone state and public runtime entrypoints.
- [ ] **ADOP-02**: Scoria exposes at least one end-to-end documented Phoenix integration flow showing how request/session context maps into Scoria identity and runtime APIs.
- [ ] **ADOP-03**: Default verification guidance tells a Phoenix team how to prove the core lane is working without unexpectedly requiring the knowledge lane.
- [ ] **ADOP-04**: The top-level public module surface is no longer placeholder-only and instead reflects the library's intended entrypoints.

## v1.5+ Deferred Requirements

### Tool and Connector Productization

- **TOOL-01**: Remote MCP connectors support OAuth/PKCE-aware authorization flows.
- **TOOL-02**: Tool scopes and approval UX cover both local and remote connector identity.

### Release Operations

- **EVAL-01**: Prompt and model versions can be registered and traced through eval and release decisions.
- **EVAL-02**: CI-friendly regression gates compare candidate behavior against approved baselines.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Managed remote runtime hosting | Conflicts with Scoria's embedded Phoenix library shape |
| Browser/code execution breadth as the primary deliverable | Better sequenced after identity and runtime boundaries are explicit |
| Replacing existing workflow/SRE/knowledge boundaries wholesale | Keystone should productize them, not restart them |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| IDEN-01 | Phase 12 | Pending |
| IDEN-02 | Phase 12 | Pending |
| IDEN-03 | Phase 13 | Pending |
| RUNT-01 | Phase 13 | Pending |
| RUNT-02 | Phase 13 | Pending |
| RUNT-03 | Phase 13 | Pending |
| POLY-01 | Phase 14 | Pending |
| POLY-02 | Phase 14 | Pending |
| POLY-03 | Phase 14 | Pending |
| ADOP-01 | Phase 15 | Pending |
| ADOP-02 | Phase 15 | Pending |
| ADOP-03 | Phase 15 | Pending |
| ADOP-04 | Phase 15 | Pending |

**Coverage:**
- v1.4 requirements: 13 total
- Mapped to phases: 13
- Unmapped: 0

---
*Requirements defined: 2026-05-12*
*Last updated: 2026-05-12 after starting v1.4 Keystone*
