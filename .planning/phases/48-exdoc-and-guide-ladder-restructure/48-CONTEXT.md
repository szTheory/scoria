# Phase 48: ExDoc and guide ladder restructure - Context

**Gathered:** 2026-07-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 48 turns Scoria's HexDocs output from a flat module/page dump into a navigable product documentation surface. The phase owns the ExDoc information architecture, guide ladder, source metadata, brand assets, public module grouping, and the docs/package contracts needed to keep those choices stable.

In scope:
- Replace the flat adopter-facing `docs/*.md` source layout with a shallow canonical `guides/` ladder.
- Preserve old source and HexDocs links with compatibility stubs and ExDoc `redirects`.
- Make HexDocs open on a purpose-built Getting Started guide instead of the GitHub README.
- Add ExDoc metadata and brand assets: source URL/ref handling, logo, favicon, grouped extras, grouped modules, and HTML/Markdown output.
- Curate the public API reference so adopters see the supported Scoria surface first and internals do not look like public contracts.
- Update README, moduledoc guide links, package file inventory, release-preview checks, and docs surface tests to match the new structure.

Out of scope:
- AI-specific docs, eval contracts, and AI assistant documentation. Phase 49 owns these.
- Release publishing, changelog/release announcement workflow, and version cutover. Phase 50 owns these.
- New product capabilities, new dashboard UI features, or new backend behavior beyond docs/config/test changes required for the documentation surface.
- A full nested Diataxis tree. Use Diataxis as a thinking model, not as the physical tree for this phase.

</domain>

<decisions>
## Implementation Decisions

### Guide Ladder
- **D-01:** Use a shallow canonical `guides/` tree for adopter-facing docs. Do not keep flat `docs/` files as the canonical source, and do not jump to a heavily nested `guides/introduction`, `guides/flows`, `guides/reference`, `guides/recipes` tree yet. Scoria has enough stable guides to deserve a real ladder, but not enough to justify over-foldering.
- **D-02:** Keep old `docs/*.md` source paths as thin compatibility stubs where external users may have copied links. Exclude those stubs from ExDoc `extras` so the sidebar does not duplicate content. Add ExDoc `redirects` for old generated page ids, using ExDoc's extensionless mapping style, for example `%{"semantic_fast_path" => "semantic-cache"}` or the final generated target id chosen by the planner.
- **D-03:** The minimum canonical guide ladder should cover:
  - `guides/getting-started.md`
  - `guides/golden-path.md`
  - `guides/jtbd-and-user-flows.md`
  - `guides/ownership-boundary.md`
  - `guides/capabilities/default-runtime.md`
  - `guides/capabilities/bounded-handoffs.md`
  - `guides/capabilities/semantic-cache.md`
  - `guides/capabilities/connectors-and-mcp.md`
  - `guides/capabilities/support-copilot-gallery.md`
  - `guides/reviewer-verification.md`
  - `guides/troubleshooting.md`
  - `guides/scoria-vs-external-llm-ops.md`
  - `guides/cheatsheet.cheatmd`
  - `guides/reference/glossary.md`
  - `guides/maintainers.md`
- **D-04:** Rename guide concepts into Phase 46/47 public vocabulary while preserving compatibility. `operator_verification` becomes reviewer verification, `semantic_fast_path` becomes semantic cache, `adoption_lanes` becomes capabilities/adoption routes, and any remaining "lane/operator surface" naming should appear only in compatibility notes.

### HexDocs Entry and Metadata
- **D-05:** Set HexDocs `main: "getting-started"`. README remains the GitHub/package front door and can appear in the extras list, but it should not be the first page HexDocs opens.
- **D-06:** Add docs metadata helpers in `mix.exs`: `@source_url`, `@hexdocs_url`, `@release_docs_url`, and `docs_source_ref/0`. Use `homepage_url: @hexdocs_url` for the Hex package metadata.
- **D-07:** `docs_source_ref/0` should prefer `SCORIA_DOCS_SOURCE_REF` when set, return `v#{@version}` only when CI/local git is building exactly that tag, and otherwise return `"main"`. This fixes the current footgun where unreleased `main` docs for version `0.1.2` point source links at a tag that may not contain the current docs.
- **D-08:** Configure ExDoc with `source_url: @source_url`, `source_ref: docs_source_ref()`, `extra_section: "Guides"`, `formatters: ["html", "markdown"]`, `logo: "brandbook/logo-mark.svg"`, and `favicon: "brandbook/favicon.svg"`. Do not add custom `source_url_pattern` for normal GitHub hosting.
- **D-09:** Include only needed docs brand assets in the Hex package: `brandbook/logo-primary.svg`, `brandbook/logo-primary-light.svg`, `brandbook/logo-mark.svg`, and `brandbook/favicon.svg`.

