# Phase 47: README First-Screen Positioning and Scope Doctrine - Research

**Researched:** 2026-07-10
**Domain:** Adopter documentation positioning, scope doctrine, comparison guide, and docs contract tests
**Confidence:** HIGH for repo scope and validation targets; MEDIUM for external LLM-ops comparison claims

<user_constraints>
## User Constraints (from CONTEXT.md)

Source: `.planning/phases/47-readme-first-screen-positioning-and-scope-doctrine/47-CONTEXT.md` [VERIFIED: codebase grep].

### Locked Decisions

Hard constraints carried forward:

- Phase 46 locked the public vocabulary: reviewer, trace, capabilities, verification suite,
  scoped context, semantic cache, and optional knowledge base.
- The P1-P6 scope doctrine is locked in `.planning/PROJECT.md`, but adopter docs should
  translate it into concrete product boundaries rather than expose planning labels first.
- Brandbook copy is useful, but newer SEED-005/Phase 46 terminology overrides older
  `operator` language in prompt and brandbook artifacts.
- Scoria's comparison posture must be honest: embedded Phoenix governance, host Postgres/Ecto,
  `/scoria`, in-path gates, and zero required egress for Scoria governance records are real;
  warehouse-scale analytics, broad cross-language SDK maturity, prompt playground depth, and
  mature external observability ecosystems are ceded strengths.

### D-01 - README first screen: plain-English embedded Phoenix front door

Use the plain-English SEED-005 front door, not the current capability-ladder-first shape.
README must open, after logo/tagline/badges, with one paragraph that says:

> Scoria is an Elixir/Phoenix library you add to an existing Phoenix app to run AI/LLM
> work durably and inspectably. Every run - one execution such as a prompt render, model
> call, tool call, retrieval, approval, or eval score - is recorded as a queryable
> Postgres/Ecto trace. A mounted LiveView dashboard at `/scoria` lets a human reviewer
> inspect, debug, approve, and resume that work. Scoria runs inside your app's BEAM and
> database boundary; it is not a hosted SaaS agent platform.

Do not introduce capabilities, verification suites, or internal milestone vocabulary before
this paragraph. Those concepts can appear after the adopter knows the product category and
boundary.

Rejected alternatives:

- **Refined capability ladder first:** smallest diff, but still asks adopters to understand
  coined taxonomy before the product category.
- **Code/quickstart first:** familiar for small libraries, but Scoria's trust boundary is the
  product. Code first makes it look like another LLM client.
- **Competitor comparison first:** strong differentiation, but defensive and stale-prone.

### D-02 - README first-screen order

Use this public README order:

1. Brand mark, `# Scoria`, tagline, badges.
2. Plain-English "what this is" paragraph from D-01.
3. Short "who this is for" paragraph using n=1 roles-not-headcount language.
4. Short "not for" line or compact boundary list.
5. Link or compact preview of "What Scoria owns vs what your app owns."
6. Only then: capability ladder, install, quickstart, verification suites.

This keeps the first screen adopter-focused and moves backend/source-of-truth details into
tables or guide sections where they help rather than overwhelm.

### D-03 - Scope doctrine table: adopter-readable owns-vs-delegates rows

Do not show P1-P6 labels as the main public table. Use an adopter-readable table with this
schema:

| Boundary | Scoria owns | Your Phoenix app owns | Why this boundary exists | Example / verification |
|----------|-------------|-----------------------|--------------------------|------------------------|

Recommended row set:

- **Run records and traces** - Scoria owns durable run records, trace projection, exact
  `run_id` readback, and reviewer inspection. The host owns ticket/order/customer/domain
  truth and references it by host IDs.
- **Reviewer dashboard scope** - Scoria owns `/scoria`, the dashboard scope seam, and
  trusted scope reads. The host owns authentication, authorization, tenant membership, and
  role values.
- **Governance gates** - Scoria owns approval, budget, breaker, eval-gate, and tool-policy
  mechanisms. The host owns thresholds, policy values, escalation rules, and business risk
  interpretation.
- **Eval and release proof** - Scoria owns scorer execution, persisted score evidence,
  fail-closed verdict posture, and verification-suite commands. The host owns prompts,
  product success definitions, expected outputs, and release intent.
- **Knowledge retrieval and grounding** - Scoria owns tenant-scoped retrieval filtering,
  citation validation, grounding checks, and persisted evidence. The host owns the corpus,
  business meaning, metadata semantics, and end-user answer surface.
- **Bounded handoff scoped context** - Scoria owns same-run handoff records, scoped-context
  validation, and delegated lineage readback. The host owns which facts may be passed and
  which role should receive them.
- **Remote connectors and tools** - Scoria owns registration, grants, health state, trace
  evidence, and approval pauses. The host owns which tools exist, what credentials mean,
  and whether a side effect is allowed in its product.
- **Phoenix/BEAM infrastructure** - Scoria owns library defaults, Ecto migrations,
  Telemetry/PubSub/Oban-friendly integration points, and dashboard assets. The host owns
  deployment topology, repo config, secrets, app supervision, and non-Scoria UI.

Keep the table copy concrete. Avoid backend guts unless the detail is needed to explain a
fundamental boundary, such as authz delegation or host-owned policy values.

### D-04 - Persona framing: roles, not headcount

State that the reviewer is a role, not a department. The default reader is the smallest
viable Phoenix team: one engineer may wear AI/product, platform, SRE, prompt, eval, and
reviewer hats. The docs should degrade gracefully to a few people, but never imply that a
dedicated ML platform, Trust and Safety, or compliance team is required.

Recommended README/guide wording:

> Scoria is for Phoenix teams where one engineer may need to ship prompts, inspect runs,
> approve risky tool calls, run evals, and debug incidents without adopting a separate
> hosted control plane.

Add a compact audience boundary after the opening:

- **Core:** Phoenix AI/product engineers, backend/platform engineers, SRE/devops hats,
  reviewers/approvers, prompt writers, eval checkers, and MCP/workflow configurators.
- **Adjacent:** security, privacy/legal, Trust and Safety, domain experts, PMs, and support
  teams consume hooks, docs, exported proof, or review outputs, but are not the first
  dedicated Scoria surface in this phase.
