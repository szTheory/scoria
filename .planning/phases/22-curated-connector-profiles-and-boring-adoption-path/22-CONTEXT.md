# Phase 22: Curated Connector Profiles and Boring Adoption Path - Context

**Gathered:** 2026-05-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Productize Scoria's remote connector adoption path with a very small curated profile layer and a boring default install/verification experience for normal Phoenix apps.

This phase should make the remote connector story easier to adopt without changing the runtime truth model established in Phases 19-21. Connector rows, grants, capability snapshots, local tools, approvals, and evidence remain the durable source of truth. Phase 22 adds curated adoption sugar, a tighter default happy path, and executable proof that the recommended connector lane is wired correctly. It does not broaden into a marketplace, hosted connector catalog, browser/code-exec productization, or a second runtime authority layered on top of connector truth.

</domain>

<decisions>
## Implementation Decisions

### Curated profile boundary
- **D-01:** Curated connector profiles should remain thin Scoria-owned data/default layers that normalize into the existing connector registration boundary. They must not become a second source of runtime truth.
- **D-02:** The profile layer should own:
  - boring transport/auth defaults
  - recommended minimum scope posture
  - default tool-adoption posture and risk hints
  - verification hints/examples for the recommended lane
- **D-03:** The profile layer should not own stable local tool identity, approval truth, connector health truth, or operator IA. Those remain runtime/evidence concerns established in Phases 19-21.
- **D-04:** Curated profile naming may help adoption, but profile-owned canonical naming must not displace the durable local-tool identity model from Phase 20.
- **D-05:** Verification hints must be derived from checked runtime helpers/tests, not maintained as hand-written prose detached from executable truth.

### Adoption surface
- **D-06:** `Scoria.register_connector/1` remains the only durable write boundary for connector registration and update truth.
- **D-07:** Phase 22 should add one thin profile-first helper for curated adoption, but that helper must expand into normalized attrs and call the same underlying registration boundary rather than introducing a second truth system.
- **D-08:** `mix scoria.install` should stay responsible only for host-app baseline wiring and verification scaffolding, not for owning live connector runtime state.
- **D-09:** The recommended adoption story should be layered:
  - install the baseline Phoenix lane
  - choose a curated profile
  - register a connector through the runtime boundary
  - sync/discover it explicitly
  - verify the resulting connector/tool/operator truth
- **D-10:** Install-time generation must not be the primary place where connector behavior, scopes, or durable grant state are defined. Those belong to runtime-owned Ecto truth.

### Curated set size and profile catalog posture
- **D-11:** Phase 22 should ship exactly two public profiles:
  - `generic` as the boring default remote `streamable_http` / stateless-first profile
  - one named exemplar profile
- **D-12:** The named exemplar should represent the safest common connector class for Scoria's product thesis:
  - OAuth/PKCE-friendly
  - explicit scopes
  - stateless HTTP
  - clear permission-upgrade semantics
  - no browser/code-exec or session-heavy behavior
- **D-13:** A GitHub-class connector is the strongest first exemplar because its permission and upgrade semantics align well with Scoria's dual-plane policy, evidence, and explicit-adoption posture.
- **D-14:** Phase 22 must not ship several named profiles or anything that implies a connector marketplace posture. The goal is to teach one real connector well, not to suggest Scoria is becoming the place where connectors live.

### Verification contract
- **D-15:** The default remote-connector proof must remain in the same shape as Keystone's adoption contract:
  - docs for the human walkthrough
  - `mix test.adoption` as the named default proof lane
  - one narrow connector-specific executable proof inside that lane
- **D-16:** The connector-specific proof should register one curated stateless profile, run discovery/sync against a stubbed remote endpoint, assert durable connector/grant/capability truth, and assert the operator surface reflects the same truth.
- **D-17:** The default verification contract must not depend on a live third-party account, a hosted smoke environment, or browser-heavy E2E infrastructure.
- **D-18:** A dedicated connector-only public verification lane is not the default Phase 22 posture. If live-provider certification smokes are added later, they should be maintainer-oriented and non-default.
- **D-19:** The documented success definition for the boring remote path should be:
  - connector registered
  - explicit sync/discovery succeeded
  - expected profile/tool state is visible durably
  - the operator page agrees with that same runtime truth

