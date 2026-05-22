# Phase 19: Remote Connector Boundary and Auth Discovery - Context

**Gathered:** 2026-05-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish the Scoria-owned remote connector boundary with durable connector records, boring discovery defaults, and auth/grant storage that fits a normal Phoenix app.

This phase creates the embedded Phoenix/Ecto boundary for registering remote MCP connectors, discovering auth metadata and capabilities, and durably storing connector and grant state. It does not yet solve stable local tool identity, dual-plane policy enforcement, workflow-owned approvals for remote writes, or the full operator evidence UX across invocations; those belong to Phases 20 and 21.

</domain>

<decisions>
## Implementation Decisions

### Connector registration shape
- **D-01:** Scoria should use a hybrid registration model where a durable `Connector` record is the runtime source of truth and optional `profile_key` / adapter modules provide boring defaults rather than owning state.
- **D-02:** The primary Phase 19 registration contract should be explicit and Ecto-friendly, not inference-heavy. Host apps should register enough durable truth to make discovery, auth, health, and operator evidence inspectable.
- **D-03:** Compile-time module registration is not the primary product posture for Phase 19. It may exist later for curated Scoria-shipped profiles, but runtime-owned connector state must live in Ecto rows.
- **D-04:** Minimal “endpoint only” registration is too implicit for Scoria’s product shape. Discovery/auth failures, granted scopes, and health state must not hide behind inference.

### Registration nouns and field posture
- **D-05:** Phase 19 should introduce first-class durable connector nouns rather than overloading workflow metadata. At minimum, Scoria should own connector rows, auth/grant rows, and a current capability snapshot or equivalent durable discovery state.
- **D-06:** The connector row should likely own: `id`, `tenant_id` or equivalent scope when applicable, `key`/`slug`, `label`, `endpoint_url`, `transport_kind`, `auth_mode`, `profile_key`, optional `adapter_module`, `status`, `health_state`, discovery timestamps, refresh timestamps, and bounded redacted metadata.
- **D-07:** The auth/grant row should own the current durable auth truth for one connector/account pairing: grant kind, status, granted scopes, subject/account reference, expiry/refresh timestamps, last refresh status, and last auth error state.
- **D-08:** Provider-specific or non-query-critical details may live in bounded JSONB metadata, but canonical operational fields must be first-class columns where operator queries, audits, and Phase 20 policy work need them.

### Discovery and capability refresh behavior
- **D-09:** Discovery should happen in two stages:
  - registration/update time for remote auth metadata and protected-resource discovery
  - post-auth or post-scope-change time for the first durable capability snapshot
- **D-10:** The boring default should be explicit sync jobs, not blind periodic polling. Refresh should be durable, observable, and trigger-driven.
- **D-11:** Capability refresh should be triggered by registration, auth completion, scope changes, operator “sync now,” connector invalidation/failure, and remote change notifications where available.
- **D-12:** Phase 19 should persist enough refresh metadata for later operator UX: `last_refresh_at`, `last_refresh_status`, `last_good_refresh_at`, `last_refresh_error_code`, catalog hash/version, discovered auth/resource metadata URLs, and staleness state.
- **D-13:** Stateless-first still applies here: Phase 19 should prefer snapshot-and-refresh over long-lived remote sessions or hidden background subscriptions.

### Auth posture
- **D-14:** Scoria should support multiple auth methods through a normalized adapter boundary, but the primary documented happy path for human-facing remote MCP connectors should be browser redirect OAuth with PKCE.
- **D-15:** API key / bearer secret auth and machine-to-machine client-credentials-style auth may be allowed in Phase 19, but they should be secondary paths rather than the core story.
- **D-16:** Device authorization flow is not the Phase 19 default. It is a secondary fallback for connectors where browser redirect is genuinely unavailable.
- **D-17:** The Phoenix/Plug boundary for auth should be boring and explicit: short-lived `state`, PKCE verifier, and return target in session or equivalent transient storage; completed grants and connector state in Ecto; no durable connector secrets in cookies or request-scoped state.
- **D-18:** Host apps continue to own user login, actor/tenant resolution, business authorization, and admin/operator authentication. Scoria owns connector auth plumbing, grant durability, and operator-visible connector state.

### Grant and secret durability model
- **D-19:** Scoria should not collapse connector, grant, and secret state into one mutable blob. Phase 19 should use normalized connector and auth/grant records, with encrypted secret payloads isolated from visible operator metadata.
- **D-20:** Encrypt access tokens, refresh tokens, client secrets, device codes, raw token response fragments, and other secret-bearing fields at rest. Keep non-secret metadata queryable: scopes, issuer/resource identifiers, expiry timestamps, status, rotation state, and redacted failure notes.
- **D-21:** Grant rows should be optimistic-lock friendly and durable enough for refresh, expiry, and re-auth flows without requiring JSON diffing.
- **D-22:** Capability snapshot provenance may be a separate row or bounded related record if needed for refresh lineage, but full history UX is not required in Phase 19.

