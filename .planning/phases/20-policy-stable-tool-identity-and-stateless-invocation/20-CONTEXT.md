# Phase 20: Policy, Stable Tool Identity, and Stateless Invocation - Context

**Gathered:** 2026-05-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Make remote connector invocation safe and unsurprising by enforcing dual-plane policy, stable local tool identity, and stateless-first invocation defaults.

This phase turns the durable connector/auth boundary from Phase 19 into a durable invocation boundary. It must preserve stable local tool identity across remote catalog drift, ensure invocation only succeeds when both remote grant scope and local Scoria policy allow it, and surface auth failures or scope escalation as explicit Scoria events and durable evidence. It does not yet broaden into the full operator approval UX for remote writes/exec/scope escalation or the dashboard-first evidence review flow; those remain Phase 21 work.

</domain>

<decisions>
## Implementation Decisions

### Stable local tool identity
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

### Catalog drift and policy carry-forward
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

### Dual-plane policy enforcement
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

### Auth failure and scope escalation surfacing
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

### Stateless-first invocation contract
- **D-21:** The documented happy-path invocation contract for remote connectors should be stateless and request-scoped. The default caller experience should look like a normal explicit library call, not a session broker.
- **D-22:** Scoria must not implicitly create, reuse, or hide remote stateful sessions behind the normal invocation path. Hidden session management would violate the repo’s principle-of-least-surprise posture.
- **D-23:** If a connector genuinely requires stateful remote sessions, the contract must be explicit and separately named, such as a remote session handle distinct from both Scoria `run_id` and host-app `session_id`.
- **D-24:** Stateful remote session support is opt-in per connector capability and per host-app choice, not a default milestone center. The default profile should remain usable across load-balanced and stateless Phoenix deployments.
- **D-25:** Reconnect, expiry, lease, and cleanup semantics for remote session handles should be explicit, auditable, and conservative. Scoria must not silently recreate high-risk stateful sessions after auth/session failure.

### DX and shift-left defaults
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

### the agent's Discretion
- Exact schema/module naming for durable local tool rows and alias/history rows, provided Scoria owns one stable per-tool noun rather than treating snapshots as truth.
- Exact compatibility heuristics for non-widening schema drift, provided they fail closed on ambiguity and do not silently widen power.
- Exact typed-envelope field names for auth/policy outcomes, provided callers receive stable Scoria-owned result categories rather than raw protocol leakage.
- Exact public API shape for explicit stateful opt-in, provided the default invocation lane remains stateless and any remote session handle stays clearly distinct from Scoria run/session identity.

</decisions>

<specifics>
## Specific Ideas

- The coherent Phase 20 shape is:
  - durable `connector_tool`-style local rows
  - capability snapshots as refresh evidence, not identity truth
  - stable local ids with alias/rebinding history
  - policy auto-carry only for non-widening drift
  - new or widened tools quarantined by default
  - typed Scoria auth/policy outcomes
  - stateless remote invocation as the boring path
  - explicit remote session handle only when a connector truly requires state
- Example local identity posture:
  - local tool id: `ctool_123`
  - local slug: `github.issue_search`
  - current remote binding: `search_issues`
  - prior alias: `issues.search`
- Example drift behavior:
  - remote rename plus same risk/schema class -> preserve `ctool_123`
  - remote adds `repo.delete` -> create disabled-pending local tool, no silent policy carry
  - remote widens input shape to permit broader destructive targets -> quarantine until explicit adoption
- Example invocation outcomes:
  - expired token -> `{:error, %{status: :auth_required, reason_code: "grant_expired", audit_outbox_event_id: ...}}`
  - insufficient current scope -> `{:error, %{status: :scope_escalation_required, missing_scopes: ["repo:write"], audit_outbox_event_id: ...}}`
- Strong outside lessons worth preserving:
  - MCP auth is now firmly OAuth/PRM/PKCE-shaped and multi-server aware.
  - Slack- and GitHub-style permission expansion flows reinforce that new power should require explicit adoption.
  - Embedded Elixir/Phoenix libraries earn trust by making runtime truth durable and inspectable rather than hiding it in long-lived process/session magic.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirement intent