- **Not Scoria's surface:** end users of host AI flows, host product designers, finance or
  executive dashboards, a general data warehouse, and host auth/policy administration.

### D-05 - Hosted/external LLM-ops comparison: hybrid framing

Use a hybrid comparison:

- README stays category-level: Scoria is embedded Phoenix governance, not a hosted or
  external LLM-ops control plane.
- A stable comparison guide names common peers in a source-linked section: LangSmith,
  Langfuse, Braintrust, and Arize Phoenix.
- The guide title should avoid inaccurate shorthand such as "hosted-only tools." Prefer
  **Scoria vs external LLM-ops platforms** or **Scoria vs hosted and external LLM-ops**.

Safe claims now:

- Scoria runs inside the host Phoenix app.
- Scoria records its governance/runtime data in the host's Postgres/Ecto boundary.
- Scoria ships an embedded LiveView reviewer dashboard at `/scoria`.
- Scoria delegates identity, authorization, role values, and business truth to the host.
- Scoria supports durable runs, reviewer-visible traces, approvals, fail-closed eval posture,
  tenant-scoped knowledge retrieval, and upgrade-safe verification suites.
- Scoria requires no separate Scoria-hosted control plane and no required egress for Scoria
  governance records beyond whatever model/tool providers the host app already calls.

Ceded strengths:

- External platforms may be better when the team needs cross-language SDK coverage, managed
  warehouse-scale analytics, hosted dashboards across many services, mature prompt
  playgrounds, broad team collaboration around evals, or non-Phoenix stacks.

Deferred or forbidden claims:

- Do not claim OpenInference-compatible export until SEED-007 ships.
- Do not claim Rule-of-Two/lethal-trifecta enforcement until SEED-010 ships.
- Do not claim mature scorer calibration or regression depth beyond current fail-closed
  posture until SEED-008 ships.
- Do not claim deep retrieval eval/rerank/faithfulness metrics until SEED-009 ships.
- Do not claim full retention, masking, purge, or feedback governance until SEED-011 ships.
- Do not call all peers "hosted SaaS"; several official docs describe self-hosted, hybrid,
  local, or open-source options.
- Always write **Arize Phoenix** when referring to the LLM-ops tool to avoid confusion with
  the Phoenix web framework.

### D-06 - Version and install fallback cleanup

Phase 47 should clean stale README version references that currently conflict with the live
release baseline:

- README GitHub fallback example must not point at `v0.1.1`.
- README status must not say current release is `0.1.1`.
- Current released Hex baseline is `0.1.2`; `0.1.3` is the target release cut owned by
  Phase 50.
- Prefer Hex-primary install guidance. GitHub fallback should be framed as fork/pinned-patch
  guidance, not a recommended release path.

Docs/maintainer release-command drift outside README may be handled here if it directly blocks
POS-01/POS-04 clarity, otherwise Phase 50 owns final release reconciliation.

### D-07 - Docs contracts and drift guards

Add or extend focused docs contracts so the positioning does not regress:

- README first screen contains the plain-English embedded-Phoenix paragraph before capability
  ladder or verification-suite language.
- README has no stale `0.1.1` current-release or fallback guidance.
- Scope table includes Scoria-owned and host-owned rows for dashboard scope, governance gates,
  eval proof, knowledge retrieval, and run records.
- Adopter-facing docs do not expose P1-P6 as the primary public table labels.
- Comparison docs separate safe current claims from deferred seed claims and avoid
  "all peers are hosted SaaS" wording.

Prefer the existing contract-test style around `Scoria.AdopterDocContract`,
`Scoria.HexConsumerContract`, `scope_doctrine_contract_test.exs`,
`changelog_contract_test.exs`, and `terminology_contract_test.exs`.

### D-08 - UX, design, and microcopy posture for docs

The docs UI is text-first, but UX still matters:

- Use progressive disclosure: plain-language promise first; raw API, storage, policy, and
  verification details one level deeper.
- Make tables scannable and accessible. Keep cells short; move long rationale below the table.
- Use brand voice: calm, exact, operator-grade, low hype.
- Do not add new brand assets or decorative visuals in this phase. Preserve the existing logo,
  tagline, and brandbook direction.
- Avoid exposing backend internals as adopter-facing nouns unless they explain a real contract
  the adopter must honor.
- Copy should answer who/what/where/when/why for each JTBD:
  - Who: Phoenix teams, often one engineer wearing several hats.
  - What: run, inspect, approve, resume, and verify AI/LLM work.
  - Where: inside the existing Phoenix app, BEAM, Ecto/Postgres, and `/scoria`.
  - When: after adding Scoria to an app and before adopting optional capabilities.
  - Why: make AI behavior durable, inspectable, recoverable, and gateable without adopting a
    separate control plane.

### the agent's Discretion

- Exact README paragraph editing is flexible as long as D-01's facts stay intact and the text
  remains shorter than the current jargon-first opening.
- Exact table row count can be 6-8 rows. Do not add rows for unbuilt seeds unless clearly marked
  deferred.
- Exact comparison guide filename is flexible. Suggested names: `docs/llm_ops_comparison.md` or
  `docs/scoria_vs_external_llm_ops.md`.
- Exact test module names are flexible; prefer extending existing docs contract modules before
  creating a new broad scanner.

### Deferred Ideas (OUT OF SCOPE)

- **ExDoc grouping, guide ladder, and docs IA restructure** - Phase 48.
- **Curated root `llms.txt` and/or `AGENTS.md`** - Phase 49.
- **Final release reconciliation, PR #12, Hex `0.1.3`, and post-publish smoke** - Phase 50.
- **OpenInference-compatible trace export/substrate** - SEED-007.
- **Trustworthy eval depth, scorer calibration, and regression comparison maturity** - SEED-008.
- **Retrieval/RAG eval depth, faithfulness, reranking, and richer citation maps** - SEED-009.
- **Rule-of-Two/lethal-trifecta governance** - SEED-010.
- **Privacy, retention, purge, masking, and feedback governance** - SEED-011.
- **Persistent AI Feature grouping, unified queue, Run Workbench, and structural reviewer UI
  pivot** - SEED-013.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| POS-01 | A Phoenix adopter can read the README first screen and understand that Scoria is an embedded Phoenix library for durable, inspectable AI/LLM work before encountering capability or verification-suite vocabulary. | Use D-01/D-02 ordering and add first-screen contract tests that assert the plain-English paragraph precedes capability and verification-suite vocabulary [VERIFIED: `.planning/REQUIREMENTS.md`] [VERIFIED: `47-CONTEXT.md`]. |
