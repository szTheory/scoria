# Phase 22: Curated Connector Profiles and Boring Adoption Path - Research

**Researched:** 2026-05-18
**Domain:** Elixir/Phoenix Operator UX, Profile-driven Configuration
**Confidence:** HIGH

## Summary

Phase 22 productizes Scoria's remote connector adoption by introducing a very thin curated profile layer. This layer normalizes common connector configurations (e.g., GitHub, generic stateless endpoints) into the existing Ecto-backed runtime boundary (`Scoria.register_connector/1`). The primary objective is to streamline the adoption of MCP connectors with sensible defaults (stateless-first, `streamable_http`, OAuth/PKCE) without introducing a secondary configuration system or marketplace model. The solution leverages existing tools like Phoenix LiveDashboard and `mix scoria.install`, reinforcing a boring, predictable setup that normal Phoenix developers expect. 

**Primary recommendation:** Introduce a `Scoria.Connectors.Profiles` module to act as a pure data-transformation layer, turning profile atoms (`:github`, `:generic`) into explicit Ecto attributes for `Scoria.register_connector/1`, ensuring a single source of runtime truth.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Connector Profile Resolution | API / Backend | — | Transforms curated atoms (e.g., `:github`) into normalized registration parameters. |
| Connector Registration Truth | Database / Storage | API / Backend | Ecto rows remain the absolute source of truth for connector state, avoiding "split brain" with static configs. |
| Adoption Verification | Test Framework | — | `mix test.adoption` provides executable proof of the wiring, rather than relying on docs. |

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Curated connector profiles should remain thin Scoria-owned data/default layers that normalize into the existing connector registration boundary. They must not become a second source of runtime truth.
- **D-02:** The profile layer should own: boring transport/auth defaults, recommended minimum scope posture, default tool-adoption posture and risk hints, verification hints/examples for the recommended lane.
- **D-03:** The profile layer should not own stable local tool identity, approval truth, connector health truth, or operator IA. Those remain runtime/evidence concerns established in Phases 19-21.
- **D-04:** Curated profile naming may help adoption, but profile-owned canonical naming must not displace the durable local-tool identity model from Phase 20.
- **D-05:** Verification hints must be derived from checked runtime helpers/tests, not maintained as hand-written prose detached from executable truth.
- **D-06:** `Scoria.register_connector/1` remains the only durable write boundary for connector registration and update truth.
- **D-07:** Phase 22 should add one thin profile-first helper for curated adoption, but that helper must expand into normalized attrs and call the same underlying registration boundary rather than introducing a second truth system.
- **D-08:** `mix scoria.install` should stay responsible only for host-app baseline wiring and verification scaffolding, not for owning live connector runtime state.
- **D-09:** The recommended adoption story should be layered: install the baseline Phoenix lane -> choose a curated profile -> register a connector through the runtime boundary -> sync/discover it explicitly -> verify the resulting connector/tool/operator truth.
- **D-10:** Install-time generation must not be the primary place where connector behavior, scopes, or durable grant state are defined. Those belong to runtime-owned Ecto truth.
- **D-11:** Phase 22 should ship exactly two public profiles: `generic` as the boring default remote `streamable_http` / stateless-first profile, and one named exemplar profile.
- **D-12:** The named exemplar should represent the safest common connector class for Scoria's product thesis: OAuth/PKCE-friendly, explicit scopes, stateless HTTP, clear permission-upgrade semantics, no browser/code-exec or session-heavy behavior.
- **D-13:** A GitHub-class connector is the strongest first exemplar because its permission and upgrade semantics align well with Scoria's dual-plane policy, evidence, and explicit-adoption posture.
- **D-14:** Phase 22 must not ship several named profiles or anything that implies a connector marketplace posture.
- **D-15:** The default remote-connector proof must remain in the same shape as Keystone's adoption contract: docs for the human walkthrough, `mix test.adoption` as the named default proof lane, one narrow connector-specific executable proof inside that lane.
- **D-16:** The connector-specific proof should register one curated stateless profile, run discovery/sync against a stubbed remote endpoint, assert durable connector/grant/capability truth, and assert the operator surface reflects the same truth.
- **D-17:** The default verification contract must not depend on a live third-party account, a hosted smoke environment, or browser-heavy E2E infrastructure.
- **D-18:** A dedicated connector-only public verification lane is not the default Phase 22 posture.
- **D-19:** The documented success definition for the boring remote path should be: connector registered, explicit sync/discovery succeeded, expected profile/tool state is visible durably, the operator page agrees with that same runtime truth.
- **D-20:** Low-impact connector-adoption decisions should be shifted left into Scoria defaults, curated profiles, and future GSD planning assumptions wherever possible.
- **D-21:** The following should be shifted left by default: `streamable_http` as the boring transport, stateless-first invocation posture, OAuth/PKCE redirect posture where auth is needed, discovery/protected-resource metadata handling, least-privilege scope recommendations, redaction, health, refresh, and verification defaults, profile-to-attrs normalization, default auth/scope failure copy and guidance, docs/examples for the recommended path.
- **D-22:** User interruption should be reserved for materially consequential choices only: explicit scope widening or optional-scope opt-in, endpoint selection and tenant scoping, stateful-session enablement, adoption of newly discovered risky tools, app-specific policy overrides with real blast-radius implications.
- **D-23:** This shift-left posture should also inform downstream GSD planning for this phase: unless a decision changes Scoria's product shape or blast radius, prefer the Scoria-recommended default over re-asking.