- `.planning/ROADMAP.md` - Phase 20 goal, success criteria, and dependency on Phase 19.
- `.planning/PROJECT.md` - embedded Phoenix-first product boundary and current Switchyard thesis.
- `.planning/REQUIREMENTS.md` - `CONN-03`, `AUTH-03`, `POLI-01`, and `POLI-02`.
- `.planning/STATE.md` - current milestone posture and locked strategic constraints.
- `.planning/MILESTONE-ARC.md` - why remote connector governance is the current leverage point.
- `.planning/research/v1.5-switchyard-recommendation.md` - active recommendation synthesis for remote connector productization.

### Prior locked Scoria decisions
- `.planning/phases/12-canonical-runtime-identity/12-CONTEXT.md` - stable runtime nouns and durable-column-first identity truth.
- `.planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md` - explicit runtime API posture and `run_id` vs `session_id` semantics.
- `.planning/phases/14-policy-defaults-and-install-ergonomics/14-CONTEXT.md` - policy/default composition and shift-left posture.
- `.planning/phases/15-adoption-surface-docs-and-example-flow/15-CONTEXT.md` - principle-of-least-surprise public surface expectations.
- `.planning/phases/18-add-executable-adoption-flow-guards/18-CONTEXT.md` - boring default-lane adoption and executable proof posture.
- `.planning/phases/19-remote-connector-boundary-and-auth-discovery/19-CONTEXT.md` - durable connector/auth nouns, explicit refresh jobs, and stateless-first connector direction.

### Current code surface
- `lib/scoria/connectors.ex` - current connector registration/update/list/sync boundary.
- `lib/scoria/connectors/connector.ex` - durable connector truth and optimistic-lock posture.
- `lib/scoria/connectors/grant.ex` - encrypted grant/secrets durability model.
- `lib/scoria/connectors/capability_snapshot.ex` - current snapshot truth that Phase 20 should treat as evidence input rather than runtime identity.
- `lib/scoria/connectors/discovery.ex` - explicit refresh pipeline and audit seam for catalog drift.
- `lib/scoria/connectors/params.ex` - current normalization/default posture, including stateless profile precedent.
- `lib/scoria/connectors/auth.ex` - current auth success/failure durability seam.
- `lib/scoria/mcp/executor.ex` - typed envelope precedent, policy-sensitive audit seam, and existing execution context shape.
- `lib/scoria/workflows.ex` - durable workflow and approval lineage patterns Phase 20 must stay compatible with.
- `lib/scoria/sre.ex` - audit/evidence insert seam.
- `lib/scoria/sre/audit_outbox_event.ex` - durable evidence schema pattern.
- `test/scoria/connectors_test.exs` - current connector refresh expectations and audit behavior.
- `test/scoria/connectors/schema_test.exs` - current durable-column and optimistic-lock expectations for connector/auth snapshot rows.
- `test/scoria/mcp/executor_test.exs` - current typed result envelope and policy-sensitive execution expectations.
- `test/scoria/mcp/executor_telemetry_test.exs` - remote integration telemetry and policy metadata posture.

### Product and architecture guidance
- `prompts/scoria-gsd-kickoff.md` - Scoria’s runtime/MCP governance and operator-first framing.
- `prompts/phoenix-ai-lib-deep-research.md` - ecosystem lessons from Phoenix-native AI libs and MCP/tool systems.
- `prompts/scoria-brand-book-deep-research.md` - calm, evidence-first product posture.
- `prompts/sztheory-elixir-dna.md` - batteries-included but composable embedded Phoenix library rules.