| POS-02 | A Phoenix adopter can identify who Scoria is for, who it is not for, and how the n=1 reviewer/operator persona maps to the product surface. | Add n=1 roles-not-headcount copy plus Core/Adjacent/Not Scoria's surface bullets in README/stable docs; glossary already defines reviewer/operator compatibility [VERIFIED: `.planning/REQUIREMENTS.md`] [VERIFIED: `docs/glossary.md`]. |
| POS-03 | A Phoenix adopter can see what Scoria owns versus what the host app owns through a concrete scope-doctrine table. | Convert P1-P6 into adopter-readable owns-vs-delegates rows and extend `scope_doctrine_contract_test.exs` for required boundaries [VERIFIED: `.planning/REQUIREMENTS.md`] [VERIFIED: `test/scoria/scope_doctrine_contract_test.exs`]. |
| POS-04 | A Phoenix adopter can compare Scoria to hosted LLM-ops tools using honest tradeoffs: embedded governance, zero required egress, in-path gates, and ceded warehouse/cross-language strengths. | Add a source-linked `docs/scoria_vs_external_llm_ops.md` guide, avoid hosted-only shorthand, and cite official peer docs for cloud/self-host/hybrid/local postures [VERIFIED: `.planning/REQUIREMENTS.md`] [CITED: `https://docs.langchain.com/langsmith/self-hosted`] [CITED: `https://langfuse.com/self-hosting`] [CITED: `https://www.braintrust.dev/docs/admin/self-hosting`] [CITED: `https://arize.com/docs/phoenix/self-hosting`]. |
</phase_requirements>

## Summary

Phase 47 should be planned as a docs-and-contract phase, not as a product or ExDoc restructure phase [VERIFIED: `47-CONTEXT.md`] [VERIFIED: `.planning/ROADMAP.md`]. The README currently opens with a capability-ladder shape and stale `0.1.1` references, while Phase 47 requires a plain-English embedded-Phoenix product paragraph before coined vocabulary and a live `0.1.2` release baseline [VERIFIED: `README.md`] [VERIFIED: `.planning/STATE.md`].

The safest plan is to edit the README first screen, add/refresh stable guide copy for persona and owns-vs-delegates doctrine, create one packaged comparison guide, and extend existing contract tests rather than adding a broad new documentation scanner [VERIFIED: `47-CONTEXT.md`] [VERIFIED: `test/scoria/adoption_surface_test.exs`] [VERIFIED: `lib/scoria/adopter_doc_contract.ex`]. External comparison copy must be hybrid and source-linked because LangSmith, Langfuse, Braintrust, and Arize Phoenix official docs each describe non-hosted or hybrid deployment paths [CITED: `https://docs.langchain.com/langsmith/self-hosted`] [CITED: `https://langfuse.com/self-hosting`] [CITED: `https://www.braintrust.dev/docs/admin/self-hosting`] [CITED: `https://arize.com/docs/phoenix/self-hosting`].

**Primary recommendation:** Implement four tightly scoped work slices: README first screen/version cleanup, owns-vs-delegates/persona copy, external LLM-ops comparison guide plus `mix.exs` package/docs inclusion, and focused contract-test extensions [VERIFIED: `47-CONTEXT.md`] [VERIFIED: `mix.exs`].

## Project Constraints (from AGENTS.md / CLAUDE.md)

No root `AGENTS.md`, `CLAUDE.md`, or `.claude/CLAUDE.md` was found in `/Users/jon/projects/scoria`; nested `AGENTS.md` files exist only under dependency/example dependency directories and are not root project directives for this phase [VERIFIED: `rg --files -uuu`].

No project-local `.claude/skills`, `.agents/skills`, or `.codex/skills` directory was found at repository depth 3, so no project skill rules apply to this research artifact [VERIFIED: `find . -maxdepth 3`].

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| README first-screen positioning | Documentation / Package Surface | Test / Contract | README is both GitHub front door and ExDoc extra/package file; regression belongs in docs contract tests [VERIFIED: `README.md`] [VERIFIED: `mix.exs`] [VERIFIED: `test/scoria/adoption_surface_test.exs`]. |
| Persona boundaries | Documentation / Package Surface | Glossary | Persona copy belongs in adopter docs; glossary already owns reviewer/operator vocabulary compatibility [VERIFIED: `docs/glossary.md`] [VERIFIED: `47-CONTEXT.md`]. |
| Owns-vs-delegates doctrine | Documentation / Package Surface | Test / Contract | Public docs should translate `.planning/PROJECT.md` P1-P6 into concrete adopter rows, and `scope_doctrine_contract_test.exs` is the existing guard [VERIFIED: `.planning/PROJECT.md`] [VERIFIED: `test/scoria/scope_doctrine_contract_test.exs`]. |
| External LLM-ops comparison | Documentation / Package Surface | ExDoc/package config | A stable guide under `docs/` must be added to `mix.exs` extras/package files if it should ship to HexDocs/Hex [VERIFIED: `mix.exs`] [VERIFIED: `47-CONTEXT.md`]. |
| Version/install fallback cleanup | README + HexConsumerContract | Test / Contract | README contains stale `v0.1.1` fallback and `0.1.1` status; `Scoria.HexConsumerContract` owns dependency snippet/fallback helpers [VERIFIED: `README.md`] [VERIFIED: `lib/scoria/hex_consumer_contract.ex`]. |
| Drift guards | Test / Contract | Documentation / Package Surface | Existing docs-as-public-API pattern uses `File.read!` assertions and contract helper modules [VERIFIED: `test/scoria/adoption_surface_test.exs`] [VERIFIED: `lib/scoria/adopter_doc_contract.ex`]. |

