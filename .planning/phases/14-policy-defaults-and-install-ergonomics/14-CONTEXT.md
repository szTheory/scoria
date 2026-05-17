# Phase 14: Policy Defaults and Install Ergonomics - Context

**Gathered:** 2026-05-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Make provider, model, prompt-policy, and runtime defaults feel predictable and installable for a normal Phoenix app integration.

This phase productizes the default configuration and install path that sit on top of the Phase 12 identity model and the Phase 13 public runtime API. It does not broaden into full docs/example closeout, hosted prompt-management infrastructure, or optional knowledge-lane productization beyond keeping those edges explicit and non-surprising.

</domain>

<decisions>
## Implementation Decisions

### Application-facing policy configuration surface
- **D-01:** Scoria should expose one obvious application-facing default surface through `config :scoria, Scoria.Runtime, defaults: ...` for the normal Phoenix install path.
- **D-02:** The happy-path config must stay plain and boring: maps/keywords/struct-backed values, not a macro DSL, DB-first config system, or hidden runtime process.
- **D-03:** Host apps may attach identity-aware runtime policy composition through one explicit optional resolver module, configured separately from the baseline defaults.
- **D-04:** Per-run runtime options remain the final caller-controlled override layer on top of Scoria’s resolved defaults.

### Identity-aware default composition
- **D-05:** Scoria should resolve effective runtime defaults exactly once at the public runtime entrypoint, before workflow, MCP, telemetry, or audit code executes.
- **D-06:** Canonical root identity remains separate from runtime policy/config. Identity comes from explicit runtime identity input first, Phoenix adapters are edge sugar only, and root identity is immutable once the run starts.
- **D-07:** The precedence order for runtime policy/config fields should be: built-in Scoria defaults < app defaults < tenant defaults < actor defaults < per-run overrides.
- **D-08:** Governance-sensitive fields must not rely on merge order alone. If a per-run override attempts to widen a tenant/actor policy boundary, Scoria should validate and reject or narrow it explicitly.

### Prompt-policy shape
- **D-09:** Scoria should introduce one canonical prompt-policy noun, exposed as a small explicit `Scoria.PromptPolicy` struct.
- **D-10:** Preset atoms/strings and small maps may be accepted as boundary sugar, but they must normalize immediately into the canonical prompt-policy struct before runtime, audit, telemetry, or persistence code uses them.
- **D-11:** The prompt-policy struct should carry both stable identity and resolved governance data, including a policy key plus prompt reference/version and any grounding/tool/approval constraints needed for traceability.
- **D-12:** Module or behaviour-driven prompt-policy resolution may exist as an advanced adapter, but it must resolve into the canonical struct before execution and must not become the default host-app contract.

### Install and verification lane
- **D-13:** `mix scoria.install` should wire only the boring core Phoenix lane by default: router/dashboard mount, asset/tailwind path updates, baseline config scaffolding, and core migration guidance.
- **D-14:** The default install lane must not require pgvector, Docker, knowledge tables, retrieval/grounding enablement, or optional ecosystem integrations.
- **D-15:** The default verification story should declare success when a host app can run the core lane with normal Postgres, `mix ecto.migrate`, `mix test`, and a working `/scoria` route.
- **D-16:** Knowledge/retrieval verification remains a separate explicit lane with its own bootstrap and test commands. Core verification must not unexpectedly depend on it.

### DX posture and decision policy
- **D-17:** Scoria should follow a least-surprise Phoenix library posture: one obvious install path, one obvious config surface, deeper layers available only when needed.
- **D-18:** Effective provider/model/prompt-policy decisions must project into runtime metadata, telemetry, and audit evidence so operators can see why a run used a given configuration.
- **D-19:** Low-impact defaults and naming decisions in this area should be shifted left inside GSD and Scoria’s planning/implementation flows. User interruption should be reserved for materially consequential product-shape decisions only.

### the agent's Discretion
- Exact module naming between `Scoria.PromptPolicy`, `Scoria.Runtime.PromptPolicy`, or a similar public noun, provided there is one obvious canonical prompt-policy struct.
- Exact resolver callback naming and return shape, provided the host-app contract stays explicit and the precedence chain is stable and documented.
- Exact scaffolded config file location and installer output wording, provided the default lane remains additive, conservative, and legible.
- Exact storage shape for the resolved policy snapshot on runs or related evidence rows, provided operators can inspect the effective provider/model/prompt-policy after the fact.

</decisions>

<specifics>
## Specific Ideas

- The best default surface should feel closer to Oban or ReqLLM than to a magical hosted AI platform: application config for the boring path, optional deeper composition when needed.
- The policy surface should read like normal Phoenix code:
  - configure defaults once
  - optionally provide a resolver for tenant/actor-aware overlays
  - override per run only when necessary
- Prompt policy should not start as a full prompt-management product. It should start as one explicit runtime noun that is easy to audit, trace, and evolve later.
- The install story should explicitly teach two lanes:
  - core lane: runtime, workflows, approvals, operator UI
  - optional knowledge lane: pgvector-backed retrieval and grounding