### Shift-left defaults and user interruption policy
- **D-20:** Low-impact connector-adoption decisions should be shifted left into Scoria defaults, curated profiles, and future GSD planning assumptions wherever possible.
- **D-21:** The following should be shifted left by default:
  - `streamable_http` as the boring transport
  - stateless-first invocation posture
  - OAuth/PKCE redirect posture where auth is needed
  - discovery/protected-resource metadata handling
  - least-privilege scope recommendations
  - redaction, health, refresh, and verification defaults
  - profile-to-attrs normalization
  - default auth/scope failure copy and guidance
  - docs/examples for the recommended path
- **D-22:** User interruption should be reserved for materially consequential choices only:
  - explicit scope widening or optional-scope opt-in
  - endpoint selection and tenant scoping
  - stateful-session enablement
  - adoption of newly discovered risky tools
  - app-specific policy overrides with real blast-radius implications
- **D-23:** This shift-left posture should also inform downstream GSD planning for this phase: unless a decision changes Scoria's product shape or blast radius, prefer the Scoria-recommended default over re-asking.

### the agent's Discretion
- Exact helper/API naming for the profile-first adoption surface, provided it remains thin and subordinate to `Scoria.register_connector/1`.
- Exact profile data structure, provided it remains plain curated config/normalization input and not a second runtime truth model.
- Exact choice of the first named exemplar connector, provided it fits the GitHub-class posture above and preserves the small curated set.
- Exact test file and docs layout for the connector-specific executable proof, provided it stays inside the default adoption lane and remains stubbed/stateless-first.

</decisions>

<specifics>
## Specific Ideas

- The coherent Phase 22 product shape is:
  - one real runtime truth boundary
  - one thin curated helper layer
  - two public profiles total
  - one boring proof lane for remote connectors
- The right mental model is closer to `Req`, `Oban`, and Phoenix LiveDashboard than to a hosted connector catalog:
  - explicit runtime boundary
  - curated happy-path sugar
  - durable Ecto truth
  - embedded operator evidence
- The best named exemplar is a GitHub-class connector, not because Scoria should become GitHub-specific, but because the permission and upgrade model teaches the exact behaviors Scoria wants users to internalize:
  - explicit scopes
  - visible permission widening
  - stable existing power
  - stateless request flow
- The main footguns to avoid are:
  - profiles becoming runtime truth
  - install-time static config pretending to be live connector state
  - a profile catalog that reads like a marketplace
  - verification that needs a real third-party account
  - docs/examples that drift from executable truth

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirement intent
- `.planning/ROADMAP.md` - Phase 22 goal, success criteria, and dependency on Phase 21.
- `.planning/PROJECT.md` - embedded Phoenix-first product boundary and current Switchyard thesis.
- `.planning/REQUIREMENTS.md` - `DX-01` and `DX-02`.
- `.planning/STATE.md` - current milestone posture and active sequencing context.
- `.planning/MILESTONE-ARC.md` - why remote connector productization is the current leverage point.
- `.planning/research/v1.5-switchyard-recommendation.md` - active recommendation synthesis for Switchyard defaults.

### Prior locked Scoria decisions
- `.planning/phases/14-policy-defaults-and-install-ergonomics/14-CONTEXT.md` - boring install defaults and shift-left posture.
- `.planning/phases/15-adoption-surface-docs-and-example-flow/15-CONTEXT.md` - one obvious adoption path and verification-story posture.
- `.planning/phases/18-add-executable-adoption-flow-guards/18-CONTEXT.md` - executable adoption guard philosophy and default-lane verification.
- `.planning/phases/19-remote-connector-boundary-and-auth-discovery/19-CONTEXT.md` - profiles as defaults, not runtime truth; explicit discovery/auth boundary.
- `.planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md` - stable local-tool identity, stateless-first invocation, and fail-closed policy posture.
- `.planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md` - operator evidence posture and embedded dashboard expectations.

### Product and architecture guidance
- `prompts/scoria-gsd-kickoff.md` - batteries-included Phoenix AI ops framing.
- `prompts/phoenix-ai-lib-deep-research.md` - ecosystem lessons from Phoenix-native and adjacent AI/runtime libraries.
- `prompts/scoria-brand-book-deep-research.md` - calm, operator-grade, anti-marketplace product posture.
- `prompts/sztheory-elixir-dna.md` - batteries-included but composable, Ecto-native, embedded LiveView dashboard rules.
- `.planning/research/mcp-and-tools.md` - MCP/tool governance research already shaping Scoria.
- `.planning/research/liveview-operator-ux.md` - operator-surface posture for embedded Phoenix apps.