## Standard Stack

### Core

| Library / Surface | Version | Purpose | Why Standard |
|-------------------|---------|---------|--------------|
| Markdown README and `docs/*.md` | Existing repo surface | Human and HexDocs adopter documentation | README and docs are already package files/extras; Phase 47 is explicitly stable adopter docs [VERIFIED: `mix.exs`] [VERIFIED: `47-CONTEXT.md`]. |
| ExUnit docs contracts | Elixir 1.19.5 / Mix 1.19.5 available locally | Regression guards for docs copy, package snippets, and scope doctrine | Existing tests already use `File.read!`, exact fragments, and contract modules for adopter docs [VERIFIED: local `elixir --version`] [VERIFIED: `test/scoria/adoption_surface_test.exs`]. |
| `Scoria.AdopterDocContract` | In-repo module | SSOT for shipped capability nouns, upgrade-safe install markers, and README refutes | Existing adoption-surface tests already import this module for README contract checks [VERIFIED: `lib/scoria/adopter_doc_contract.ex`] [VERIFIED: `test/scoria/adoption_surface_test.exs`]. |
| `Scoria.HexConsumerContract` | In-repo module, app version `0.1.2` | SSOT for Hex dep snippets, GitHub fallback snippet, current package version, and adopter docs surfaces | Version/fallback cleanup should extend this contract instead of hand-coded README-only assertions [VERIFIED: `lib/scoria/hex_consumer_contract.ex`] [VERIFIED: `mix.exs`]. |

### Supporting

| Library / Surface | Version | Purpose | When to Use |
|-------------------|---------|---------|-------------|
| `docs/glossary.md` | Phase 46 artifact | Final vocabulary and compatibility aliases | Link from README/comparison guide instead of redefining every term [VERIFIED: `docs/glossary.md`]. |
| `docs/adoption_lanes.md` | Existing stable guide | Capability ladder and dashboard/knowledge scope language | Use after README first screen as deeper capability reference [VERIFIED: `docs/adoption_lanes.md`]. |
| `docs/operator_verification.md` | Existing stable guide | Verification-suite, dashboard scope, eval proof, and knowledge proof details | Use for verification examples and scope-table examples [VERIFIED: `docs/operator_verification.md`]. |
| `docs/scoria_vs_external_llm_ops.md` | New file recommended | Stable peer comparison | Add when implementing POS-04 and include in `mix.exs` docs/package lists [VERIFIED: `47-CONTEXT.md`] [VERIFIED: `mix.exs`]. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Extend existing contract tests | Add a broad regex scanner | Existing tests are easier to map to POS-01..04 and match project style; broad scanners risk false positives across historical fixtures [VERIFIED: `test/scoria/adoption_surface_test.exs`] [VERIFIED: `test/fixtures/hex_consumer/scoria-0.1.0-unpack/README.md`]. |
| New comparison guide | Put peer table only in README | README should stay category-level while peer-specific claims live in source-linked stable guide [VERIFIED: `47-CONTEXT.md`]. |
| Public P1-P6 table | Adopter-readable owns-vs-delegates table | P1-P6 labels are planning doctrine; public docs must translate them into product boundaries [VERIFIED: `47-CONTEXT.md`] [VERIFIED: `.planning/PROJECT.md`]. |

**Installation:**

No external packages are required for this phase; use the existing project toolchain and tests [VERIFIED: `mix.exs`] [VERIFIED: `47-CONTEXT.md`].

## Package Legitimacy Audit

No new external package installation is recommended for Phase 47 [VERIFIED: `47-CONTEXT.md`] [VERIFIED: `mix.exs`].

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| None | - | - | - | - | OK | No package gate required [VERIFIED: research scope]. |

**Packages removed due to [SLOP] verdict:** none [VERIFIED: no package recommendations].
**Packages flagged as suspicious [SUS]:** none [VERIFIED: no package recommendations].

## Architecture Patterns

### System Architecture Diagram

```text
Phase 47 requirements (POS-01..04)
  -> README first screen rewrite
      -> product category before coined vocabulary
      -> n=1 role framing
      -> install/version baseline cleanup
  -> Stable docs updates
      -> owns-vs-delegates table
      -> persona boundary copy
      -> external LLM-ops comparison guide
  -> Package/docs config
      -> include any new guide in docs extras/package files
  -> Contract tests
      -> first-screen order guard
      -> stale version guard
      -> scope table row guard
      -> comparison safe/deferred claim guard
```

This flow follows the existing docs-as-public-API pattern where Markdown surfaces are guarded by ExUnit tests and contract modules [VERIFIED: `test/scoria/adoption_surface_test.exs`] [VERIFIED: `lib/scoria/adopter_doc_contract.ex`].

### Recommended Project Structure

```text
README.md                                  # front-door positioning, first-screen order, install baseline
docs/
  adoption_lanes.md                        # capability ladder and scope-doctrine cross-links
  operator_verification.md                 # verification and dashboard/eval/knowledge proof details
  scoria_vs_external_llm_ops.md            # recommended new comparison guide
  glossary.md                              # final vocabulary SSOT
lib/scoria/
  adopter_doc_contract.ex                  # docs contract constants
  hex_consumer_contract.ex                 # Hex/GitHub dep snippet constants
test/scoria/
  adoption_surface_test.exs                # README and package-surface docs guard
  scope_doctrine_contract_test.exs         # owns-vs-delegates guard
  terminology_contract_test.exs            # final vocabulary guard
  changelog_contract_test.exs              # release-note/README terminology guard
```

The paths above already exist except the recommended comparison guide [VERIFIED: `find docs -maxdepth 1`] [VERIFIED: `find test -type f`].

### Pattern 1: First-Screen Order Guard

**What:** Assert the plain-English paragraph appears before capability, install, quickstart, and verification-suite vocabulary [VERIFIED: `47-CONTEXT.md`].

