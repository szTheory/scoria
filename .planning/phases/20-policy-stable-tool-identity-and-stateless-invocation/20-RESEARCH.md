# Phase 20: Policy, Stable Tool Identity, and Stateless Invocation - Research

**Researched:** 2026-05-17  
**Domain:** Remote MCP connector invocation governance in a Phoenix/Ecto/Oban library  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md]
- **D-01:** Phase 20 should introduce a first-class durable Scoria noun for remote tools, separate from raw capability snapshots. Remote catalog entries are evidence inputs, not runtime identity truth.
- **D-02:** The durable local tool record should have a stable Scoria-owned surrogate id plus an optional human-readable local slug. Local policy, audit, approval lineage, and invocation evidence should refer to this durable local tool id, not directly to the remote tool name.
- **D-03:** Capability refresh should attempt deterministic rebinding in this order:
  - explicit remote stable metadata if present
  - prior alias/history match
  - exact remote name plus compatible schema fingerprint
  - name-only match when the drift is non-widening and compatibility is clear
  - otherwise create a new local tool row
- **D-04:** Ambiguous rebinding must fail closed. When Scoria cannot safely determine continuity, it should preserve the prior local tool row, create a new pending tool candidate if needed, and emit durable evidence that operator review is required later.
- **D-05:** Removed remote tools should not disappear silently. They should transition to a stale/removed local state so prior evidence, policy refs, and invocation history remain intelligible.
- **D-06:** Curated profile-owned canonical tool naming is valuable, but it is a later-layer enhancement, not the core Phase 20 identity mechanism. The generic durable local tool system must work without curated profiles.
- **D-07:** Scoria should not mirror refreshed remote catalogs live into callable tool surface area. A refresh must never silently widen what a Phoenix app can invoke.
- **D-08:** Existing local policy should auto-carry only for non-widening drift:
  - rename/title/description churn
  - schema tightening
  - metadata changes that do not expand blast radius
- **D-09:** Any of the following should quarantine the tool into a disabled-pending state rather than auto-carrying policy:
  - brand-new remote tool
  - schema widening that materially changes effective power
  - newly destructive or open-world behavior
  - scope widening requirement
  - ambiguous identity match
- **D-10:** Safe removals or narrowing changes may apply automatically, but additive or higher-risk changes must require explicit later adoption rather than silent enablement.
- **D-11:** The default mental model should be: existing allowed tools keep working under stable local ids; refresh improves fidelity; refresh never grants new power by surprise.
- **D-12:** Remote invocation should succeed only when both planes allow it:
  - the connector’s current durable grant covers the required remote scope
  - Scoria’s local policy allows the local tool and action class
- **D-13:** Dual-plane policy should be evaluated before outbound remote execution whenever Scoria has enough local information to do so. Remote denial should be a last confirmation, not the primary policy engine.
- **D-14:** Remote annotations and catalog hints may inform risk classification, but they are not trustworthy enough to become enforcement truth on their own. Scoria must preserve its own local action/risk classification boundary.
- **D-15:** Policy outcomes should be stable local result categories, not transport leaks. Callers should see Scoria-owned outcomes such as:
  - `:policy_denied`
  - `:auth_required`
  - `:scope_insufficient`
  - `:scope_escalation_required`
  - `:tool_unavailable`
- **D-16:** Ordinary auth failure should fail fast with a typed local outcome and durable evidence. Expired, missing, or invalid remote grants must not present as opaque remote errors.
- **D-17:** Scope escalation is distinct from ordinary auth failure. If the current grant is valid but insufficient for the requested operation, Scoria should surface a dedicated escalation-needed outcome with exact missing-scope evidence.
- **D-18:** Phase 20 should record scope-escalation intent and evidence in a workflow-compatible shape, but it should not require the full workflow-owned approval UX yet. The Phase 21 approval flow will attach to this seam.
- **D-19:** Durable evidence for auth or scope issues should capture:
  - connector id
  - local tool id
  - actor/tenant/run identity
  - local policy key/outcome
  - remote scope state and exact missing scopes when known
  - redacted request/response summaries
  - linked audit/event ids
- **D-20:** Raw tokens, raw remote auth payloads, and secret-bearing transport details must not leak into normal metadata, telemetry, or operator-facing evidence surfaces.
- **D-21:** The documented happy-path invocation contract for remote connectors should be stateless and request-scoped. The default caller experience should look like a normal explicit library call, not a session broker.
- **D-22:** Scoria must not implicitly create, reuse, or hide remote stateful sessions behind the normal invocation path. Hidden session management would violate the repo’s principle-of-least-surprise posture.
- **D-23:** If a connector genuinely requires stateful remote sessions, the contract must be explicit and separately named, such as a remote session handle distinct from both Scoria `run_id` and host-app `session_id`.
- **D-24:** Stateful remote session support is opt-in per connector capability and per host-app choice, not a default milestone center. The default profile should remain usable across load-balanced and stateless Phoenix deployments.
- **D-25:** Reconnect, expiry, lease, and cleanup semantics for remote session handles should be explicit, auditable, and conservative. Scoria must not silently recreate high-risk stateful sessions after auth/session failure.
- **D-26:** The default product posture for Phoenix teams should feel like `Req` or `Oban`, not a hosted connector control plane:
  - explicit calls
  - durable rows
  - observable jobs/events
  - conservative defaults