### the agent's Discretion
- Exact helper/API naming for the profile-first adoption surface, provided it remains thin and subordinate to `Scoria.register_connector/1`.
- Exact profile data structure, provided it remains plain curated config/normalization input and not a second runtime truth model.
- Exact choice of the first named exemplar connector, provided it fits the GitHub-class posture above and preserves the small curated set.
- Exact test file and docs layout for the connector-specific executable proof, provided it stays inside the default adoption lane and remains stubbed/stateless-first.

### Deferred Ideas (OUT OF SCOPE)
- A broader connector catalog or marketplace-style profile set.
- Profile-owned runtime identity or approval logic.
- Install-time generated connector state as the primary remote-adoption surface.
- Live-provider certification smoke tests as the default public proof path.
- Browser/code-exec or session-heavy exemplar connectors in this phase.
- Hosted connector trust claims or registry-like positioning.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DX-01 | Scoria ships a small curated connector/profile layer for common remote-tool adoption paths without becoming a connector marketplace. | Addressed via `Scoria.Connectors.Profiles` yielding normalized map attributes for exactly two profiles (`:generic` and `:github`). |
| DX-02 | The default install and verification path for remote connectors stays boring for an ordinary Phoenix app integration. | Addressed via extending `mix test.adoption` to include `ProfilesTest` that relies on `Req.Test` HTTP stubbing. |
</phase_requirements>

## Project Constraints (from GEMINI.md)
- **Ash Framework:** Do not attempt to integrate with or use the Ash framework. We are strictly all-in on standard Phoenix and Ecto architectures.
- **Deep Recommendations:** Provide deep, cohesive, one-shot recommendations. Include pros/cons/tradeoffs with examples, what is idiomatic for the current tech stack, and emphasize developer ergonomics, principle of least surprise, and great UI/UX.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | 1.15+ | Runtime | Base language constraint |
| Phoenix | 1.7+ | Web Framework | Native host environment, LiveView UI integration |
| Ecto | 3.10+ | Database Wrapper | Sole source of connector truth (no static state or Ash) |
| Req | ~> 0.4.0 | HTTP Client & Testing | Idiomatic HTTP interaction, explicit stubbing via `Req.Test` |

## Architecture Patterns

### Recommended Project Structure
```text
lib/scoria/connectors/
├── params.ex         # Base attribute validation & canonicalization
├── profiles.ex       # Profile transformation logic (New)
└── discovery.ex      # Existing discovery job enqueue logic

test/scoria/connectors/
├── profiles_test.exs # Verifies profile-to-attr expansion (New)
```

### Pattern 1: Profile Normalization Pipeline
**What:** Transforming a high-level profile identifier (e.g., `:github`) into an explicit, Ecto-ready attributes map.
**When to use:** Whenever a user attempts to register a connector via a profile.
**Example:**
```elixir
defmodule Scoria.Connectors.Profiles do
  @moduledoc """
  Provides curated default templates for standard connector classes.
  These expand into Ecto attributes for `Scoria.register_connector/1`.
  """

  @profiles %{
    generic: %{
      transport_kind: "streamable_http",
      auth_mode: "none",
      # ... defaults
    },
    github: %{
      transport_kind: "streamable_http",
      auth_mode: "oauth_pkce",
      discovery_metadata_url: "https://api.github.com/.well-known/oauth-authorization-server",
      # ... minimal safe defaults
    }
  }

  def build_attrs(profile_name, overrides \\ %{}) do
    base = Map.get(@profiles, profile_name) || raise ArgumentError, "Unknown profile: #{profile_name}"
    
    # Deep merge overrides into the curated defaults
    Map.merge(base, overrides, fn _k, v1, v2 -> if is_map(v1) and is_map(v2), do: Map.merge(v1, v2), else: v2 end)
  end
end
```