### Guide Groups
- **D-10:** Group extras by reader job, not by implementation folder alone. Recommended ExDoc group labels:
  - `Start Here`: README, Getting Started, Golden Path, JTBD/User Flows, Ownership Boundary, Cheatsheet.
  - `Capabilities`: Default Runtime, Bounded Handoffs, Semantic Cache, Connectors/MCP, Support Copilot Gallery.
  - `Operate & Verify`: Reviewer Verification and Troubleshooting.
  - `Compare & Decide`: Scoria vs External LLM Ops.
  - `Reference`: Glossary.
  - `Maintainers`: MAINTAINERS, CHANGELOG, LICENSE, and maintainer-only docs that are intentionally packaged.
- **D-11:** Keep dev-only docs such as design system, Docker dev DX, and UAT automation out of the adopter HexDocs sidebar unless the planner finds an explicit Phase 48 requirement to package them. They can remain repository docs.

### Module Groups and Public Surface
- **D-12:** Use a consumer-journey domain taxonomy for `groups_for_modules`, not a namespace mirror. Recommended group labels:
  - `Start Here`
  - `Install & Verify`
  - `Runtime & Workflows`
  - `Reviewer Dashboard`
  - `Eval & Release Proof`
  - `Knowledge & Semantic Cache`
  - `Connectors & MCP`
  - `Governance, Observe & SRE`
  - `Compatibility Aliases`
  - `Maintainer Tools` only if a module is intentionally public to maintainers
- **D-13:** Keep `Scoria` as the first public API and make the first public group answer "what do I install or call first?" Include `Scoria`, `Scoria.Identity`, runtime summary/detail structs, `ScoriaWeb.Router`, `ScoriaWeb.DashboardScope`, and `Scoria.VerificationSuites` near the start/install groups.
- **D-14:** Curate the public reference aggressively. Hide or filter modules that are implementation details: Ecto schemas, workers, LiveViews, controllers, components, copy helpers, asset/layout modules, `DevLab.*`, warning-ratchet/inventory helpers, adopter/Hex contract test helpers, support journey artifacts, UI critique artifacts, and test/support modules. If a returned schema or struct must remain visible for a public function, give it a minimal public typedoc/moduledoc that frames it as data returned by the public API rather than persistence internals.
- **D-15:** Keep compatibility wrappers visible in a small `Compatibility Aliases` group, but do not add runtime `@deprecated` warnings during this phase. Include wrappers such as old verification lane/semantic lane/operator surface/broadcast names with migration notes to the Phase 46 vocabulary.

### Moduledoc and API DX
- **D-16:** Public moduledocs should read like mini README pages: concise first sentence, when to use it, how it fits into Scoria's ownership boundary, one copyable example when feasible, and links to the relevant guide. Do not lead with backend implementation details.
- **D-17:** Prioritize polished moduledocs for these public entry points: `Scoria`, `Scoria.Identity`, `Scoria.Runtime`, `Scoria.PromptPolicy`, `ScoriaWeb.Router`, `ScoriaWeb.DashboardScope`, `ScoriaWeb.ReviewerSurface`, `Scoria.Observe.ReviewerBroadcast`, `Scoria.VerificationSuites`, `Scoria.SemanticCache.Profile`, `Scoria.SemanticCache`, `Scoria.Knowledge`, `Scoria.Connectors`, `Scoria.Connectors.Auth`, `Scoria.MCP.Tool`, `Scoria.Req.Steps`, `Scoria.Eval`, `Scoria.PromptRegistry`, `Scoria.SRE`, `Scoria.SRE.AlertSink`, and `Scoria.SRE.AuditSink`.
- **D-18:** Call out the common adoption footguns in docs where they naturally belong: `session_id` is not `run_id`; dashboard tenant scope is host-authenticated rather than query-param selected; the default runtime does not require knowledge, semantic cache, or connector setup; semantic cache is not the same thing as a knowledge base.
- **D-19:** Doctest only pure examples that do not require repo, PubSub, router, DB, or LiveView setup. Keep runtime/dashboard/DB examples under regular tests and docs contract tests.