- **D-27:** The following should be shifted left into Scoria and future GSD defaults rather than surfaced as routine user choices:
  - local tool rebinding heuristics
  - local slug format
  - non-widening vs widening drift taxonomy
  - quarantine rules for new/high-risk tools
  - typed auth/policy outcome taxonomy
  - redaction defaults for remote evidence
  - stateless-first default connector profile
  - explicit naming for remote session handles
- **D-28:** User interruption should be reserved for materially impactful decisions only:
  - adopting newly discovered higher-risk tools
  - overriding an ambiguous rebind
  - allowing stateful remote sessions for a connector
  - widening local policy or remote scopes

### Claude's Discretion [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md]
- Exact schema/module naming for durable local tool rows and alias/history rows, provided Scoria owns one stable per-tool noun rather than treating snapshots as truth.
- Exact compatibility heuristics for non-widening schema drift, provided they fail closed on ambiguity and do not silently widen power.
- Exact typed-envelope field names for auth/policy outcomes, provided callers receive stable Scoria-owned result categories rather than raw protocol leakage.
- Exact public API shape for explicit stateful opt-in, provided the default invocation lane remains stateless and any remote session handle stays clearly distinct from Scoria run/session identity.

### Deferred Ideas (OUT OF SCOPE) [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md]
- Full workflow-owned approval UX for remote write/exec/scope-escalation paths - Phase 21.
- Embedded dashboard review flows for connector health, local tool adoption, grant scope visibility, and invocation evidence - Phase 21.
- Curated connector profile layer with profile-owned canonical tool naming and adoption sugar - Phase 22.
- Marketplace-style live catalog mirroring or hosted connector-broker behavior.
- Hidden implicit remote session brokering as the default invocation experience.
- Broad release-ops or prompt/eval governance coupling, which remains outside `v1.5` and likely belongs to later milestones.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CONN-03 | Scoria can expose a stable local connector/tool identity even when the remote tool catalog changes over time. [VERIFIED: .planning/REQUIREMENTS.md] | Durable local tool rows, alias/history rows, fail-closed rebinding order, and drift quarantine rules. [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md] |
| AUTH-03 | Scope escalation and auth failures surface as explicit Scoria events and evidence instead of silent transport-level surprises. [VERIFIED: .planning/REQUIREMENTS.md] | Typed local outcomes, exact missing-scope capture, redacted audit outbox events, and workflow-compatible escalation intent seams. [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md] [VERIFIED: lib/scoria/sre.ex] [VERIFIED: lib/scoria/workflows.ex] |
| POLI-01 | A remote tool invocation is allowed only when both remote grant scope and local Scoria policy permit it. [VERIFIED: .planning/REQUIREMENTS.md] | A preflight dual-plane gate should run before outbound invocation and return Scoria-owned outcome categories instead of raw remote transport errors. [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md] [VERIFIED: lib/scoria/mcp/executor.ex] |
| POLI-02 | Stateless-first remote invocation is the default milestone path, while stateful remote session support remains opt-in per connector. [VERIFIED: .planning/REQUIREMENTS.md] | Request-scoped invocation should be the only default path; any stateful lane should use an explicit remote session-handle noun and separate API. [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md] [CITED: https://modelcontextprotocol.io/specification/2025-03-26/basic/transports] [CITED: https://csharp.sdk.modelcontextprotocol.io/concepts/stateless/stateless.html] |
</phase_requirements>

## Summary

Phase 20 should add one new durable center of gravity: a Scoria-owned local remote-tool record that survives catalog refreshes and becomes the only identity used by policy, audit, approval lineage, and invocation evidence. The current Phase 19 connector boundary already persists connectors, grants, and one current capability snapshot, but that snapshot is still the only durable catalog noun; it is evidence, not a safe invocation identity. [VERIFIED: lib/scoria/connectors/connector.ex] [VERIFIED: lib/scoria/connectors/grant.ex] [VERIFIED: lib/scoria/connectors/capability_snapshot.ex] [VERIFIED: .planning/phases/19-remote-connector-boundary-and-auth-discovery/19-RESEARCH.md]

The dual-plane gate should run locally before transport: first resolve the stable local tool binding, then verify local policy for that tool/action class, then verify the active grant covers the required scopes, and only then perform outbound execution. This matches the existing Scoria posture of emitting durable audit rows at execution seams, using Ecto rows as runtime truth, and keeping security-sensitive behavior inspectable rather than hidden in transient sessions or middleware. [VERIFIED: lib/scoria/mcp/executor.ex] [VERIFIED: lib/scoria/sre/audit_outbox_event.ex] [VERIFIED: lib/scoria/workflows.ex] [VERIFIED: .planning/PROJECT.md]

Remote auth discovery and scope-upgrade behavior should follow current MCP guidance: MCP servers must publish Protected Resource Metadata, clients must use PRM for auth-server discovery, `WWW-Authenticate` scope challenges are authoritative for the current operation, and stateless Streamable HTTP is the recommended default. The planning implication is straightforward: Phase 20 should build a stateless-first preflight and evidence layer now, while preserving explicit seams for later approval UX and optional stateful session handles. [CITED: https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization] [CITED: https://www.rfc-editor.org/rfc/rfc9728] [CITED: https://modelcontextprotocol.io/specification/2025-03-26/basic/transports] [CITED: https://csharp.sdk.modelcontextprotocol.io/concepts/stateless/stateless.html]

**Primary recommendation:** Add a durable `ConnectorTool` identity layer plus a `PolicyGate`/`Invocation` seam in front of remote transport, and treat capability snapshots as reconciliation evidence only. [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md] [VERIFIED: lib/scoria/connectors/discovery.ex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Stable local remote-tool identity | API / Backend | Database / Storage | Identity must be durable, queryable, and independent of transient catalog payloads, so Ecto-backed backend rows own it. [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md] [VERIFIED: lib/scoria/connectors/capability_snapshot.ex] |
| Catalog drift reconciliation | API / Backend | Database / Storage | Drift classification and rebinding are business rules that should run in the discovery service and persist explicit outcomes. [VERIFIED: lib/scoria/connectors/discovery.ex] |
| Local policy enforcement | API / Backend | Database / Storage | The local allow/deny decision must happen before outbound invocation and must emit durable evidence. [VERIFIED: lib/scoria/mcp/executor.ex] [VERIFIED: lib/scoria/sre.ex] |
| Remote grant/scope enforcement | API / Backend | Database / Storage | Granted scopes already live in durable grant rows, so the backend should compare required scopes against stored grant truth before transport. [VERIFIED: lib/scoria/connectors/grant.ex] |
| Auth failure and scope-escalation evidence | API / Backend | Database / Storage | Audit outbox rows and workflow events are the existing durable evidence channel; the UI is only a later projection. [VERIFIED: lib/scoria/sre/audit_outbox_event.ex] [VERIFIED: lib/scoria/workflows.ex] |
| Stateless remote invocation | API / Backend | — | Request-scoped invocation is a runtime contract, not a browser or dashboard concern. [CITED: https://csharp.sdk.modelcontextprotocol.io/concepts/stateless/stateless.html] |
| Optional stateful remote session handles | API / Backend | Database / Storage | If added, remote session handles need explicit lifecycle semantics and durable auditability, not hidden in browser or process state. [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md] [CITED: https://modelcontextprotocol.io/specification/2025-03-26/basic/transports] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `ecto_sql` | `3.13.5` (2026-03-03) [VERIFIED: mix hex.info ecto_sql] | Durable runtime truth, migrations, optimistic locking, transactional reconciliation. | Phase 20 is dominated by durable rows and multi-step reconciliation, which matches the repo’s Ecto-first architecture. [VERIFIED: mix.exs] [VERIFIED: lib/scoria/connectors/connector.ex] |
| `oban` | `2.22.1` (2026-04-30) [VERIFIED: mix hex.info oban] | Explicit durable refresh/reconciliation jobs. | Discovery already runs as an Oban worker, and the official docs support SQLite via `Oban.Engines.Lite`, which matches the repo stack. [VERIFIED: lib/scoria/connectors/discovery_job.ex] [CITED: ctx7:/oban-bg/oban] |
| `cloak_ecto` | `1.3.0` (2024-04-06) [VERIFIED: mix hex.info cloak_ecto] | Encrypted grant-secret fields and secret-bearing payload storage. | Phase 20 must preserve the no-secret-leak posture while adding more auth/scope evidence. [VERIFIED: lib/scoria/connectors/grant.ex] |
| `phoenix` | `1.8.7` (2026-05-06) [VERIFIED: mix hex.info phoenix] | Embedded Phoenix boundary and operator/dashboard integration point. | The project boundary remains Phoenix-first and embedded rather than hosted. [VERIFIED: .planning/PROJECT.md] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `ecto_sqlite3` | `0.23.0` (2026-05-05) [VERIFIED: mix hex.info ecto_sqlite3] | Current local DB adapter in this repo. | Use for migrations/tests and any Phase 20 indexes/constraints in the existing SQLite-backed development lane. [VERIFIED: mix.exs] |
| `phoenix_live_dashboard` | `0.8.7` (2025-04-28) [VERIFIED: mix hex.info phoenix_live_dashboard] | Future operator surface projection. | Keep compatible now because Phase 21 will project Phase 20 evidence into the dashboard. [VERIFIED: .planning/ROADMAP.md] [CITED: ctx7:/phoenixframework/phoenix_live_dashboard] |
| `plug` | `1.19.1` locked; `1.19.2` current (2026-05-14) [VERIFIED: mix hex.info plug] | Callback/auth request boundary and explicit HTTP seams. | Use when typed auth or scope failures must be surfaced through Plug/Phoenix boundaries without leaking raw transport details. [VERIFIED: lib/scoria/connectors/auth.ex] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Durable local tool rows | Treat `CapabilitySnapshot.catalog` as runtime identity | Reject this: a single mutable snapshot cannot preserve stable IDs, alias history, stale removal state, or fail-closed ambiguity handling. [VERIFIED: lib/scoria/connectors/capability_snapshot.ex] [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md] |
| Local preflight gate | Let remote 401/403 responses be the policy engine | Reject this: Phase 20 requires Scoria-owned outcomes and durable evidence before transport whenever local information is sufficient. [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md] |
| Stateless request-scoped invocation | Hidden long-lived remote sessions | Reject this as the default: current MCP guidance treats stateless HTTP as the recommended default, and the phase explicitly forbids hidden session brokering. [CITED: https://csharp.sdk.modelcontextprotocol.io/concepts/stateless/stateless.html] [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md] |

**Installation:** No new external dependency is required for the Phase 20 default lane; use the existing stack already present in `mix.exs`. [VERIFIED: mix.exs]

```bash
mix deps.get
mix ecto.migrate
```

**Version verification:** Use `mix hex.info <package>` for Hex packages; this session verified `oban`, `ecto_sql`, `ecto_sqlite3`, `cloak_ecto`, `phoenix`, `phoenix_live_dashboard`, and `plug`. [VERIFIED: mix hex.info oban] [VERIFIED: mix hex.info ecto_sql] [VERIFIED: mix hex.info ecto_sqlite3] [VERIFIED: mix hex.info cloak_ecto] [VERIFIED: mix hex.info phoenix] [VERIFIED: mix hex.info phoenix_live_dashboard] [VERIFIED: mix hex.info plug]

## Architecture Patterns

### System Architecture Diagram

```text
Capability refresh trigger
  -> Scoria.Connectors.DiscoveryJob
  -> Scoria.Connectors.Discovery
  -> fetch remote catalog/auth metadata
  -> classify drift
     -> non-widening + unambiguous
        -> rebind existing local tool id
        -> carry forward local policy
     -> widening/new/ambiguous
        -> create or keep disabled-pending local tool
        -> emit audit evidence for later operator review
  -> persist ConnectorTool + alias/history + CapabilitySnapshot

Invocation request
  -> resolve local tool id from requested local ref
  -> local policy gate
  -> grant/scope gate
     -> grant missing/expired -> auth_required
     -> valid grant but missing scopes -> scope_escalation_required
     -> local policy denied -> policy_denied
     -> tool stale/removed/quarantined -> tool_unavailable
     -> both planes allow
        -> outbound remote transport
        -> typed success/failure envelope
        -> audit outbox event + workflow/event linkage

Optional later seam
  -> explicit remote session handle API
  -> durable lease/expiry/cleanup records
  -> never used by default invocation path
```

The planner should treat discovery reconciliation and invocation gating as two separate write paths sharing the same durable local tool identity. [VERIFIED: lib/scoria/connectors/discovery.ex] [VERIFIED: lib/scoria/mcp/executor.ex]

### Recommended Project Structure

```text
lib/scoria/
├── connectors/
│   ├── connector_tool.ex          # stable local tool noun
│   ├── connector_tool_alias.ex    # alias/history records for rebinding
│   ├── tool_reconciler.ex         # drift classification + rebinding
│   ├── policy_gate.ex             # local policy + grant scope preflight
│   ├── invocation.ex              # typed remote invocation boundary
│   ├── remote_session_handle.ex   # explicit opt-in stateful seam only
│   ├── discovery.ex               # existing refresh pipeline, extended
│   └── grant.ex                   # existing grant truth, reused
├── mcp/
│   └── executor.ex                # typed envelope and audit precedent
└── sre/
    └── audit_outbox_event.ex      # durable evidence sink
```

This structure aligns with the repo’s existing “one durable noun per runtime concern” pattern and keeps discovery, policy, and transport distinct. [VERIFIED: lib/scoria/connectors.ex] [VERIFIED: lib/scoria/workflows.ex]

### Pattern 1: Durable Local Tool Identity
**What:** Add a first-class `ConnectorTool` row with a Scoria-generated primary key, current remote binding fields, lifecycle status, and a separate alias/history relation. [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md]  
**When to use:** For every remotely discovered tool that can ever appear in policy, audit, or invocation evidence. [VERIFIED: .planning/REQUIREMENTS.md]  
**Example:**

```elixir
# Source: lib/scoria/connectors/discovery.ex
Multi.new()
|> Multi.update(:connector, Connector.changeset(connector, connector_attrs))
|> Multi.run(:snapshot, fn repo, _changes ->
  upsert_snapshot(repo, connector.id, snapshot_attrs)
end)
|> Multi.run(:audit_outbox_event, fn repo, %{connector: refreshed, snapshot: snapshot} ->
  {:ok, SRE.insert_audit_outbox_event(repo, refresh_audit_envelope(refreshed, snapshot, trigger_cause, requester))}
end)
```

The phase-specific extension is to add `ConnectorTool` reconciliation into the same durable transaction shape instead of trusting the snapshot alone. [VERIFIED: lib/scoria/connectors/discovery.ex]

### Pattern 2: Fail-Closed Drift Reconciliation
**What:** Compare the refreshed remote tool to the currently bound local tool and only auto-carry policy on unambiguous, non-widening drift. [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md]  
**When to use:** On every discovery refresh and every auth-completion-triggered capability refresh. [VERIFIED: lib/scoria/connectors/discovery_job.ex] [VERIFIED: test/scoria/connectors/auth_test.exs]  
**Example:**

```elixir
# Source: lib/scoria/connectors/discovery_job.ex
use Oban.Worker,
  queue: :connector_sync,
  unique: [
    period: {5, :minutes},
    fields: [:worker, :args],
    keys: [:connector_id, :trigger_class],
    states: [:available, :scheduled, :executing, :retryable]
  ]
```

Use the same explicit job boundary for reconciliation so drift handling stays observable and deduplicated. [VERIFIED: lib/scoria/connectors/discovery_job.ex] [CITED: ctx7:/oban-bg/oban]

### Pattern 3: Dual-Plane Preflight Gate
**What:** Resolve local tool identity, evaluate local policy, verify grant validity and scopes, then invoke transport only if both planes allow. [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md]  
**When to use:** For every remote invocation path, including workflow-owned execution and direct library calls. [VERIFIED: .planning/PROJECT.md]  
**Example:**

```elixir
# Source: lib/scoria/mcp/executor.ex
with {:ok, access_context} <- maybe_capture_sensitive_mcp_access(tool_module, args, context),
     {:ok, reservation_context} <- reserve_budget(tool_module, args, access_context),
     {:ok, execution_context} <- ensure_policy_sensitive_invocation(tool_module, args, access_context, reservation_context) do
  ...
else
  {:error, envelope} ->
    emit_access_denied_telemetry(tool_module, context, envelope)
    {:error, envelope}
end
```

Phase 20 should mirror this typed, pre-transport guard shape for remote connector policy and scope checks. [VERIFIED: lib/scoria/mcp/executor.ex]

### Pattern 4: Stateless by Default, Explicit Stateful Seam
**What:** Make request-scoped invocation the only boring path; require a separate noun and API for remote sessions when a connector truly needs them. [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md]  
**When to use:** Always by default; only diverge for connectors that cannot function without remote session state. [VERIFIED: .planning/REQUIREMENTS.md]  
**Example:**

```elixir
# Source: https://csharp.sdk.modelcontextprotocol.io/concepts/stateless/stateless.html
// Stateless mode is the recommended default for HTTP-based MCP servers.
// When enabled, the server doesn't track any state between requests.
```

The planning implication is to keep any future stateful lane visibly separate from normal `invoke_remote_tool/…` calls. [CITED: https://csharp.sdk.modelcontextprotocol.io/concepts/stateless/stateless.html]

### Anti-Patterns to Avoid

- **Snapshot-as-identity:** Do not let `CapabilitySnapshot.catalog` become the callable truth surface. It is mutable refresh evidence, not durable identity. [VERIFIED: lib/scoria/connectors/capability_snapshot.ex]
- **Silent policy widening:** Do not auto-enable newly discovered or widened tools after refresh. GitHub and Slack both require explicit re-approval when permissions widen; Phase 20 should mirror that posture locally. [CITED: https://docs.github.com/en/enterprise-cloud@latest/apps/maintaining-github-apps/modifying-a-github-app-registration] [CITED: https://docs.slack.dev/authentication/installing-with-oauth]
- **Remote-denial-first policy:** Do not wait for transport 401/403 responses to tell Scoria what the local policy outcome was. [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md]
- **Hidden session brokering:** Do not create or cache remote `Mcp-Session-Id` flows behind the default API. [CITED: https://modelcontextprotocol.io/specification/2025-03-26/basic/transports] [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Background reconciliation | Ad hoc `Task` polling loops | `Oban` jobs with uniqueness and retry semantics | Discovery already uses Oban, and Phase 20 needs the same durable, deduped refresh seam. [VERIFIED: lib/scoria/connectors/discovery_job.ex] [CITED: ctx7:/oban-bg/oban] |
| Secret persistence | Raw token fields in metadata or audit payloads | `CloakEcto` encrypted fields plus redacted audit refs | Phase 20 adds more auth/scope evidence, so secret-bearing fields must stay encrypted and redacted. [VERIFIED: lib/scoria/connectors/grant.ex] [VERIFIED: lib/scoria/sre.ex] |
| Scope discovery | Provider-specific hardcoded “required scopes” tables as the source of truth | MCP PRM plus `WWW-Authenticate` scope challenges | Current MCP guidance treats the challenge scope as authoritative for the current request. [CITED: https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization] |
| Approval lineage | A separate remote-approval mini-framework in Phase 20 | Existing `Scoria.Workflows` event/checkpoint/audit patterns | Phase 21 is explicitly reserved for the approval UX; Phase 20 only needs a compatible seam. [VERIFIED: lib/scoria/workflows.ex] [VERIFIED: .planning/ROADMAP.md] |
| Stateful remote transport | Implicit session caches keyed by host-app session | Explicit remote session handle noun and lifecycle | Hidden session recreation breaks the stateless-first contract and auditability. [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md] |

**Key insight:** Phase 20 is primarily a truth-modeling problem, not a transport SDK problem; the expensive mistakes come from hidden identity and policy state, not from missing HTTP helpers. [VERIFIED: .planning/PROJECT.md] [VERIFIED: lib/scoria/connectors/discovery.ex] [VERIFIED: lib/scoria/mcp/executor.ex]

## Common Pitfalls

### Pitfall 1: Treating catalog refresh as live callable truth
**What goes wrong:** A rename or widened schema silently changes which remote behavior a local policy entry now points at. [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md]  
**Why it happens:** Phase 19 only persists one current `CapabilitySnapshot`, so there is no stable local per-tool identity yet. [VERIFIED: lib/scoria/connectors/capability_snapshot.ex]  
**How to avoid:** Insert a durable local tool row and reconcile refreshes into it; never invoke directly by remote catalog name. [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md]  
**Warning signs:** Policy keys or evidence rows still reference raw remote tool names. [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md]

### Pitfall 2: Conflating missing auth with insufficient scope
**What goes wrong:** Callers see one opaque remote failure even though the remediation differs between re-auth and scope upgrade. [VERIFIED: .planning/REQUIREMENTS.md]  
**Why it happens:** Both arrive as transport failures unless Scoria inspects grant status, scope coverage, and MCP challenge metadata locally. [VERIFIED: lib/scoria/connectors/grant.ex] [CITED: https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization]  
**How to avoid:** Emit typed outcomes such as `:auth_required` and `:scope_escalation_required` with durable evidence and exact missing scopes when known. [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md]  
**Warning signs:** Audit rows contain only generic `connector.auth_failed` or raw HTTP errors without missing-scope detail. [VERIFIED: lib/scoria/connectors/auth.ex]

### Pitfall 3: Carrying policy across widening drift
**What goes wrong:** A previously allowed tool gains destructive or broader behavior and remains callable without explicit adoption. [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md]  
**Why it happens:** The reconciler does not distinguish non-widening from widening schema or action drift. [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md]  
**How to avoid:** Carry forward only non-widening drift and quarantine new, widened, or ambiguous cases. [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md]  
**Warning signs:** Refresh can create new callable tools without creating a pending/disabled state or evidence row. [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md]

### Pitfall 4: Hidden stateful sessions leaking into the default API
**What goes wrong:** The default remote invocation path becomes node-local, reconnect-prone, and hard to reason about in load-balanced deployments. [CITED: https://csharp.sdk.modelcontextprotocol.io/concepts/stateless/stateless.html]  
**Why it happens:** Streamable HTTP allows sessions, and SDK defaults may enable them unless the integrator opts into stateless mode. [CITED: https://modelcontextprotocol.io/specification/2025-03-26/basic/transports] [CITED: https://csharp.sdk.modelcontextprotocol.io/concepts/stateless/stateless.html]  
**How to avoid:** Make stateless request-scoped invocation the only default lane and isolate any stateful support behind an explicit remote session-handle API. [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md]  
**Warning signs:** Invocation APIs start accepting or generating host-app `session_id` values for remote transport semantics. [VERIFIED: .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md]

## Code Examples

Verified patterns from official sources and the current repo:

### Durable Refresh Job Boundary

```elixir
# Source: lib/scoria/connectors/discovery_job.ex
use Oban.Worker,
  queue: :connector_sync,
  unique: [
    period: {5, :minutes},
    fields: [:worker, :args],
    keys: [:connector_id, :trigger_class],
    states: [:available, :scheduled, :executing, :retryable]
  ]
```

This is the correct seam for local tool reconciliation because it is already explicit, durable, and deduplicated. [VERIFIED: lib/scoria/connectors/discovery_job.ex]

### Pre-Transport Typed Denial Envelope

```elixir
# Source: lib/scoria/mcp/executor.ex
{:error,
 %{
   status: :access_denied,
   reason_code: Map.get(context, :access_reason, "policy_denied"),
   audit_outbox_event_id: audit_outbox_event.id,
   trace_id: Map.get(context, :trace_id),
   policy_key: Map.get(context, :policy_key)
 }}
```

Phase 20 should reuse this contract style for `:policy_denied`, `:auth_required`, `:scope_escalation_required`, and `:tool_unavailable`. [VERIFIED: lib/scoria/mcp/executor.ex]

### LiveDashboard Mount Pattern For Later Evidence Projection

```elixir
# Source: ctx7:/phoenixframework/phoenix_live_dashboard
scope "/" do
  pipe_through [:browser, :admins_only]
  live_dashboard "/dashboard"
end
```

Phase 20 should keep evidence rows compatible with this later operator projection path without coupling current execution logic to the UI. [CITED: ctx7:/phoenixframework/phoenix_live_dashboard]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Ad hoc auth discovery per provider | MCP servers must expose Protected Resource Metadata and clients must use PRM for auth-server discovery. [CITED: https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization] | RFC 9728 published April 2025; MCP auth spec now requires PRM. [CITED: https://www.rfc-editor.org/rfc/rfc9728] | Phase 20 should model scope/auth evidence around PRM and `WWW-Authenticate`, not custom per-connector heuristics. |
| Legacy HTTP+SSE transport as the main HTTP transport | Streamable HTTP is the current transport; HTTP+SSE is the legacy compatibility path. [CITED: https://modelcontextprotocol.io/specification/2025-03-26/basic/transports] | MCP transport spec version 2025-03-26. [CITED: https://modelcontextprotocol.io/specification/2025-03-26/basic/transports] | Planning should assume request-scoped POST-first invocation and treat session support as optional. |
| Silent permission additions in connected platforms | GitHub requires updated-permission approval for added permissions, while removed permissions take effect immediately. [CITED: https://docs.github.com/en/enterprise-cloud@latest/apps/maintaining-github-apps/modifying-a-github-app-registration] | Current docs as crawled 2026-05. [CITED: https://docs.github.com/en/enterprise-cloud@latest/apps/maintaining-github-apps/modifying-a-github-app-registration] | This is a strong external precedent for Scoria’s widening-vs-non-widening carry-forward rules. |
| “Request everything once” OAuth posture | Slack now documents additive scopes and optional scopes, reinforcing explicit scope handling and graceful operation when some scopes are absent. [CITED: https://docs.slack.dev/authentication/installing-with-oauth] [CITED: https://docs.slack.dev/changelog/2026/03/16/optional-scopes/] | Optional scopes announced 2026-03-16. [CITED: https://docs.slack.dev/changelog/2026/03/16/optional-scopes/] | Phase 20 should preserve exact missing-scope evidence and keep step-up scope adoption explicit. |

**Deprecated/outdated:**
- Hidden default stateful HTTP sessions as the primary connector contract are outdated for this phase’s design goals; stateless Streamable HTTP is the recommended default and should remain the boring path. [CITED: https://csharp.sdk.modelcontextprotocol.io/concepts/stateless/stateless.html]
- Treating remote catalog names as durable identity is outdated relative to the repo’s runtime-identity posture and this phase’s locked decisions. [VERIFIED: .planning/phases/12-canonical-runtime-identity/12-CONTEXT.md] [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md]

## Assumptions Log

All substantive claims in this research were verified from the current repo, current Hex metadata, Context7 fallback output, or official standards/docs in this session. No additional user confirmation is required before planning. [VERIFIED: this research session]

## Open Questions (RESOLVED)

1. **Where should connector-specific local policy live?**
   - What we know: Existing execution code already carries `policy_key` and emits typed denied envelopes, but there is no connector-tool-specific local policy schema yet. [VERIFIED: lib/scoria/mcp/executor.ex]
   - What's unclear: Whether Phase 20 should introduce a dedicated connector-tool policy schema or reuse an existing policy taxonomy with new key conventions.
   - Recommendation: Plan a dedicated `PolicyGate` module in Phase 20 and let the implementation decide whether the durable rule store is a new schema or a constrained reuse of existing policy structures. [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md]

2. **How rich should alias/history persistence be?**
   - Resolution: Phase 20 should require at least one durable alias/history row type and can treat explicit rebinding-event rows as discretionary if normal audit evidence already records review-worthy drift outcomes. This keeps the required identity seam small while preserving future extensibility. [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md] [VERIFIED: lib/scoria/sre/audit_outbox_event.ex]

3. **What is the minimal workflow-compatible escalation seam?**
   - Resolution: Phase 20 should require at least one durable row or event linking `connector_id`, `local_tool_id`, `run_id`, `step_id`, missing scopes, and the policy outcome, and should prefer reuse of workflow events plus audit outbox lineage over inventing a full approval object early. That creates the exact attachment point Phase 21 needs without forcing the approval UX into this phase. [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md] [VERIFIED: lib/scoria/workflows.ex] [VERIFIED: lib/scoria/sre.ex]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Build, migrations, tests, implementation | ✓ | `1.19.5` [VERIFIED: `elixir --version`] | — |
| Erlang/OTP | Elixir runtime | ✓ | `28` [VERIFIED: `elixir --version`] | — |
| Mix | Dependency and test commands | ✓ | `1.19.5` [VERIFIED: `mix --version`] | — |
| SQLite | Local repo DB lane | ✓ | `3.51.0` CLI present [VERIFIED: `sqlite3 --version`] | Repo can still run through Ecto without direct CLI use. |
| Node/npm | Context7 CLI fallback used during research only | ✓ | `v22.14.0` / `11.1.0` [VERIFIED: `node --version`] [VERIFIED: `npm --version`] | Not required for Phase 20 implementation. |

**Missing dependencies with no fallback:**
- None for the Phase 20 code/test lane. [VERIFIED: this research session]

**Missing dependencies with fallback:**
- None. [VERIFIED: this research session]

## Validation Architecture

`workflow.nyquist_validation` could not be disabled because `.planning/config.json` is absent in this repo, so validation is treated as enabled by default. [VERIFIED: repo lookup for .planning/config.json returned no file]

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Oban testing helpers and Ecto SQL sandbox. [VERIFIED: test/test_helper.exs] [VERIFIED: test/scoria/connectors_test.exs] |
| Config file | `test/test_helper.exs` [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/scoria/connectors_test.exs test/scoria/connectors/auth_test.exs test/scoria/mcp/executor_test.exs test/scoria/mcp/executor_telemetry_test.exs` [VERIFIED: test file presence] |
| Full suite command | `mix test` [VERIFIED: lib/mix/tasks/test.adoption.ex] [VERIFIED: test/test_helper.exs] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CONN-03 | Stable local tool identity survives rename/non-widening drift and quarantines widening/ambiguous drift. [VERIFIED: .planning/REQUIREMENTS.md] | integration | `mix test test/scoria/connectors/tool_reconciliation_test.exs` | ❌ Wave 0 |
| AUTH-03 | Expired grant, missing grant, and insufficient scope return typed outcomes with durable evidence. [VERIFIED: .planning/REQUIREMENTS.md] | integration | `mix test test/scoria/connectors/invocation_policy_test.exs` | ❌ Wave 0 |
| POLI-01 | Local policy plus grant scope are both required before outbound remote invocation. [VERIFIED: .planning/REQUIREMENTS.md] | integration | `mix test test/scoria/connectors/invocation_policy_test.exs` | ❌ Wave 0 |
| POLI-02 | Stateless request-scoped invocation is the default lane and stateful support is explicit/opt-in only. [VERIFIED: .planning/REQUIREMENTS.md] | unit + integration | `mix test test/scoria/connectors/invocation_mode_test.exs` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `mix test test/scoria/connectors_test.exs test/scoria/connectors/auth_test.exs test/scoria/mcp/executor_test.exs test/scoria/mcp/executor_telemetry_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/scoria/connectors/tool_reconciliation_test.exs` — covers stable identity, alias/history, stale removal, and widening-vs-non-widening drift. [VERIFIED: missing from test tree]
- [ ] `test/scoria/connectors/invocation_policy_test.exs` — covers dual-plane policy enforcement and typed auth/scope outcomes. [VERIFIED: missing from test tree]
- [ ] `test/scoria/connectors/invocation_mode_test.exs` — covers stateless default and explicit stateful opt-in seam. [VERIFIED: missing from test tree]
- [ ] One end-to-end workflow lineage test tying invocation failure evidence to `run_id`/`step_id` and audit outbox rows. [VERIFIED: lib/scoria/workflows.ex] [VERIFIED: test/scoria/workflows_test.exs]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | OAuth PKCE, PRM discovery, and typed grant-state handling for remote connectors. [VERIFIED: lib/scoria/connectors/auth.ex] [CITED: https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization] |
| V3 Session Management | yes | Stateless-first default; explicit remote session-handle API if stateful support is ever enabled. [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md] [CITED: https://modelcontextprotocol.io/specification/2025-03-26/basic/transports] |
| V4 Access Control | yes | Dual-plane local policy plus grant-scope gate before invocation. [VERIFIED: .planning/REQUIREMENTS.md] |
| V5 Input Validation | yes | Existing changeset/normalization posture for connector inputs and future policy/invocation params. [VERIFIED: lib/scoria/connectors/params.ex] |
| V6 Cryptography | yes | `CloakEcto` encrypted secret fields; never hand-roll token encryption. [VERIFIED: lib/scoria/connectors/grant.ex] [VERIFIED: mix.exs] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Silent capability widening after refresh | Elevation of Privilege | Fail-closed drift classification; quarantine new/widened/ambiguous tools. [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md] |
| Token or auth-payload leakage into evidence | Information Disclosure | Keep tokens in encrypted fields and emit only redacted refs/metadata. [VERIFIED: lib/scoria/connectors/grant.ex] [VERIFIED: lib/scoria/sre.ex] |
| Confused-deputy/token-passthrough behavior | Elevation of Privilege | Treat remote grant as a separate token domain, bind requests to the target resource, and do not use remote denial as the local policy engine. [CITED: https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization] |
| DNS rebinding/origin trust mistakes in HTTP transport assumptions | Spoofing | Preserve the clear boundary that Scoria is a client to remote MCP servers and do not smuggle browser session semantics into connector transport state. [CITED: https://modelcontextprotocol.io/specification/2025-03-26/basic/transports] |
| Replay of stale remote sessions | Repudiation / Tampering | Keep stateful support opt-in with explicit handle lifecycle, expiry, and cleanup semantics. [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `lib/scoria/connectors.ex`, `lib/scoria/connectors/discovery.ex`, `lib/scoria/connectors/discovery_job.ex`, `lib/scoria/connectors/auth.ex`, `lib/scoria/connectors/connector.ex`, `lib/scoria/connectors/grant.ex`, `lib/scoria/connectors/capability_snapshot.ex` - current connector boundary, grant durability, and refresh behavior. [VERIFIED: repo code]
- `lib/scoria/mcp/executor.ex`, `lib/scoria/workflows.ex`, `lib/scoria/sre.ex`, `lib/scoria/sre/audit_outbox_event.ex` - typed envelope, workflow lineage, and durable evidence patterns. [VERIFIED: repo code]
- `.planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md` - locked Phase 20 decisions and scope. [VERIFIED: repo docs]
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/PROJECT.md`, `.planning/STATE.md` - milestone constraints and requirement mapping. [VERIFIED: repo docs]
- `https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization` - current MCP auth requirements, PRM usage, scope challenge handling, PKCE verification. [CITED: https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization]
- `https://modelcontextprotocol.io/specification/2025-03-26/basic/transports` - Streamable HTTP transport and optional session management semantics. [CITED: https://modelcontextprotocol.io/specification/2025-03-26/basic/transports]
- `https://csharp.sdk.modelcontextprotocol.io/concepts/stateless/stateless.html` - current SDK guidance that stateless mode is the recommended default. [CITED: https://csharp.sdk.modelcontextprotocol.io/concepts/stateless/stateless.html]
- `https://www.rfc-editor.org/rfc/rfc9728` - OAuth 2.0 Protected Resource Metadata standard, published April 2025. [CITED: https://www.rfc-editor.org/rfc/rfc9728]
- `ctx7:/oban-bg/oban` - current Oban installation/SQLite guidance. [CITED: ctx7:/oban-bg/oban]
- `ctx7:/phoenixframework/phoenix_live_dashboard` - current `live_dashboard` router pattern. [CITED: ctx7:/phoenixframework/phoenix_live_dashboard]
- `mix hex.info oban`, `mix hex.info ecto_sql`, `mix hex.info ecto_sqlite3`, `mix hex.info cloak_ecto`, `mix hex.info phoenix`, `mix hex.info phoenix_live_dashboard`, `mix hex.info plug` - current package versions and release dates. [VERIFIED: Hex package metadata]

### Secondary (MEDIUM confidence)

- `https://docs.github.com/en/enterprise-cloud@latest/apps/maintaining-github-apps/modifying-a-github-app-registration` - widening-permission approval precedent. [CITED: https://docs.github.com/en/enterprise-cloud@latest/apps/maintaining-github-apps/modifying-a-github-app-registration]
- `https://docs.github.com/en/enterprise-server@3.17/apps/using-github-apps/approving-updated-permissions-for-a-github-app` - user-facing approval behavior when permissions expand. [CITED: https://docs.github.com/en/enterprise-server@3.17/apps/using-github-apps/approving-updated-permissions-for-a-github-app]
- `https://docs.slack.dev/authentication/installing-with-oauth` - additive scopes and OAuth installation behavior. [CITED: https://docs.slack.dev/authentication/installing-with-oauth]
- `https://docs.slack.dev/changelog/2026/03/16/optional-scopes/` - optional-scope support as a current precedent for explicit scope handling. [CITED: https://docs.slack.dev/changelog/2026/03/16/optional-scopes/]

### Tertiary (LOW confidence)

- None. [VERIFIED: this research session]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - verified from current Hex metadata, repo dependencies, and Context7 fallback. [VERIFIED: mix.exs] [VERIFIED: mix hex.info oban]
- Architecture: HIGH - driven by locked Phase 20 decisions plus current repo seams in connectors, executor, workflows, and SRE. [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md] [VERIFIED: lib/scoria/mcp/executor.ex]
- Pitfalls: HIGH - directly supported by locked phase decisions, current MCP auth/session specs, and current connected-platform permission behavior. [CITED: https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization] [CITED: https://csharp.sdk.modelcontextprotocol.io/concepts/stateless/stateless.html]

**Research date:** 2026-05-17  
**Valid until:** 2026-06-16