**When to use:** Use in `test/scoria/adoption_surface_test.exs` or a narrow README-positioning contract when implementing POS-01 [VERIFIED: `test/scoria/adoption_surface_test.exs`].

**Example:**

```elixir
# Source pattern: test/scoria/adoption_surface_test.exs File.read!/fragment assertions.
test "README explains Scoria before coined capability vocabulary" do
  readme = File.read!("README.md")

  intro_index = index_of!(readme, "Scoria is an Elixir/Phoenix library")
  capability_index = index_of!(readme, "Choose Your Capability")
  verification_index = index_of!(readme, "verification suite")

  assert intro_index < capability_index
  assert intro_index < verification_index
end
```

### Pattern 2: Contract Constants for Stale Version Refutes

**What:** Put stale README version strings in `Scoria.AdopterDocContract` or `Scoria.HexConsumerContract` and assert README does not contain them [VERIFIED: `lib/scoria/adopter_doc_contract.ex`] [VERIFIED: `lib/scoria/hex_consumer_contract.ex`].

**When to use:** Use for D-06 cleanup so future README copy cannot reintroduce `v0.1.1` fallback/current-release claims [VERIFIED: `README.md`] [VERIFIED: `47-CONTEXT.md`].

**Example:**

```elixir
# Source pattern: test/scoria/adoption_surface_test.exs refute loops.
for stale <- ["tag: \"v0.1.1\"", "Current release: `0.1.1`"] do
  refute File.read!("README.md") =~ stale
end
```

### Pattern 3: Packaged Comparison Guide

**What:** New stable guide should be added to both `docs()` extras and `package()` files if it is adopter-facing HexDocs/Hex content [VERIFIED: `mix.exs`].

**When to use:** Use when implementing POS-04 with `docs/scoria_vs_external_llm_ops.md` [VERIFIED: `47-CONTEXT.md`].

**Example:**

```elixir
# Source pattern: mix.exs docs/0 and package/0 existing docs lists.
extras: [
  "README.md",
  "docs/glossary.md",
  "docs/adoption_lanes.md",
  "docs/scoria_vs_external_llm_ops.md"
]
```

### Anti-Patterns to Avoid

- **Capability ladder before product category:** It violates D-01/D-02 and keeps POS-01 unresolved [VERIFIED: `47-CONTEXT.md`] [VERIFIED: `README.md`].
- **Public P1-P6 table labels:** The public table must be adopter-readable, not planning-label-first [VERIFIED: `47-CONTEXT.md`] [VERIFIED: `.planning/PROJECT.md`].
- **Calling every peer hosted SaaS:** Official docs describe self-hosted, open-source, local, and hybrid options across the peer set [CITED: `https://docs.langchain.com/langsmith/self-hosted`] [CITED: `https://langfuse.com/self-hosting`] [CITED: `https://www.braintrust.dev/docs/admin/self-hosting`] [CITED: `https://arize.com/docs/phoenix/self-hosting`].
- **Claiming unbuilt future seeds:** OpenInference export, lethal-trifecta enforcement, deeper scorer calibration, retrieval eval depth, and retention/masking are explicitly deferred [VERIFIED: `47-CONTEXT.md`] [VERIFIED: `.planning/REQUIREMENTS.md`].

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Docs regression detection | Broad custom scanner over all repo text | Existing ExUnit docs contracts and SSOT modules | Project already guards docs with exact fragments; broad scans will trip on historical fixtures and archived docs [VERIFIED: `test/scoria/adoption_surface_test.exs`] [VERIFIED: `test/fixtures/hex_consumer/scoria-0.1.0-unpack/README.md`]. |
| Version snippet truth | Inline hard-coded README-only checks | `Scoria.HexConsumerContract` + `Scoria.AdopterDocContract` | Existing contract modules already centralize Hex dep snippets and README refutes [VERIFIED: `lib/scoria/hex_consumer_contract.ex`] [VERIFIED: `lib/scoria/adopter_doc_contract.ex`]. |
| Peer comparison claims | Uncited marketing copy | Official-doc cited comparison guide | Peer deployment/SDK/eval posture changes over time and must stay source-linked [CITED: `https://docs.langchain.com/langsmith/observability`] [CITED: `https://langfuse.com/docs`] [CITED: `https://www.braintrust.dev/docs/evaluate`] [CITED: `https://arize.com/docs/phoenix`]. |
| Auth/policy modeling copy | New Scoria-owned role or policy vocabulary | Host-owned authz/policy language from dashboard scope docs | Phase 44/45 doctrine says Scoria ships the seam and records trusted scope while host owns authz and policy values [VERIFIED: `.planning/STATE.md`] [VERIFIED: `docs/operator_verification.md`]. |

**Key insight:** The planner should make every doc change falsifiable through focused contract tests, because Scoria already treats docs copy as public API [VERIFIED: `test/scoria/adoption_surface_test.exs`] [VERIFIED: `test/scoria/terminology_contract_test.exs`].

## Common Pitfalls

### Pitfall 1: Jargon Before Category

**What goes wrong:** The README asks adopters to understand capabilities and verification suites before they know Scoria is an embedded Phoenix library [VERIFIED: `README.md`] [VERIFIED: `47-CONTEXT.md`].

**Why it happens:** Phase 46 successfully migrated terminology, but the front-door order still leads with the capability ladder [VERIFIED: `README.md`] [VERIFIED: `.planning/ROADMAP.md`].

**How to avoid:** Put the D-01 paragraph immediately after logo/tagline/badges and guard order with a test [VERIFIED: `47-CONTEXT.md`].

**Warning signs:** `Default runtime`, `verification suite`, or capability bullets appear before the plain-English paragraph [VERIFIED: `README.md`].

### Pitfall 2: Treating Reviewer as a Department

**What goes wrong:** Docs imply a dedicated ML platform, Trust and Safety, compliance, or review team is required [VERIFIED: `47-CONTEXT.md`].

**Why it happens:** The glossary defines reviewer, but the README does not yet carry the n=1 roles-not-headcount lens [VERIFIED: `docs/glossary.md`] [VERIFIED: `README.md`].