### External standards and ecosystem guidance
- `https://modelcontextprotocol.io/specification/draft/basic/authorization` - current MCP auth expectations: PRM discovery, multi-auth-server handling, PKCE, and explicit `WWW-Authenticate` scope challenges.
- `https://modelcontextprotocol.io/docs/tutorials/security/authorization` - practical MCP auth flow and PRM tutorial.
- `https://www.rfc-editor.org/rfc/rfc9728.html` - OAuth 2.0 Protected Resource Metadata, published April 2025.
- `https://csharp.sdk.modelcontextprotocol.io/concepts/stateless/stateless.html` - current MCP SDK explanation of stateless-vs-stateful HTTP posture and why stateless is recommended by default.
- `https://docs.langchain.com/oss/python/langgraph/human-in-the-loop` - durable interrupt/resume pattern and why long-lived state should be explicit and persisted.
- `https://docs.langchain.com/oss/python/langgraph/overview` - durable execution and orchestration posture from a successful adjacent runtime.
- `https://hexdocs.pm/oban/Oban.html` - idiomatic Elixir example of durable, observable, database-backed background work.
- `https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.Router.html` - idiomatic Phoenix mounted-operator-surface posture.
- `https://docs.github.com/en/enterprise-cloud@latest/apps/maintaining-github-apps/editing-a-github-apps-permissions` - explicit approval when GitHub App permissions widen.
- `https://docs.slack.dev/app-management/quickstart-app-settings` - explicit reinstall when Slack scopes widen.
- `https://docs.slack.dev/authentication/installing-with-oauth` - additive scope behavior and explicit re-authorization flow.
- `https://developer.atlassian.com/cloud/oauth/` - Atlassian OAuth scope model and least-privilege guidance.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scoria.Connectors.Discovery` already provides the right durable refresh seam for catalog-drift reconciliation, evidence emission, and later local tool rebinding.
- `Scoria.Connectors.Connector`, `Grant`, and `CapabilitySnapshot` already establish the Ecto-first durability posture that Phase 20 should extend rather than bypass.
- `Scoria.MCP.Executor` already has the typed-envelope, audit, breaker, and policy-sensitive invocation seam that remote connector invocation should mirror.
- `Scoria.Workflows` and `Scoria.SRE` already demonstrate the transactional pattern for durable evidence and workflow-compatible future escalation seams.
- Existing connector tests already establish explicit sync jobs, optimistic locking, and durable snapshot metadata as first-class proof lanes.

### Established Patterns
- Ecto rows are durable runtime truth; discovery snapshots, telemetry, and LiveView are projections or evidence of that truth.
- Scoria favors explicit public/runtime nouns over implicit platform magic.
- Security-sensitive behavior is expressed through audit/breaker/policy seams with durable evidence, not hidden middleware or process-local state.
- The repo keeps the default lane boring and pushes low-impact defaults left, reserving user interruption for real blast-radius choices.

### Integration Points
- Phase 20 should add durable local tool rows tied to connectors and fed by capability refresh.
- Discovery refresh should produce both snapshot updates and local tool reconciliation outcomes in one explicit durable flow.
- Remote invocation should pass through a connector-aware policy gate before reaching outbound transport code.
- Auth failure and scope-escalation outcomes should reuse the typed result and audit envelope style already present in `Scoria.MCP.Executor`.
- Future Phase 21 approval UX should attach to the durable evidence and escalation seams defined here rather than redefining the remote invocation boundary.

</code_context>

<deferred>
## Deferred Ideas

- Full workflow-owned approval UX for remote write/exec/scope-escalation paths - Phase 21.
- Embedded dashboard review flows for connector health, local tool adoption, grant scope visibility, and invocation evidence - Phase 21.
- Curated connector profile layer with profile-owned canonical tool naming and adoption sugar - Phase 22.
- Marketplace-style live catalog mirroring or hosted connector-broker behavior.
- Hidden implicit remote session brokering as the default invocation experience.
- Broad release-ops or prompt/eval governance coupling, which remains outside `v1.5` and likely belongs to later milestones.

</deferred>

---

*Phase: 20-policy-stable-tool-identity-and-stateless-invocation*
*Context gathered: 2026-05-17*