### Current code surface
- `lib/scoria.ex` - top-level public facade including the current connector boundary.
- `lib/scoria/connectors.ex` - durable connector registration/update/sync boundary.
- `lib/scoria/connectors/params.ex` - current profile/default normalization seam.
- `lib/mix/tasks/scoria.install.ex` - baseline install surface and next-step messaging.
- `lib/mix/tasks/test.adoption.ex` - default adoption proof lane.
- `docs/operator_verification.md` - current human verification guide.
- `test/scoria/adoption_surface_test.exs` - docs/public-surface guard posture.
- `test/scoria/runtime_integration_test.exs` - strongest existing runtime/operator proof seam.
- `test/mix/tasks/scoria.install_test.exs` - installer mutation/idempotence seam.
- `test/mix/tasks/scoria.install_route_smoke_test.exs` - mounted route proof seam.

### External standards and adjacent-system guidance
- `https://modelcontextprotocol.io/specification/2025-06-18/basic/authorization` - current MCP authorization requirements, PKCE posture, and resource-audience guidance.
- `https://modelcontextprotocol.io/docs/tutorials/security/authorization` - practical MCP auth flow guidance.
- `https://hexdocs.pm/req/Req.Request.html` - high-level API over explicit request substrate; plugin/step layering posture.
- `https://hexdocs.pm/req/Req.Test.html` - repo-native HTTP stubbing/testing posture suitable for connector verification.
- `https://hexdocs.pm/oban/installation.html` - install task plus explicit runtime configuration layering.
- `https://hexdocs.pm/oban/testing.html` - normal test-lane posture for durable background work.
- `https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.Router.html` - embedded mounted operator-surface pattern.
- `https://docs.github.com/en/apps/using-github-apps/authorizing-github-apps` - dual-plane app/user authorization posture.
- `https://docs.github.com/en/enterprise-cloud@latest/apps/using-github-apps/approving-updated-permissions-for-a-github-app` - explicit permission-widening review flow.
- `https://docs.slack.dev/authentication/installing-with-oauth/` - least-privilege scope request posture and additive scope behavior.
- `https://docs.slack.dev/changelog/2026/03/16/optional-scopes/` - optional-scope handling and graceful degradation guidance.
- `https://docs.langchain.com/oss/python/langgraph/interrupts` - durable interrupt/resume posture and persistence-first approval semantics.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scoria.Connectors.Params` already provides the right seam for a thin curated profile layer: profile defaults normalize into explicit connector attrs before durable writes.
- `Scoria.Connectors` already provides the durable runtime boundary that Phase 22 should preserve rather than bypass.
- `mix scoria.install` and `mix test.adoption` already establish the boring install-and-proof shape that remote connectors should extend instead of replacing.
- Existing adoption, runtime integration, and installer tests already give Scoria a Phoenix-native executable verification lane to build on.

### Established Patterns
- Scoria consistently keeps one explicit public/runtime boundary and treats sugar as subordinate to that boundary.
- Durable truth lives in Ecto rows; operator UI and docs are projections or guides over that truth.
- The repo prefers one boring default lane with optional deeper lanes, rather than a matrix of parallel onboarding surfaces.
- Prior phases repeatedly shifted low-impact defaults left and reserved human interruption for real blast-radius decisions.

### Integration Points
- The curated profile layer should sit directly on top of `Scoria.Connectors.Params` and `Scoria.register_connector/1`.
- The named exemplar profile should feed the same discovery/auth/grant/sync lifecycle as any generic connector row.
- The connector-specific proof should extend `mix test.adoption`, use repo-native HTTP stubbing, and connect back to the operator evidence surface.
- Docs and helper APIs should point back to the same runtime truth and proof lane instead of inventing separate success definitions.

</code_context>

<deferred>
## Deferred Ideas

- A broader connector catalog or marketplace-style profile set.
- Profile-owned runtime identity or approval logic.
- Install-time generated connector state as the primary remote-adoption surface.
- Live-provider certification smoke tests as the default public proof path.
- Browser/code-exec or session-heavy exemplar connectors in this phase.
- Hosted connector trust claims or registry-like positioning.

</deferred>

---

*Phase: 22-curated-connector-profiles-and-boring-adoption-path*
*Context gathered: 2026-05-18*
