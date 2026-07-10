# Phase 48: ExDoc and guide ladder restructure - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-07-10
**Phase:** 48-ExDoc and guide ladder restructure
**Areas discussed:** Guide tree migration, HexDocs landing and docs metadata, guide/extras grouping, module grouping taxonomy, public moduledoc/API discoverability, docs package and verification contracts

---

## User Direction

The user asked to "discuss/consider all" gray areas in one pass, using subagents and research. They explicitly requested pros/cons/tradeoffs, idiomatic Elixir/Plug/Ecto/Phoenix ecosystem guidance, lessons from successful libraries/apps in adjacent ecosystems, excellent developer ergonomics, user-friendly surfaces, project-vision coherence, prompt-corpus research, and UI/UX/brand/JTBD lenses where applicable.

Research inputs included current official ExDoc/Elixir docs, Phoenix/Ecto/LiveDashboard docs, Diataxis, Django and Rails guide organization, local sibling repositories, current Scoria docs/tests, prior phase contexts, the documentation overhaul seed, and the prompt/brand corpus.

---

## Guide Tree Migration

| Option | Description | Selected |
|--------|-------------|----------|
| ExDoc grouping over flat `docs/` | Lowest churn; keeps source paths stable; sidebar improves but old filenames and source IA remain flat. | |
| Shallow `guides/` ladder plus old-path stubs and ExDoc redirects | Real guide migration with manageable churn; preserves old source/HexDocs links; matches current Scoria scale. | yes |
| Full nested Diataxis tree | Strong long-term IA; higher churn and too much structure for current guide count. | |
| Audience split | Clear adopter/operator/maintainer separation; less task-oriented and risks leaking old persona language. | |

**User's choice:** User delegated final recommendation after asking to consider all options deeply.
**Notes:** Subagent research recommended the shallow `guides/` ladder because it satisfies DOCS-01..03 without over-structuring. The plan should keep compatibility stubs out of ExDoc `extras` and add redirects for old page ids such as `semantic_fast_path`, `operator_verification`, and `adoption_lanes`.

---

## HexDocs Landing and Metadata

| Option | Description | Selected |
|--------|-------------|----------|
| Keep `main: "readme"` | Lowest churn; HexDocs still opens on GitHub README instead of product docs. | |
| New Getting Started guide as `main` | Best first-run HexDocs DX; separates README positioning from product manual. | yes |
| Use `Scoria` facade module as `main` | API-first; too reference-oriented for onboarding. | |

**User's choice:** User delegated final recommendation.
**Notes:** Recommendation is `main: "getting-started"`, dynamic source refs, ExDoc logo/favicon, grouped extras/modules, and HTML/Markdown formatters. `docs_source_ref/0` should fall back to `"main"` unless the exact release tag is being built or `SCORIA_DOCS_SOURCE_REF` is set.

---

## Guide and Extra Grouping

| Option | Description | Selected |
|--------|-------------|----------|
| Pure Diataxis labels | Strong documentation theory; can feel abstract in the sidebar. | |
| Consumer job groups | Matches Scoria JTBD and user psychology; keeps the sidebar action-oriented. | yes |
| Source-folder groups only | Easy to maintain; less helpful as a product surface. | |

**User's choice:** User delegated final recommendation.
**Notes:** Recommended groups are Start Here, Capabilities, Operate & Verify, Compare & Decide, Reference, and Maintainers. Diataxis should inform completeness, not become the visible taxonomy.

---

## Module Grouping Taxonomy

| Option | Description | Selected |
|--------|-------------|----------|
| Consumer-journey domain taxonomy | Best adopter DX; puts install/runtime/reviewer/capability surfaces in task order. | yes |
| Namespace/folder mirror | Easy but recreates an API dump with headings. | |
| API maturity rings | Communicates support level but loses domain story. | |
| Architecture map taxonomy | Good for maintainers; too implementation-first for HexDocs. | |

**User's choice:** User delegated final recommendation.
**Notes:** Recommended groups are Start Here, Install & Verify, Runtime & Workflows, Reviewer Dashboard, Eval & Release Proof, Knowledge & Semantic Cache, Connectors & MCP, Governance/Observe/SRE, Compatibility Aliases, and Maintainer Tools only when deliberately public.

---

## Public Moduledoc and API Discoverability

| Option | Description | Selected |
|--------|-------------|----------|
| Curated public surface plus grouped guide ladder | Best least-surprise HexDocs; supported modules get mini-README moduledocs; internals are hidden. | yes |
| Physical `guides/` tree with redirects only | Strong guide IA but does not by itself fix API reference noise. | |
| Broad grouped API reference | Maintainer-friendly; exposes too many internals as public API. | |
| Facade-only API reference | Very clean but hides legitimate advanced extension points. | |

**User's choice:** User delegated final recommendation.
**Notes:** Public docs should prioritize `Scoria`, install/dashboard scope, runtime, reviewer surface, verification suites, semantic cache, knowledge, connectors/MCP, eval, prompt policy/registry, Req steps, and SRE sinks. Hide schemas, LiveViews, components, workers, dev/test helpers, warning-ratchet helpers, and contract-test modules unless they are explicitly public.

---

## Docs Package and Verification Contracts

| Option | Description | Selected |
|--------|-------------|----------|
| Keep current hardcoded flat path tests | Low effort; locks in the old shape. | |
| Update contracts to assert guide ladder, groups, redirects, metadata, package assets, and source refs | More work; prevents future drift and makes the restructure durable. | yes |
| Add broad warning-as-error gate now | Strong quality bar; may expand scope into warning cleanup. | |

**User's choice:** User delegated final recommendation.
**Notes:** Update `test/scoria/package_surface_test.exs`, `lib/mix/tasks/scoria.release_preview.ex`, and `test/mix/tasks/scoria.release_preview_test.exs`. Keep release-preview passing. Defer broad docs WAE CI enforcement unless it is cheap and does not distract from DOCS-01..03.

## Claude's Discretion

- Exact helper names and shared test helper factoring.
- Exact final generated page ids in ExDoc redirects, as long as old generated ids redirect to canonical guide pages.
- Whether to use explicit module lists, regexes, or a small `filter_modules` function, as long as the curated public surface and internal hiding decisions hold.

## Deferred Ideas

- Phase 49: AI docs/evaluation docs, docs-as-eval contract, and AI-specific guide surfaces.
- Phase 50: release publish workflow, version cutover, and announcement/release artifacts.
- Later hardening: full docs warning-as-error CI gate if it requires broad warning cleanup.