### Verification and Package Contracts
- **D-20:** Replace tests that assert the old flat extras list and `source_ref == "v#{version}"` with normalized assertions for the new guide ladder, group coverage, redirects for old page ids, dynamic source refs, and package inclusion for every docs extra and brand asset.
- **D-21:** Align `mix.exs`, `test/scoria/package_surface_test.exs`, `lib/mix/tasks/scoria.release_preview.ex`, and `test/mix/tasks/scoria.release_preview_test.exs`. Avoid duplicating path lists in multiple places without a shared helper or a deliberate contract test that detects drift.
- **D-22:** Phase 48 should keep `mix scoria.release_preview` passing after the docs restructure. A broad `mix docs --warnings-as-errors` CI gate can stay deferred to Phase 49/release hardening unless Phase 48 can add it without turning this into a warning cleanup project.

### Claude's Discretion
The user delegated the final recommendations after asking to consider all options through architecture, DX, ecosystem, UI/UX, brand, and user-psychology lenses. Downstream agents may choose exact helper/function names and exact implementation factoring, but should preserve the decisions above unless blocked by live code constraints.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

No explicit `Canonical refs:` line appears in the Phase 48 roadmap entry. The references below are accumulated from the roadmap, requirements, prior phase contexts, seed docs, prompt corpus, code scout, local exemplars, subagent research, and current official documentation.

### Phase and Planning Context
- `.planning/ROADMAP.md` - Phase 48 goal, dependencies, success criteria, and requirement IDs.
- `.planning/REQUIREMENTS.md` - DOCS-01, DOCS-02, and DOCS-03 for Phase 48; DOCS-04/AI requirements deferred to Phase 49; release requirements deferred to Phase 50.
- `.planning/PROJECT.md` - Project vision and current milestone framing.
- `.planning/STATE.md` - Current GSD state and phase sequencing.
- `.planning/seeds/SEED-005-documentation-overhaul.md` - Original documentation overhaul seed, including ExDoc grouping, metadata, and guide ladder ideas.
- `.planning/phases/47-readme-first-screen-positioning-and-scope-doctrine/47-CONTEXT.md` - README front-door decisions, scope doctrine, and Phase 48 deferrals.
- `.planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md` - Locked vocabulary: reviewer, trace, capabilities, verification suite, scoped context, semantic cache, optional knowledge base.

### Brand and Prompt Corpus
- `brandbook/brand-book.md` - Canonical current brandbook; use this over older prompt references if they disagree.
- `brandbook/README.md` - Brand asset usage context.
- `brandbook/logo-mark.svg` - Recommended ExDoc logo asset.
- `brandbook/favicon.svg` - Recommended ExDoc favicon asset.
- `brandbook/logo-primary.svg` - Package brand asset.
- `brandbook/logo-primary-light.svg` - Package brand asset.
- `prompts/sztheory-elixir-dna.md` - Phoenix/Elixir DNA: composable, operator-first, embedded dashboards, Ecto-native state, ecosystem integration, robust CI.
- `prompts/phoenix-ai-lib-deep-research.md` - Scoria positioning as Phoenix-native AI quality layer, not a generic SDK.
- `prompts/scoria-brand-book-deep-research.md` - Older brand research; consult only when consistent with `brandbook/brand-book.md`.

### Current Docs and Package Surface
- `mix.exs` - Current flat `docs/` extras, package file list, version, docs source ref, and docs config.
- `README.md` - GitHub/package front door and current flat docs links.
- `CHANGELOG.md` - Maintainer/release extra.
- `LICENSE` - Package extra.
- `docs/glossary.md` - Current vocabulary reference to migrate to `guides/reference/glossary.md`.
- `docs/adoption_lanes.md` - Current old-vocabulary adoption route doc; migrate to capabilities/route language.
- `docs/scoria_vs_external_llm_ops.md` - Current comparison guide.
- `docs/phoenix_runtime_example.md` - Current runtime example guide.
- `docs/bounded_handoffs.md` - Current bounded handoffs guide.
- `docs/semantic_fast_path.md` - Current old-vocabulary semantic cache guide.
- `docs/operator_verification.md` - Current old-vocabulary reviewer verification guide.
- `docs/connector_adoption.md` - Current connector adoption guide.
- `docs/support_copilot_gallery.md` - Current support copilot gallery.
- `docs/MAINTAINERS.md` - Current maintainer guide.
- `docs/design_system.md` - Dev-only docs; do not surface in adopter HexDocs unless deliberately packaged.
- `docs/docker_dev_dx.md` - Dev-only docs; do not surface in adopter HexDocs unless deliberately packaged.
- `docs/uat_automation.md` - Dev-only docs; do not surface in adopter HexDocs unless deliberately packaged.

