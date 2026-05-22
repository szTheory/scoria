# Milestone v1.5: Switchyard Requirements

**Status:** Active
**Theme:** Tool and MCP connector productization
**Last updated:** 2026-05-17

## Milestone Goal

Productize remote MCP connector adoption as an embedded Phoenix capability with stateless-first defaults, policy-backed tool scopes, workflow-owned approvals, and operator-grade audit visibility.

## In Scope Requirements

### Connector Boundary

- [ ] **CONN-01**: A Phoenix app can register a remote MCP connector through a Scoria-owned boundary that stores connector metadata, transport mode, and health state durably.
- [ ] **CONN-02**: Connector discovery and capability refresh run through boring defaults that keep transport concerns out of the host app's normal request/UI code.
- [ ] **CONN-03**: Scoria can expose a stable local connector/tool identity even when the remote tool catalog changes over time.

### Auth and Grants

- [ ] **AUTH-01**: Scoria can complete or coordinate remote connector auth flows using modern MCP/OAuth discovery expectations without forcing host apps to hand-roll protocol plumbing.
- [ ] **AUTH-02**: Connector credentials, grants, and expiry state are stored durably with encrypted-at-rest secrets and operator-visible grant metadata.
- [ ] **AUTH-03**: Scope escalation and auth failures surface as explicit Scoria events and evidence instead of silent transport-level surprises.

### Policy and Invocation

- [ ] **POLI-01**: A remote tool invocation is allowed only when both remote grant scope and local Scoria policy permit it.
- [ ] **POLI-02**: Stateless-first remote invocation is the default milestone path, while stateful remote session support remains opt-in per connector.
- [ ] **POLI-03**: Remote write, exec, or scope-escalation paths require workflow-owned approval handling instead of ad hoc UI mutations.

### Operator Evidence and UX

- [ ] **EVID-01**: Operators can inspect connector health, granted scopes, and last capability refresh through the embedded Scoria dashboard.
- [ ] **EVID-02**: Operators can review remote invocation evidence including actor/session identity, policy outcome, approval lineage, and redacted request/response summaries.
- [ ] **EVID-03**: Telemetry and durable evidence preserve low-cardinality metrics while still linking operators to exact connector, approval, and invocation records.

### Curated DX Surface

- [ ] **DX-01**: Scoria ships a small curated connector/profile layer for common remote-tool adoption paths without becoming a connector marketplace.
- [ ] **DX-02**: The default install and verification path for remote connectors stays boring for an ordinary Phoenix app integration.

## Future Requirements

- Stateful remote session lifecycle as a first-class default capability across connectors.
- First-party browser/code-exec productization on top of the connector boundary.
- Prompt/version release gates and eval-release operations tied to connector-aware changes.
- Hosted connector catalog or broker behavior.

## Out of Scope

- **Hosted connector platform** — Scoria remains embedded and app-owned.
- **First-party browser/code-exec tooling** — deferred until connector policy and evidence are proven boring.
- **Prompt/version release discipline** — reserved for likely `v1.6 Flightpath`.
- **Deep runtime interoperability** — future-bet work after the default Phoenix connector story is complete.

## Traceability

| Requirement | Phase | Notes |
|-------------|-------|-------|
| CONN-01 | Phase 19 | Connector registry and durable connector boundary |
| CONN-02 | Phase 19 | Discovery and boring transport defaults |
| CONN-03 | Phase 20 | Stable local tool identity and catalog handling |
| AUTH-01 | Phase 19 | Discovery/auth plumbing boundary |
| AUTH-02 | Phase 19 | Credentials, grants, and expiry durability |
| AUTH-03 | Phase 20 | Auth failure and scope-escalation evidence |
| POLI-01 | Phase 20 | Dual-plane policy enforcement |
| POLI-02 | Phase 20 | Stateless-first invocation defaults |
| POLI-03 | Phase 21 | Workflow-owned approval path for remote connectors |
| EVID-01 | Phase 21 | Connector/operator health surface |
| EVID-02 | Phase 21 | Invocation evidence and approval lineage UX |
| EVID-03 | Phase 21 | Telemetry/evidence linking model |
| DX-01 | Phase 22 | Curated connector/profile surface |
| DX-02 | Phase 22 | Boring install and verification path |
