# Phase 44: Dashboard auth seam - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-07-07
**Phase:** 44-Dashboard auth seam
**Areas discussed:** Router hook composition, Host-asserted dashboard scope, LiveView enforcement and proof, Docs and operator UX boundary

---

## Router Hook Composition

| Option | Description | Selected |
|--------|-------------|----------|
| Direct `on_mount:` pass-through | Phoenix-native API; host hooks run before Scoria hooks; bare macro remains valid. | x |
| Broader `live_session_opts:` pass-through | Future-flexible but risks overriding Scoria layout/hooks. | |
| Custom Scoria option such as `auth_hooks:` | Explicit but non-idiomatic and less discoverable for Phoenix users. | |

**User's choice:** User delegated decision to Claude and asked for researched one-shot recommendations.
**Notes:** Research found Phoenix LiveView, generated auth, LiveDashboard, and Oban Web all point toward native `on_mount:` as the least-surprising DX.

---

## Host-Asserted Dashboard Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Behavior-backed resolver with MFA shorthand | Strong public contract, host-owned authz, explicit tenant scope, ergonomic shorthand. | x |
| Host-only assigns | Maximum host ownership but weak Hex-library guidance and easy to misconfigure. | |
| Session-only tenant | Simple but incomplete for authorization and stale/misleading across LiveView navigation. | |
| Global/process tenant | Low call-site noise but risky hidden state in async Elixir/LiveView code. | |

**User's choice:** User delegated decision to Claude and asked to emphasize Phoenix/Ecto/Plug idioms, DX, and security.
**Notes:** Recommendation mirrors Phase 43 explicit scope and keeps `Plug.Conn`/auth logic at the Phoenix edge.

---

## LiveView Enforcement And Proof

| Option | Description | Selected |
|--------|-------------|----------|
| Shared Scoria scope gate plus host resolver | Central fail-closed enforcement before all dashboard LiveView data access. | x |
| Host-only hook | Strong host ownership but too easy to miss without Scoria validation. | |
| Session-only tenant | Removes query-param trust but does not satisfy the host callback requirement. | |
| Param/session compatibility guard | Lowest migration friction but keeps params in the trust story. | |

**User's choice:** User delegated decision to Claude.
**Notes:** Current code has multiple `params["tenant"] || session["tenant_id"] || "default"` paths plus some global dashboard reads. Proof must combine runtime tests and source-scan guards.

---

## Docs And Operator UX Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| API seam and docs-first copy | Closes the P0 directly, preserves v3.3 UI stability, keeps authz host-owned. | x |
| Read-only scope receipt | Useful if cheap and host-provided; not required for the P0 fix. | |
| Full persistent scope bar | Correct future North-Star UX, but over-scoped for Phase 44. | |
| Optional Sigra recipe | Useful secondary ecosystem recipe; not canonical Scoria integration. | |

**User's choice:** User delegated decision to Claude and asked for UI/UX only where applicable.
**Notes:** Phase 44 should not add tenant switching or a full scope bar. Browser copy should be generic and calm; developer detail belongs in docs and tests.

---

## Claude's Discretion

- User explicitly wrote: "u decide i follow ur recs... for each of these... research using subagents".
- Exact module names and error names are left to the planner.
- Optional read-only scope receipt is allowed but not required.

## Deferred Ideas

- Full persistent scope bar with Tenant/Feature/Time/Live.
- Tenant switching UI.
- In-lib RBAC/roles/policy values.
- Sigra-specific recipe as core dependency.
- Broad `live_session_opts:` pass-through.