### Current Code and Tests
- `lib/scoria.ex` - Public facade and likely first API page.
- `lib/scoria/identity.ex` - Public identity/scope helper.
- `lib/scoria/runtime.ex` - Runtime entry point.
- `lib/scoria/runtime/run_summary.ex` - Public runtime result data surface candidate.
- `lib/scoria/runtime/run_detail.ex` - Public runtime detail data surface candidate.
- `lib/scoria/verification_suites.ex` - Public verification suite API.
- `lib/scoria/semantic_cache.ex` - Semantic cache public surface.
- `lib/scoria/semantic_cache/profile.ex` - Semantic cache profile public surface.
- `lib/scoria/knowledge.ex` - Optional knowledge public surface.
- `lib/scoria/connectors.ex` - Connector public surface.
- `lib/scoria/connectors/auth.ex` - Connector auth public surface.
- `lib/scoria/mcp/tool.ex` - MCP tool public surface.
- `lib/scoria/eval.ex` - Eval public surface candidate.
- `lib/scoria/prompt_policy.ex` - Prompt policy public surface candidate.
- `lib/scoria/prompt_registry.ex` - Prompt registry public surface candidate.
- `lib/scoria/req/steps.ex` - Req integration public surface candidate.
- `lib/scoria/sre.ex` - SRE public surface candidate.
- `lib/scoria/sre/alert_sink.ex` - SRE integration public surface candidate.
- `lib/scoria/sre/audit_sink.ex` - SRE integration public surface candidate.
- `lib/scoria_web/router.ex` - Dashboard mount integration point.
- `lib/scoria_web/dashboard_scope.ex` - Dashboard scope integration point.
- `lib/scoria_web/reviewer_surface.ex` - Reviewer dashboard public surface candidate.
- `lib/scoria/observe/reviewer_broadcast.ex` - Reviewer broadcast public surface candidate.
- `test/scoria/package_surface_test.exs` - Current package/docs surface contract with flat extras and source-ref assumptions.
- `lib/mix/tasks/scoria.release_preview.ex` - Release-preview task that currently checks the flat package/docs surface.
- `test/mix/tasks/scoria.release_preview_test.exs` - Release-preview contract tests that must move with the new docs surface.
- `test/scoria/terminology_contract_test.exs` - Terminology expectations that should stay consistent with Phase 46 vocabulary.

### Local Exemplar Repositories
- `/Users/jon/projects/lattice_stripe/mix.exs` - Good local pattern: `main: "getting-started"`, dynamic dev source refs, explicit groups, docs warning gate.
- `/Users/jon/projects/lattice_stripe/guides/` - Good local pattern for a "choose your route" guide ladder.
- `/Users/jon/projects/sigra/mix.exs` - Good local pattern for deeper Diataxis-style grouping; use as a future-state reference, not the default Phase 48 tree.
- `/Users/jon/projects/scrypath/mix.exs` - Good local pattern for docs URLs, source refs, and package/docs metadata.
- `/Users/jon/projects/mailglass/mix.exs` - Good local pattern for logo/favicon docs config and compact guide grouping.
- `/Users/jon/projects/oban_powertools/` - Good local pattern for operator/runbook-heavy docs language; adapt to reviewer vocabulary.