### Pattern 2: Stubbed Executable Proofs via Req.Test
**What:** Using `Req.Test` to intercept and mock the connector discovery and sync endpoints during `mix test.adoption`.
**When to use:** In the automated verification lane (`test.adoption`) where we cannot rely on live, third-party internet access.
**Example:**
```elixir
test "GitHub profile registration provisions expected scope and triggers discovery" do
  Req.Test.stub(Scoria.Connectors.Discovery, fn conn ->
    Req.Test.json(conn, %{
      "catalog" => %{"tools" => [%{"name" => "issues.list"}]}
    })
  end)

  attrs = Scoria.Connectors.Profiles.build_attrs(:github, %{tenant_id: "test", key: "gh-1"})
  assert {:ok, connector} = Scoria.register_connector(attrs)
  
  # Ensure the discovery job was enqueued
  assert_enqueued(worker: Scoria.Connectors.DiscoveryJob, args: %{"connector_id" => connector.id})
end
```

### Anti-Patterns to Avoid
- **Split Brain Config:** Do NOT try to read the connector configuration exclusively from `config.exs` at runtime. All connector identities, states, and authorizations must live in Ecto.
- **Marketplace Proliferation:** Do NOT introduce an extensible module behavior or plugin system for profiles. The list of profiles should be hardcoded to `:generic` and `:github`.
- **Live Provider Testing:** Do NOT hit real GitHub API endpoints in standard tests. All HTTP requests in `mix test.adoption` MUST be intercepted.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HTTP Stubbing | Mock libraries (e.g., Mox for HTTP), Custom bypass plugs | `Req.Test` | Provides standard, robust request/response assertions specifically designed for Elixir's idiomatic HTTP client. |
| Connector Persistence | Static config files, Application env | `Ecto.Repo` | Connectors have a lifecycle (sync status, last refresh, health checks) that demands durable transactional storage. |

## Common Pitfalls

### Pitfall 1: Bypassing the Existing Registration Pipeline
**What goes wrong:** The new profile helper registers directly to Ecto, bypassing `Scoria.Connectors.register_connector/1` logic.
**Why it happens:** Attempting to build a "shortcut" for adoption.
**How to avoid:** Ensure `Profiles.build_attrs/2` ONLY returns a map. The caller then passes that map into the exact same `register_connector` boundary as before.

### Pitfall 2: Over-Promising in Installer Tasks
**What goes wrong:** `mix scoria.install` attempts to register the remote connectors.
**Why it happens:** Trying to make the initial command "do everything."
**How to avoid:** Installer tasks should only verify base schema and provide docs. Live connector provisioning happens via runtime logic or test setups, keeping the installer side-effect free concerning third-party states.

## Code Examples

### Connector Registration with Curated Profile
```elixir
# In application bootstrap, setup, or an explicit admin task:
attrs = Scoria.Connectors.Profiles.build_attrs(:github, %{
  tenant_id: "acme_corp",
  key: "github_prod",
  endpoint_url: "https://api.github.com/mcp"
})

case Scoria.register_connector(attrs) do
  {:ok, connector} -> 
    Logger.info("GitHub Connector registered: #{connector.id}")
  {:error, changeset} ->
    Logger.error("Failed to register: #{inspect(changeset.errors)}")
end
```

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test_helper.exs` / `mix.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test.adoption` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DX-01 | Registering a curated profile transforms data properly | unit | `mix test test/scoria/connectors/profiles_test.exs` | ❌ Phase 22 |
| DX-02 | Verifying the GitHub profile triggers sync against a stub | integration | `mix test test/scoria/connectors/profiles_test.exs` | ❌ Phase 22 |

### Wave 0 Gaps
- [ ] `test/scoria/connectors/profiles_test.exs` — covers DX-01, DX-02 profile normalization and mock sync integration.
- [ ] `lib/scoria/connectors/profiles.ex` — implementation of the normalization layer.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hand-rolling full `attrs` | Using `Profiles.build_attrs(:github)` | Phase 22 | Lowers adoption barrier without compromising runtime truth. |
| Ad-hoc testing | `Req.Test` stubbing in `mix test.adoption` | Phase 22 | Predictable, offline-capable verification of complex flows. |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/22-curated-connector-profiles-and-boring-adoption-path/22-CONTEXT.md` - Explicit instruction constraints and bounded context.
- `.planning/phases/22-curated-connector-profiles-and-boring-adoption-path/22-PATTERNS.md` - Existing mapping and data transformation logic.
- `.planning/REQUIREMENTS.md` - Milestone and feature requirements (DX-01, DX-02).
- `GEMINI.md` - Project-level constraints (Phoenix + Ecto, NO Ash).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Directly follows Phoenix and existing project norms.
- Architecture: HIGH - Dictated strongly by the Phase Context constraints.
- Pitfalls: HIGH - Addresses direct anti-patterns highlighted in project guidelines.

**Research date:** 2026-05-18
**Valid until:** 2026-06-18