### Scope, DX, and shift-left policy
- **D-23:** The user-facing decision surface for normal Phase 19 adoption should stay small:
  - connector endpoint
  - auth strategy only when the boring default is not appropriate
  - optional curated profile selection
  - any explicit scope widening or offline-refresh consent
- **D-24:** Low-impact choices should be shifted left into Scoria and GSD defaults: metadata discovery rules, PKCE requirement, redirect/callback shape, secure session handling, redaction defaults, refresh trigger policy, least-privilege scope posture, conservative staleness heuristics, and default sync behavior.
- **D-25:** Phase 19 should optimize for principle-of-least-surprise Phoenix DX: one obvious registration path, durable Ecto truth, explicit sync actions, and no hosted-broker magic.

### the agent's Discretion
- Exact module names and schema names for connector/auth snapshot rows, provided the durable nouns above remain explicit and coherent.
- Exact precedence rules between a connector record and an optional profile/adapter module, provided the durable record remains the final runtime truth after normalization.
- Exact Oban-vs-equivalent job orchestration for sync, provided refresh stays durable, observable, and explicit instead of hidden polling magic.
- Exact encrypted-field implementation and storage helper choice, provided secrets remain encrypted at rest and redacted in evidence surfaces.

</decisions>

<specifics>
## Specific Ideas

- The coherent Scoria shape for Phase 19 is:
  - durable connector rows as runtime truth
  - optional curated profile sugar layered on top
  - browser redirect OAuth + PKCE as the main remote connector story
  - explicit sync jobs and durable capability snapshots
  - encrypted grants/secrets with visible non-secret operator metadata
- This follows the same posture locked in prior phases:
  - one obvious public boundary
  - Ecto rows as durable truth
  - Plug-facing transport/auth seams
  - LiveView as operator evidence and UX only
- Strong outside lessons that apply directly:
  - MCP auth has moved toward protected-resource metadata and OAuth-style discovery rather than ad hoc connector auth.
  - FastMCP is a good reminder that protocol complexity should feel like normal app code, but Scoria should not copy code-first runtime inference as the primary state model.
  - Oban/Req-style DX is a better fit for Scoria than DSL-heavy compile-time configuration for runtime-owned connector state.
- Footguns to avoid:
  - turning connector rows into opaque metadata blobs
  - storing durable connector secrets in cookies/session state
  - silent periodic polling that makes Scoria feel like a hosted broker
  - compile-time connector declarations that diverge from runtime grant truth
  - letting minimal registration hide auth/discovery/product-shaping behavior

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirement intent
- `.planning/ROADMAP.md` - Phase 19 goal, dependency chain, and v1.5 sequencing.
- `.planning/PROJECT.md` - embedded Phoenix-first product boundary and current milestone thesis.
- `.planning/REQUIREMENTS.md` - `CONN-01`, `CONN-02`, `AUTH-01`, and `AUTH-02`.
- `.planning/STATE.md` - current milestone posture and explicit TODO to begin Phase 19.
- `.planning/MILESTONE-ARC.md` - why connector productization is next and what remains out of scope.
- `.planning/research/v1.5-switchyard-recommendation.md` - active recommendation synthesis for Switchyard defaults.

### Prior locked Scoria decisions
- `.planning/phases/12-canonical-runtime-identity/12-CONTEXT.md` - canonical identity posture and durable-column-first runtime truth.
- `.planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md` - explicit public boundary and boring Phoenix runtime posture.
- `.planning/phases/14-policy-defaults-and-install-ergonomics/14-CONTEXT.md` - batteries-included but composable config/default posture and shift-left rule.
- `.planning/phases/15-adoption-surface-docs-and-example-flow/15-CONTEXT.md` - one obvious host-app integration path and principle-of-least-surprise docs posture.
- `.planning/phases/18-add-executable-adoption-flow-guards/18-CONTEXT.md` - default core-lane verification and embedded operator-surface posture.

### Product and architecture guidance
- `prompts/scoria-gsd-kickoff.md` - Scoria’s runtime, MCP/tool governance, and operator-UI framing.
- `prompts/phoenix-ai-lib-deep-research.md` - ecosystem lessons from Phoenix-native AI libraries, MCP systems, and eval/ops products.
- `prompts/scoria-brand-book-deep-research.md` - calm, operator-grade, evidence-first product posture.
- `prompts/sztheory-elixir-dna.md` - batteries-included but composable, Ecto-native, embedded LiveView dashboard rules.