**How to avoid:** Add Core/Adjacent/Not Scoria's surface bullets and say reviewer is a role one engineer may wear [VERIFIED: `47-CONTEXT.md`] [VERIFIED: `.planning/PROJECT.md`].

**Warning signs:** Copy presents reviewers, eval checkers, prompt writers, and SREs as separate required teams rather than hats [VERIFIED: `.planning/PROJECT.md`].

### Pitfall 3: Scope Doctrine as Internal Labels

**What goes wrong:** A public table exposes P1-P6 instead of answering what Scoria owns versus what the host app owns [VERIFIED: `47-CONTEXT.md`].

**Why it happens:** P1-P6 is the planning SSOT, but adopter docs need concrete product boundaries [VERIFIED: `.planning/PROJECT.md`] [VERIFIED: `47-CONTEXT.md`].

**How to avoid:** Use the D-03 table schema and row set; add row-level tests for run records, dashboard scope, governance gates, eval proof, and knowledge retrieval [VERIFIED: `47-CONTEXT.md`].

**Warning signs:** Public docs lead with P1/P2 labels or hide host-owned auth/policy/business-truth responsibilities [VERIFIED: `47-CONTEXT.md`] [VERIFIED: `docs/operator_verification.md`].

### Pitfall 4: Peer Comparison Overclaim

**What goes wrong:** Copy says peers are hosted SaaS only, or implies Scoria ships OpenInference export/lethal-trifecta/deep eval/retention features that are deferred [VERIFIED: `47-CONTEXT.md`].

**Why it happens:** Scoria's embedded posture is real, but peer deployment models and feature sets are broader than hosted-only shorthand [CITED: `https://langfuse.com/self-hosting`] [CITED: `https://arize.com/docs/phoenix/self-hosting`].

**How to avoid:** Title the guide "Scoria vs external LLM-ops platforms," source-link peer claims, and include a "not yet / deferred" section [VERIFIED: `47-CONTEXT.md`].

**Warning signs:** "hosted-only tools", "all peers are SaaS", "OpenInference-compatible", or "Rule-of-Two" appears as a current claim [VERIFIED: `47-CONTEXT.md`].

### Pitfall 5: Hidden Baseline Test Failure

**What goes wrong:** The planner assumes docs contracts are green before Phase 47 work [VERIFIED: local test run].

**Why it happens:** Current `scope_doctrine_contract_test.exs` expects a README sentence with "lane" wording, but README now uses "capability" wording in that section [VERIFIED: `test/scoria/scope_doctrine_contract_test.exs`] [VERIFIED: `README.md`].

**How to avoid:** Add a Wave 0 baseline task to reconcile the existing contract failure before layering new Phase 47 guards [VERIFIED: local test run].

**Warning signs:** Focused command below fails one assertion in `Scoria.ScopeDoctrineContractTest` [VERIFIED: local test run].

```bash
MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/scope_doctrine_contract_test.exs test/scoria/terminology_contract_test.exs test/scoria/changelog_contract_test.exs test/scoria/glossary_contract_test.exs
```

## Code Examples

Verified patterns from existing project tests:

### Exact Fragment Contract

```elixir
# Source: test/scoria/adoption_surface_test.exs
content = File.read!("README.md")

for marker <- AdopterDocContract.upgrade_safe_install_markers() do
  assert content =~ marker
end
```

### Active Source Filtering for Storage-Safe Terminology

```elixir
# Source: test/scoria/terminology_contract_test.exs
defp active_source_text(source) do
  source
  |> String.split("\n")
  |> Enum.reject(&(String.trim_leading(&1) |> String.starts_with?("#")))
  |> Enum.join("\n")
  |> String.trim()
end
```

### Index-Based Ordering Guard

```elixir
# Source style: test/scoria/changelog_contract_test.exs index_of!/2 ordering checks.
intro_index = index_of!(readme, "Scoria is an Elixir/Phoenix library")
capability_index = index_of!(readme, "Choose Your Capability")

assert intro_index < capability_index
```

## State of the Art

| Old Approach | Current Approach | When Changed / Verified | Impact |
|--------------|------------------|-------------------------|--------|
| README leads with capability ladder | README should lead with product category and embedded boundary | Phase 47 D-01/D-02 [VERIFIED: `47-CONTEXT.md`] | POS-01 becomes testable by first-screen order. |
| Public scope doctrine points at P1-P6 SSOT | Public docs translate doctrine into owns-vs-delegates rows | Phase 47 D-03 [VERIFIED: `47-CONTEXT.md`] | POS-03 becomes adopter-facing instead of planning-facing. |
| Peer comparison as hosted SaaS contrast | Peer comparison as external LLM-ops platforms with cloud/self-host/hybrid/local nuance | Official docs checked 2026-07-10 [CITED: `https://docs.langchain.com/langsmith/self-hosted`] [CITED: `https://langfuse.com/self-hosting`] [CITED: `https://www.braintrust.dev/docs/admin/self-hosting`] [CITED: `https://arize.com/docs/phoenix/self-hosting`] | POS-04 avoids false claims and stale comparisons. |
| README status says `0.1.1` | README should state live Hex baseline `0.1.2` and Phase 50 `0.1.3` target only where needed | Phase 47 D-06 [VERIFIED: `README.md`] [VERIFIED: `.planning/STATE.md`] | Removes stale install/release guidance. |

**Deprecated/outdated:**

- README GitHub fallback `tag: "v0.1.1"` is stale for Phase 47 and must be removed or updated to non-release fork/pinned-patch guidance [VERIFIED: `README.md`] [VERIFIED: `47-CONTEXT.md`].
- README `Current release: 0.1.1` is stale because `mix.exs` and state identify `0.1.2` as current baseline [VERIFIED: `README.md`] [VERIFIED: `mix.exs`] [VERIFIED: `.planning/STATE.md`].
- "Hosted-only tools" is unsafe shorthand because peer docs include self-hosted, hybrid, local, and open-source deployment models [CITED: `https://docs.langchain.com/langsmith/self-hosted`] [CITED: `https://langfuse.com/self-hosting`] [CITED: `https://www.braintrust.dev/docs/admin/self-hosting`] [CITED: `https://arize.com/docs/phoenix/self-hosting`].