### Official and Ecosystem References
- `https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html` - Current `mix docs` behavior and warnings-as-errors option.
- `https://hexdocs.pm/ex_doc/ExDoc.html` - Current ExDoc options for extras, groups, redirects, source URLs/refs, logo/favicon, and formatters.
- `https://github.com/elixir-lang/ex_doc/blob/main/README.md` - ExDoc feature set and current docs UX expectations.
- `https://hexdocs.pm/elixir/writing-documentation.html` - Elixir guidance: docs are API contracts; hide internals with `@moduledoc false` or `@doc false`.
- `https://hexdocs.pm/phoenix/overview.html` - Phoenix guide organization as ecosystem precedent.
- `https://hexdocs.pm/ecto/getting-started.html` - Ecto onboarding pattern as ecosystem precedent.
- `https://preview.hex.pm/preview/phoenix_live_dashboard/show/README.md` - Phoenix LiveDashboard install/dashboard docs pattern.
- `https://diataxis.fr/` - Four documentation needs: tutorial, how-to, reference, explanation.
- `https://docs.djangoproject.com/en/6.0/` - Mature cross-language precedent for tutorial/topic/reference/how-to organization.
- `https://guides.rubyonrails.org/` - Mature cross-language precedent for grouped guide index and "Start Here" first-run docs.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `brandbook/logo-mark.svg` and `brandbook/favicon.svg`: ready for ExDoc `logo` and `favicon`.
- `brandbook/logo-primary.svg` and `brandbook/logo-primary-light.svg`: package assets for docs/README brand consistency.
- Existing `docs/*.md` files: source material for the new guide ladder; most Phase 48 work should be migration, renaming, re-linking, and polishing rather than writing from scratch.
- Existing package/release-preview tests: good contract points, but their hardcoded flat path assumptions must change.

### Established Patterns
- Scoria docs are treated as public API, not prose garnish. Phase 46 and 47 already established that naming, scope doctrine, and README positioning are compatibility-sensitive.
- "Scoria owns the verb; host owns the noun" should shape docs examples. Avoid implying Scoria owns customer domain objects.
- "Default runtime first, optional capabilities later" should shape guide order. Do not force new adopters to understand knowledge, semantic cache, connectors, or SRE surfaces before they have the basic runtime/dashboard path working.
- The brand voice is calm, precise, field-engineer oriented, and operator-grade. Avoid hype, vague AI claims, and backend-guts-first explanations.

### Integration Points
- `mix.exs` must become the source of truth for ExDoc extras, groups, metadata, package files, and source refs.
- README docs links must point to canonical `guides/` paths after migration.
- Public moduledocs should link to canonical guide labels/paths. If a guide path moves, update ExDoc redirects and README/module links together.
- Package surface tests and release-preview tests must assert the new structure so future docs edits do not silently break HexDocs or Hex package contents.
- If `DevLab.*` or dev-only modules leak into docs through the docs compile environment, add a `:docs` elixirc path or `filter_modules`/`@moduledoc false` strategy. Prefer `@moduledoc false` for true internals because Elixir docs treat public moduledocs as contracts.

</code_context>

<specifics>
## Specific Ideas

The chosen architecture deliberately combines the best parts of the options considered:
- From Phoenix/Ecto/Rails/Django: a visible first-run guide path, then task/domain groups, then reference.
- From ExDoc's own feature set: explicit `groups_for_extras`, `groups_for_modules`, `extra_section: "Guides"`, `redirects`, `logo`, `favicon`, and source-link metadata.
- From local sibling libraries: `lattice_stripe`'s `main: "getting-started"` and dynamic dev source ref; `scrypath`'s docs URL/source URL shape; `mailglass`'s compact guide grouping and brand assets; `sigra`'s deeper tree as a future scaling reference.
- From Phase 47: README stays a first-screen scope and positioning surface; HexDocs becomes the deeper product manual.
- From Phase 46: all public docs must use reviewer/capabilities/semantic cache/scoped context language, with old lane/operator names contained in compatibility notes.

Subagent research converged on the same path: shallow `guides/` migration with compatibility stubs and redirects; `main: "getting-started"`; dynamic source refs; consumer-journey module taxonomy; curated public API surface; docs/package tests updated to prevent drift.

</specifics>

<deferred>
## Deferred Ideas

- Phase 49 owns AI integration docs, docs-as-eval ideas, AI-specific guide surfaces, and any `llms.txt`/agent documentation policy beyond what ExDoc generates automatically.
- Phase 50 owns release publishing, release announcement copy, final version cutover, and any Hex.pm publish choreography.
- Full warning-as-error CI enforcement for docs can be added later unless Phase 48 can do it without creating a broad warning cleanup project.
- A fully nested Diataxis source tree can wait until Scoria has enough stable guides to make those folders earn their keep.
- New dashboard UI/UX work is out of scope. Phase 48 may improve docs screenshots/links only if existing assets already support it.

</deferred>

---

*Phase: 48-ExDoc and guide ladder restructure*
*Context gathered: 2026-07-10*