### Current code surface
- `lib/scoria.ex` - top-level public facade posture that new connector APIs should match.
- `lib/scoria/runtime.ex` - explicit public lifecycle layer behind the facade.
- `lib/scoria/runtime/params.ex` - normalization-before-runtime pattern to mirror for connector registration.
- `lib/scoria/identity.ex` - explicit edge-normalization posture.
- `lib/scoria/workflows.ex` - durable workflow truth and existing transactional style.
- `lib/scoria/workflows/run.ex` - current durable run schema pattern for first-class runtime rows.
- `lib/scoria/mcp/router.ex` - Plug-facing MCP boundary that Phase 19 must preserve rather than bypass.
- `lib/scoria/mcp/executor.ex` - current MCP execution, audit, budget, and breaker seam that future remote connector work will feed.
- `lib/scoria/observe/redactor.ex` - current redaction rules and default secret posture.
- `lib/scoria/sre.ex` - existing audit/event durability seam.
- `lib/scoria/sre/audit_outbox_event.ex` - durable audit evidence schema pattern relevant to connector auth and refresh events.
- `test/scoria/mcp/router_test.exs` - current MCP Plug integration expectations.
- `test/scoria/mcp/executor_test.exs` - current policy-sensitive audit and redaction posture around MCP execution.

### External standards and ecosystem guidance
- `https://modelcontextprotocol.io/specification/2025-06-18/basic/authorization` - current MCP authorization specification; OAuth-based protected-resource discovery expectations.
- `https://modelcontextprotocol.io/specification/draft/basic/authorization` - draft guidance on current interoperability/security posture, including PKCE expectations.
- `https://modelcontextprotocol.io/docs/tutorials/security/authorization` - explanatory MCP auth guidance for remote servers.
- `https://www.rfc-editor.org/rfc/rfc9728` - OAuth 2.0 Protected Resource Metadata (April 2025).
- `https://www.rfc-editor.org/rfc/rfc8252.html` - OAuth 2.0 for Native Apps; browser-based best-practice posture and PKCE context.
- `https://datatracker.ietf.org/doc/html/rfc8628` - OAuth 2.0 Device Authorization Grant; useful as a secondary fallback, not the default Phase 19 path.
- `https://hexdocs.pm/oban/Oban.html` - durable Phoenix job/inspection posture aligned with explicit refresh jobs.
- `https://hexdocs.pm/req/Req.Request.html` - request/plugin layering model that informs profile/adapter design without replacing durable runtime truth.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scoria.Runtime.Params` already demonstrates the normalization seam Phase 19 should mirror: loose edge input at the boundary, one canonical internal shape before runtime code executes.
- `Scoria.Workflows` and `Scoria.Workflows.Run` already show Scoria’s preferred durable-truth pattern: explicit Ecto rows, transactional writes, and projection later.
- `Scoria.MCP.Router` already anchors MCP transport at the Plug boundary, which matches the locked product direction for remote connector work.
- `Scoria.MCP.Executor` already centralizes policy-sensitive audit, breaker, and budget behavior that future remote connector invocations must eventually reuse.
- `Scoria.Observe.Redactor` and `Scoria.SRE` already provide the evidence/redaction posture that grant and secret durability should align with.

### Established Patterns
- Scoria prefers one small public boundary over DSL-heavy product surfaces.
- Ecto rows are durable truth; telemetry, LiveView, and projections are observations of that truth.
- Security-sensitive runtime behavior is already expressed as explicit audit/budget/breaker seams instead of hidden middleware magic.
- The project repeatedly chooses boring defaults and shift-lefts low-impact decisions into GSD/planning rather than surfacing them to the user.

### Integration Points
- Phase 19 should add connector/auth rows in the same explicit Ecto style as existing workflow and audit schemas.
- Connector auth callbacks should live in Plug/Phoenix-facing boundaries and feed durable connector/grant rows rather than mutating transient UI state.
- Capability refresh should be durable work that can later surface in the LiveView operator UI without redefining truth in the UI layer.
- Future Phase 20 tool identity and policy checks should hang off these connector/grant/capability records rather than reverse-engineering remote servers at invocation time.

</code_context>

<deferred>
## Deferred Ideas

- Stable local tool identity mapping when remote catalogs drift - Phase 20.
- Dual-plane local-policy-plus-remote-scope enforcement - Phase 20.
- Workflow-owned approval on remote writes / exec / scope escalation - Phase 21.
- Full operator evidence UX for remote invocation lineage and approval review - Phase 21.
- Curated connector profile productization and boring install/verification defaults - Phase 22.
- Hosted connector-broker behavior, background polling as platform magic, or stateful remote session lifecycle as the default connector story.

</deferred>

---

*Phase: 19-remote-connector-boundary-and-auth-discovery*
*Context gathered: 2026-05-17*
