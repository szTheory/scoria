# Phase 12: Canonical Runtime Identity - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `12-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-05-13
**Phase:** 12-canonical-runtime-identity
**Areas discussed:** identity envelope shape, persistence model, propagation and override rules, host-app contract

---

## Identity Envelope Shape

| Option | Description | Selected |
|--------|-------------|----------|
| One canonical identity envelope struct | One stable `Scoria.Identity` noun carrying canonical runtime identity, normalized once and reused everywhere | ✓ |
| Separate top-level actor/tenant/session inputs | Explicit inputs at every call site, but no single durable runtime noun | |
| Minimal ids plus freeform metadata | Flexible but identity drifts into conventions and ad hoc keys | |
| Request scope/context object as canonical input | Ergonomic at the boundary, but too coupled to request lifecycle for durable runtime truth | |

**User’s choice:** One canonical identity envelope struct.
**Notes:** Keep the envelope disciplined and flat: first-class canonical ids inside the struct, optional bounded metadata outside the canonical core. Helpers may accept top-level args or Phoenix scope inputs, but they must normalize immediately into the envelope.

---

## Persistence Model

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated canonical columns only | Strong queryability and operator ergonomics, but less extensible | |
| Identity only in metadata / JSON | Flexible early, but high ambiguity and indexing/query footguns | |
| Hybrid columns plus metadata | Canonical identity columns for truth plus extensible app context in maps | ✓ |
| Separate normalized identity table | Rich normalization, but too join-heavy and indirect for this phase | |

**User’s choice:** Hybrid columns plus metadata.
**Notes:** Canonical `actor_id`, `tenant_id`, and `session_id` should become durable first-class columns on the rows that matter; metadata remains secondary extension context and must not override canonical truth.

---

## Propagation and Override Rules

| Option | Description | Selected |
|--------|-------------|----------|
| Run-root identity inherited everywhere with narrow overlays | Simple and workable, but overlays need strict control | |
| Independent per-subsystem attrs and fallbacks | Flexible but identity drift and audit mismatch become likely | |
| Immutable root identity plus separate transient execution context | Stable audit principal plus explicit execution-local context | ✓ |
| Fully explicit scope object passed end-to-end | Correct but too heavy as the primary public posture | |

**User’s choice:** Immutable root identity plus separate transient execution context.
**Notes:** The recommendation keeps A’s inherit-by-default behavior, but root identity must remain immutable. Any local adjustments belong in separate execution context and must be explicit and auditable.

---

## Host-App Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Opaque canonical ids only | Smallest contract, but thin for operator UX and later evidence | |
| Rich typed refs plus metadata | Strong explicitness, but slightly heavier than needed everywhere | |
| App-owned structs / protocols | Native-feeling for some apps, but too magical and coupled | |
| Required canonical ids plus optional labels/metadata | Stable core identity plus ergonomic extras and Phoenix-edge helpers | ✓ |
| Resolver/callback contract from conn/socket/request | Great edge adapter, poor canonical core contract | |

**User’s choice:** Required canonical ids plus optional labels/metadata.
**Notes:** Scoria should require canonical ids and accept optional display/context fields. Phoenix helpers may derive the envelope from `conn.assigns`, session, or LiveView assigns, but that remains an adapter path rather than the core runtime contract.

---

## the agent's Discretion

- Exact public module naming for the canonical identity envelope.
- Exact split of initial durable columns across runs, approvals, trace rows, and audit/SRE tables.
- Exact helper APIs for Phoenix edge extraction and normalization.
- Exact naming of the transient execution-context sidecar.

## Deferred Ideas

- Teaching Scoria arbitrary host-app identity structs as the default contract.
- Using request objects or LiveView socket state as durable runtime truth.
- Building a full authentication or tenancy subsystem into Scoria.
- Solving later Keystone public API and docs/install ergonomics inside this phase.