## Assumptions Log

All claims in this research were verified against repository files, local commands, or official documentation in this session; no `[ASSUMED]` claims are intentionally used.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| - | None | - | - |

## Open Questions (RESOLVED)

1. **Should Phase 47 touch maintainer `0.1.1` release-command examples?**
   - What we know: README stale `0.1.1` is explicitly in scope; maintainer release-command drift may be handled only if it directly blocks POS-01/POS-04 clarity [VERIFIED: `47-CONTEXT.md`] [VERIFIED: `docs/MAINTAINERS.md`].
   - RESOLVED: Keep Phase 47 to README/adopter comparison unless README/adopter docs contracts require `docs/MAINTAINERS.md`; otherwise leave maintainer `0.1.1` release-command cleanup to Phase 50 [VERIFIED: `47-CONTEXT.md`] [VERIFIED: `.planning/ROADMAP.md`].

2. **Exact comparison filename**
   - What we know: Context suggests `docs/llm_ops_comparison.md` or `docs/scoria_vs_external_llm_ops.md` [VERIFIED: `47-CONTEXT.md`].
   - RESOLVED: Use `docs/scoria_vs_external_llm_ops.md` because it is explicit, stable, and avoids "hosted-only" shorthand [VERIFIED: `47-CONTEXT.md`] [VERIFIED: `find docs -maxdepth 1`].

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | ExUnit docs contracts | yes | 1.19.5 / OTP 28 | None needed [VERIFIED: local `elixir --version`]. |
| Mix | Test runner and docs/package config | yes | 1.19.5 / OTP 28 | None needed [VERIFIED: local `mix --version`]. |
| Git | Optional research commit | yes | 2.41.0 | Manual commit if GSD commit seam fails [VERIFIED: local `git --version`]. |
| External web access | Peer comparison source checks | yes | WebSearch via GSD seam and built-in web tool | Use cited docs snapshots if network later fails [VERIFIED: research-plan execution]. |

**Missing dependencies with no fallback:** none for research/planning [VERIFIED: environment audit].

**Missing dependencies with fallback:** none for research/planning [VERIFIED: environment audit].

## Validation Architecture

`workflow.nyquist_validation` is absent from `.planning/config.json`, so validation is treated as enabled [VERIFIED: `.planning/config.json`].

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix 1.19.5 [VERIFIED: `mix --version`]. |
| Config file | `mix.exs` aliases and preferred envs [VERIFIED: `mix.exs`]. |
| Quick run command | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/scope_doctrine_contract_test.exs test/scoria/terminology_contract_test.exs test/scoria/changelog_contract_test.exs test/scoria/glossary_contract_test.exs` [VERIFIED: local test run]. |
| Full suite command | `mix ci` or maintainer closeout chain `mix scoria.release_preview`, `mix test.adoption`, `mix test.runtime_to_handoff` depending on plan scope [VERIFIED: `docs/operator_verification.md`] [VERIFIED: `mix.exs`]. |

### Phase Requirements to Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| POS-01 | README plain-English embedded-Phoenix paragraph appears before capability and verification-suite vocabulary | docs contract | quick run above, after adding first-screen assertions | Partial; extend `test/scoria/adoption_surface_test.exs` [VERIFIED: file exists]. |
| POS-02 | README/stable docs state n=1 roles-not-headcount and Core/Adjacent/Not Scoria's surface boundaries | docs contract | quick run above, after adding persona assertions | Partial; extend existing docs contracts [VERIFIED: `docs/glossary.md`] [VERIFIED: `README.md`]. |
| POS-03 | Owns-vs-delegates table includes Scoria-owned and host-owned boundaries without public P1-P6 labels | docs contract | quick run above, after extending `scope_doctrine_contract_test.exs` | Partial; existing file needs new row assertions [VERIFIED: `test/scoria/scope_doctrine_contract_test.exs`]. |
| POS-04 | Comparison guide states safe current Scoria claims, cites peer deployment nuance, and names deferred claims | docs contract | quick run above plus package/docs surface tests if guide added | No guide yet; add `docs/scoria_vs_external_llm_ops.md` and package/extras checks [VERIFIED: `find docs -maxdepth 1`] [VERIFIED: `mix.exs`]. |

### Sampling Rate

- **Per task commit:** Run focused docs contracts for files touched by that task [VERIFIED: existing test layout].
- **Per wave merge:** Run the quick command above; it currently exposes one baseline failure to fix [VERIFIED: local test run].
- **Phase gate:** Run `mix scoria.release_preview` if a new packaged guide or `mix.exs` docs/package list changes; run `mix test.adoption` only if package surface or README install guidance changes materially [VERIFIED: `docs/operator_verification.md`] [VERIFIED: `mix.exs`].

### Wave 0 Gaps

- [ ] Existing focused command currently fails one assertion in `test/scoria/scope_doctrine_contract_test.exs` because the test expects "Retrieval and citations in this lane..." while README now uses capability wording [VERIFIED: local test run] [VERIFIED: `test/scoria/scope_doctrine_contract_test.exs`] [VERIFIED: `README.md`].
- [ ] Add first-screen order assertions for POS-01 in `test/scoria/adoption_surface_test.exs` or a new narrow README positioning test [VERIFIED: `47-CONTEXT.md`].
- [ ] Add stale `0.1.1` README refutes and current `0.1.2` baseline assertions through contract helpers [VERIFIED: `README.md`] [VERIFIED: `lib/scoria/hex_consumer_contract.ex`].
- [ ] Add package/docs list assertions if `docs/scoria_vs_external_llm_ops.md` is created [VERIFIED: `mix.exs`].

## Security Domain

`security_enforcement` is absent from `.planning/config.json`, so security review is treated as enabled [VERIFIED: `.planning/config.json`].

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes, documentation surface only | README/scope table must say host app owns authentication and Scoria only consumes trusted scope [VERIFIED: `docs/operator_verification.md`] [VERIFIED: `47-CONTEXT.md`]. |
| V3 Session Management | yes, documentation surface only | Copy must avoid treating query params as tenant authority and keep session/scope resolver language precise [VERIFIED: `docs/adoption_lanes.md`] [VERIFIED: `docs/operator_verification.md`]. |
| V4 Access Control | yes, documentation surface only | Owns-vs-delegates table must say host owns authorization, tenant membership, role values, policy values, and business risk interpretation [VERIFIED: `47-CONTEXT.md`]. |
| V5 Input Validation | limited | No new runtime input; comparison/docs should not advise unsafe URL/query-param trust [VERIFIED: docs-only phase scope]. |
| V6 Cryptography | no | No cryptographic implementation or key-management change in this phase [VERIFIED: `47-CONTEXT.md`]. |

### Known Threat Patterns for Docs-Only Phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Docs imply URL tenant params select dashboard authority | Elevation of Privilege | Preserve Phase 44 language that URL values are hints only and host resolver asserts tenant scope [VERIFIED: `docs/adoption_lanes.md`] [VERIFIED: `docs/operator_verification.md`]. |
| Docs imply Scoria owns host auth, roles, or business policy values | Elevation of Privilege | Owns-vs-delegates table must put authz, role values, thresholds, and escalation rules under host ownership [VERIFIED: `47-CONTEXT.md`]. |
| Docs overclaim zero egress beyond Scoria governance records | Information Disclosure | State that Scoria governance records require no Scoria-hosted control-plane egress, while model/tool provider calls remain host-owned [VERIFIED: `47-CONTEXT.md`]. |
| Docs overclaim deferred security features | Spoofing / Tampering / Information Disclosure | Forbid current claims for Rule-of-Two/lethal-trifecta, retention/masking/purge, and OpenInference export until their owning seeds ship [VERIFIED: `47-CONTEXT.md`] [VERIFIED: `.planning/REQUIREMENTS.md`]. |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/47-readme-first-screen-positioning-and-scope-doctrine/47-CONTEXT.md` - locked Phase 47 decisions, scope, deferred work, and test preferences [VERIFIED: codebase grep].
- `.planning/REQUIREMENTS.md` - POS-01..04 definitions and traceability [VERIFIED: codebase grep].
- `.planning/ROADMAP.md` - Phase 47/48/49/50 boundaries and release sequencing [VERIFIED: codebase grep].
- `.planning/PROJECT.md` - n=1 persona lens and P1-P6 scope doctrine SSOT [VERIFIED: codebase grep].
- `.planning/STATE.md` - current milestone state, Phase 46 complete, `0.1.2` live baseline, `0.1.3` held for Phase 50 [VERIFIED: codebase grep].
- `README.md` - current first-screen order and stale `0.1.1` references [VERIFIED: codebase grep].
- `docs/glossary.md`, `docs/adoption_lanes.md`, `docs/operator_verification.md` - stable docs inputs and vocabulary/scope language [VERIFIED: codebase grep].
- `lib/scoria/adopter_doc_contract.ex`, `lib/scoria/hex_consumer_contract.ex`, `lib/scoria/verification_suites.ex` - docs and verification SSOT modules [VERIFIED: codebase grep].
- `test/scoria/adoption_surface_test.exs`, `test/scoria/scope_doctrine_contract_test.exs`, `test/scoria/terminology_contract_test.exs`, `test/scoria/changelog_contract_test.exs`, `test/scoria/glossary_contract_test.exs` - existing docs contract style and baseline failure [VERIFIED: codebase grep] [VERIFIED: local test run].

