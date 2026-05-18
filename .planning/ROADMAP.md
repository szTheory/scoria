# Roadmap: Scoria

## Milestones

- ✅ **v1.0 MVP** — Phases 1-4 (shipped 2026-05-10)
- ✅ **v1.1 Caldera** — Phase 5 (shipped 2026-05-11)
- ✅ **v1.2 Corpus** — Phase 6 (shipped 2026-05-11)
- ✅ **v1.3 Seismograph** — Phases 7-11 (shipped 2026-05-12)
- ✅ **v1.4 Keystone** — Phases 12-18 (shipped 2026-05-17; details: `.planning/milestones/v1.4-ROADMAP.md`)
- 🚧 **v1.5 Switchyard** — Phases 19-22 (active)

## Current Milestone

**v1.5 Switchyard**

- Theme: Tool and MCP connector productization
- Goal: Productize remote MCP connector adoption as an embedded Phoenix capability with stateless-first defaults, policy-backed tool scopes, workflow-owned approvals, and operator-grade audit visibility
- Requirements: 14
- Status: Ready to begin implementation

## Phases

### Phase 19: Remote Connector Boundary and Auth Discovery

**Goal**: Establish the Scoria-owned remote connector boundary with durable connector records, boring discovery defaults, and auth/grant storage that fits a normal Phoenix app.
**Depends on**: Phase 13 for public runtime nouns and Phase 14 for boring install/config defaults
**Requirements**: `CONN-01`, `CONN-02`, `AUTH-01`, `AUTH-02`

**Success criteria**
1. A host app can register a remote connector through a Scoria API that persists connector metadata, transport, and health state durably.
2. Discovery/auth plumbing stays behind a Scoria-owned boundary rather than leaking protocol details into ordinary request/UI code.
3. Connector credentials and grant metadata are stored durably with encrypted-at-rest secrets and visible expiry/refresh state.
4. The resulting boundary preserves Scoria's embedded Phoenix product shape instead of introducing hosted-platform assumptions.

### Phase 20: Policy, Stable Tool Identity, and Stateless Invocation

**Goal**: Make remote connector invocation safe and unsurprising by enforcing dual-plane policy, stable local tool identity, and stateless-first invocation defaults.
**Depends on**: Phase 19
**Requirements**: `CONN-03`, `AUTH-03`, `POLI-01`, `POLI-02`
**Plans**: 3 plans

Plans:
- [ ] `20-01-PLAN.md` — Add durable local-tool identity rows, alias/history tracking, and connector-context query helpers.
- [ ] `20-02-PLAN.md` — Reconcile capability refresh into stable local-tool truth with fail-closed drift handling.
- [ ] `20-03-PLAN.md` — Enforce dual-plane invocation policy, typed auth/scope outcomes, and stateless-first remote execution.

**Success criteria**
1. Scoria can derive a stable local tool identity even when the remote catalog changes.
2. Remote auth failures and scope escalation surface as explicit Scoria events and durable evidence.
3. Remote tool invocation only succeeds when both remote grant scope and local Scoria policy allow it.
4. Stateless-first invocation is the default supported path, while stateful remote session handling remains clearly opt-in.

### Phase 21: Remote Approval Flow and Operator Evidence UX

**Goal**: Extend Scoria's workflow-owned approval and evidence model into remote connector scenarios with operator-grade visibility.
**Depends on**: Phase 20
**Requirements**: `POLI-03`, `EVID-01`, `EVID-02`, `EVID-03`

**Success criteria**
1. Remote write, exec, and scope-escalation paths require workflow-owned approvals instead of ad hoc UI mutations.
2. Operators can inspect connector health, granted scopes, and capability refresh state in the embedded dashboard.
3. Operators can review remote invocation evidence tied to exact identity, policy, approval, and redacted request/response summaries.
4. Telemetry remains low-cardinality while still linking operators to exact durable evidence records.

### Phase 22: Curated Connector Profiles and Boring Adoption Path

**Goal**: Productize the remote connector story with a small curated profile layer, install ergonomics, and verification defaults that feel boring in a normal Phoenix app.
**Depends on**: Phase 21
**Requirements**: `DX-01`, `DX-02`
**Plans**: 2 plans

Plans:
- [ ] `22-01-PLAN.md` — Introduce a curated connector profile layer that normalizes predefined profiles.
- [ ] `22-02-PLAN.md` — Wire profile verification test into default adoption proof lane and update operator documentation.

**Success criteria**
1. Scoria ships a small curated connector/profile layer that improves adoption without becoming a marketplace.
2. The default install path, docs, and verification flow for remote connectors are aligned to checked runtime truth.
3. A Phoenix team can adopt the recommended remote connector path without needing to understand protocol internals first.

## Coverage

| Phase | Requirements Covered |
|-------|----------------------|
| 19 | `CONN-01`, `CONN-02`, `AUTH-01`, `AUTH-02` |
| 20 | `CONN-03`, `AUTH-03`, `POLI-01`, `POLI-02` |
| 21 | `POLI-03`, `EVID-01`, `EVID-02`, `EVID-03` |
| 22 | `DX-01`, `DX-02` |

All active milestone requirements are mapped exactly once.

## Forward Look

- `v1.6 Flightpath` remains the likely follow-on for prompt lifecycle and eval-release operations.
- `v1.7 Outrider` remains a future-bet milestone for deeper ecosystem/runtime expansion.
- Next step: `$gsd-discuss-phase 19` or `$gsd-plan-phase 19`.