- Good DX here means a host app can get to value without inventing policy precedence, without wiring hidden runtime magic, and without being forced into optional subsystems.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirement intent
- `.planning/ROADMAP.md` - Phase 14 goal, plan breakdown, and Keystone sequencing.
- `.planning/PROJECT.md` - embedded Phoenix-first product boundary and the requirement for boring install defaults.
- `.planning/REQUIREMENTS.md` - `POLY-01`, `POLY-02`, and `POLY-03`.
- `.planning/STATE.md` - current milestone posture plus the existing split between core and knowledge verification lanes.
- `.planning/MILESTONE-ARC.md` - why installability, public API clarity, and operator trust are the current leverage point.

### Prior phase context
- `.planning/phases/12-canonical-runtime-identity/12-CONTEXT.md` - canonical identity envelope, immutable root identity, and edge-adapter rules.
- `.planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md` - public runtime facade, explicit start/resume semantics, and the rule that low-impact defaults should be shifted left.
- `.planning/phases/13-public-runtime-api-and-session-lifecycle/13-RESEARCH.md` - runtime-layer reasoning that explicitly leaves broader policy/default composition and install ergonomics to Phase 14.

### Product and ecosystem guidance
- `prompts/scoria-gsd-kickoff.md` - batteries-included install vision and operator-first baseline.
- `prompts/phoenix-ai-lib-deep-research.md` - ecosystem lessons from Phoenix-native AI libraries and adjacent runtimes.
- `prompts/sztheory-elixir-dna.md` - batteries-included but composable defaults, Ecto-native durability, and zero-configuration onboarding.
- `prompts/scoria-brand-book-deep-research.md` - evidence-first, least-surprise product posture.
- `.planning/seeds/SEED-001-agentcore-lessons.md` - explicit identity and policy-backed runtime lessons.
- `.planning/research/milestone-options-2026-05-12.md` - argument for embedded defaults and runtime clarity before broader expansion.

### Current code surface
- `lib/scoria.ex` - current top-level public runtime facade.
- `lib/scoria/runtime.ex` - current public runtime lifecycle and inspection layer.
- `lib/scoria/runtime/params.ex` - current runtime normalization seam that should absorb default composition.
- `lib/scoria/identity.ex` - canonical identity normalization and edge-adapter pattern.
- `lib/scoria/workflows/runtime.ex` - root-identity and transient execution-context separation.
- `lib/scoria/mcp/executor.ex` - policy-sensitive execution seam where effective runtime defaults must stay coherent.
- `lib/scoria/sre/budget_engine.ex` - tenant-aware policy lookup and budgeting seam.
- `lib/scoria/sre/telemetry.ex` - telemetry projection path that should surface effective provider/model/policy decisions.
- `lib/mix/tasks/scoria.install.ex` - current installer baseline that Phase 14 should harden.
- `lib/mix/tasks/scoria.pgvector.bootstrap.ex` - explicit optional knowledge-lane bootstrap task.
- `lib/mix/tasks/scoria.test.knowledge.ex` - explicit optional knowledge verification lane.
- `test/mix/tasks/scoria.install_test.exs` - current installer behavior coverage.
- `test/scoria/bootstrap/migration_lane_compatibility_test.exs` - current core-vs-knowledge migration lane contract.
- `README.md` - current install story mismatch that later docs work must align with.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scoria.Runtime.Params` is already the right normalization seam for start/resume contracts and should become the place where effective runtime defaults are resolved once.
- `Scoria.Identity` already demonstrates the pattern Scoria wants here: loose edge input is acceptable, but durable/runtime code uses one canonical normalized noun.
- The SRE and MCP seams already carry `provider`, `model`, `policy_key`, and identity fields through execution and telemetry, which makes them ready consumers of a resolved default policy surface.
- The existing installer, installer test, and migration-lane compatibility test already provide a concrete base for hardening the boring core lane without inventing a new onboarding system.

### Established Patterns
- Scoria favors small explicit runtime nouns over bags of attrs and hidden framework state.
- Durable truth lives in Ecto rows; telemetry and LiveView are projections of that truth.
- The repo already distinguishes a default core lane from the optional knowledge lane. Phase 14 should preserve and formalize that distinction rather than blur it.
- The product direction is embedded and Phoenix-first, not hosted-platform-first. Config and install should feel like a normal library integration, not a managed control plane.

### Integration Points
- Public runtime start should resolve effective defaults once, stamp the chosen policy/provider/model into durable run metadata, and pass the same resolved shape into workflow, MCP, SRE, and telemetry paths.
- The optional resolver module should take canonical identity plus runtime input and return overlay config without mutating root identity.
- Installer hardening should connect router/assets/config/migrations into one obvious core lane while leaving pgvector and knowledge work in explicit secondary tasks.

</code_context>

<deferred>
## Deferred Ideas

- Hosted or remote prompt-management infrastructure as the default Scoria prompt-policy story.
- DB-backed or dashboard-managed runtime default editing as the primary configuration path for Phase 14.
- Full docs/example closeout work, including end-to-end integration walkthroughs, which belongs to Phase 15.
- Productizing the optional knowledge lane as part of the default install success path.
- Broader ecosystem integrations such as Sigra/Threadline/Parapet-specific installers or hard dependencies.

</deferred>

---

*Phase: 14-policy-defaults-and-install-ergonomics*
*Context gathered: 2026-05-14*