### Secondary (MEDIUM confidence)

- `https://docs.langchain.com/langsmith/self-hosted` - LangSmith self-hosted Enterprise add-on, infrastructure, observability/evaluation/prompt engineering [CITED: official docs].
- `https://docs.langchain.com/langsmith/observability` - LangSmith cloud/hybrid/self-hosted setup and features [CITED: official docs].
- `https://docs.langchain.com/langsmith/reference` - LangSmith Python, JS/TS, Go, Java SDK references [CITED: official docs].
- `https://langfuse.com/docs` - Langfuse open-source AI engineering platform, observability/prompts/evaluation/platform overview [CITED: official docs].
- `https://langfuse.com/self-hosting` - Langfuse cloud/self-hosted deployment and architecture [CITED: official docs].
- `https://langfuse.com/docs/observability/sdk/overview` - Langfuse Python, JS/TS, and OpenTelemetry/public API language posture [CITED: official docs].
- `https://www.braintrust.dev/docs/evaluate` - Braintrust evals, playgrounds, experiments, CI/CD, production trace scoring [CITED: official docs].
- `https://www.braintrust.dev/docs/admin/self-hosting` - Braintrust hybrid self-hosting/data-plane model [CITED: official docs].
- `https://www.braintrust.dev/docs/admin/self-hosting/deploy` - Braintrust AWS/GCP/Azure data-plane deployment [CITED: official docs].
- `https://arize.com/docs/phoenix` - Arize Phoenix tracing/evaluation and integration language support [CITED: official docs].
- `https://arize.com/docs/phoenix/self-hosting` - Arize Phoenix free self-host/no egress/air-gapped claims [CITED: official docs].
- `https://arize.com/docs/phoenix/get-started` - Arize Phoenix trace/eval/prompt/experiment guide ladder [CITED: official docs].

### Tertiary (LOW confidence)

- None used for recommendations; package/search discoveries were not used as authoritative package recommendations [VERIFIED: research log].

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - entirely based on current repo files and local tool versions [VERIFIED: `mix.exs`] [VERIFIED: local `mix --version`].
- Architecture: HIGH - Phase 47 scope, docs surfaces, and contract-test style are all repo-verified [VERIFIED: `47-CONTEXT.md`] [VERIFIED: `test/scoria/adoption_surface_test.exs`].
- Pitfalls: HIGH for repo pitfalls and MEDIUM for peer-comparison pitfalls because peer claims come from official web docs checked through the research seam [VERIFIED: `README.md`] [CITED: official peer docs].

**Research date:** 2026-07-10
**Valid until:** 2026-08-09 for repo-internal planning guidance; 2026-07-17 for peer comparison details because external LLM-ops documentation changes quickly.
