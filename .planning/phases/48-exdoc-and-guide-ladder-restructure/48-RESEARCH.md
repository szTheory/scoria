# Phase 48: ExDoc and Guide Ladder Restructure - Research

**Researched:** 2026-07-10 [VERIFIED: system date]
**Domain:** Elixir ExDoc/HexDocs documentation information architecture, guide migration, source metadata, and docs/package contracts [VERIFIED: .planning/phases/48-exdoc-and-guide-ladder-restructure/48-CONTEXT.md]
**Confidence:** MEDIUM [VERIFIED: GSD research-plan used websearch-verified official docs because Context7 CLI/MCP was unavailable]

<user_constraints>
## User Constraints (from CONTEXT.md)

All content in this section is copied from `.planning/phases/48-exdoc-and-guide-ladder-restructure/48-CONTEXT.md`; treat it as locked project input for planning. [VERIFIED: .planning/phases/48-exdoc-and-guide-ladder-restructure/48-CONTEXT.md]

### Locked Decisions

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

### the agent's Discretion
The user delegated the final recommendations after asking to consider all options through architecture, DX, ecosystem, UI/UX, brand, and user-psychology lenses. Downstream agents may choose exact helper/function names and exact implementation factoring, but should preserve the decisions above unless blocked by live code constraints.

### Deferred Ideas (OUT OF SCOPE)

- Phase 49 owns AI integration docs, docs-as-eval ideas, AI-specific guide surfaces, and any `llms.txt`/agent documentation policy beyond what ExDoc generates automatically.
- Phase 50 owns release publishing, release announcement copy, final version cutover, and any Hex.pm publish choreography.
- Full warning-as-error CI enforcement for docs can be added later unless Phase 48 can do it without creating a broad warning cleanup project.
- A fully nested Diataxis source tree can wait until Scoria has enough stable guides to make those folders earn their keep.
- New dashboard UI/UX work is out of scope. Phase 48 may improve docs screenshots/links only if existing assets already support it.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOCS-01 | A Phoenix adopter can navigate ExDoc through grouped modules and grouped extras instead of one flat sidebar. [VERIFIED: .planning/REQUIREMENTS.md] | Use ExDoc `groups_for_extras` and `groups_for_modules`; current `mix.exs` has flat extras and no grouping. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] [VERIFIED: mix.exs] |
| DOCS-02 | ExDoc source links, release docs links, logo/favicon metadata, and markdown/html formatter settings are version-aware and do not point `-dev` docs at missing tag URLs. [VERIFIED: .planning/REQUIREMENTS.md] | ExDoc derives GitHub source links from `source_url` plus `source_ref`, defaults `source_ref` to `main`, accepts SVG `logo`/`favicon`, and supports explicit `formatters`; current Scoria hard-codes `source_ref: "v#{@version}"`. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] [VERIFIED: mix.exs] |
| DOCS-03 | Stable adopter guides are organized into a clear guide ladder covering getting started, golden path, user flows/JTBD, troubleshooting, hosted-LLM-ops comparison, and a cheatsheet. [VERIFIED: .planning/REQUIREMENTS.md] | Use the locked shallow `guides/` ladder and migrate current stable `docs/*.md` material; current repo has no `guides/` directory and has the source material in flat `docs/*.md`. [VERIFIED: 48-CONTEXT.md] [VERIFIED: find docs guides] |
</phase_requirements>

## Summary

Phase 48 is a documentation IA and contract phase, not a runtime feature phase: the plan should update `mix.exs`, migrate stable adopter guides from flat `docs/*.md` into the locked shallow `guides/` ladder, preserve old public links with stubs plus ExDoc redirects, curate the public module sidebar, and update package/release-preview tests so the new surface stays stable. [VERIFIED: 48-CONTEXT.md] [VERIFIED: mix.exs] [VERIFIED: test/scoria/package_surface_test.exs]

The current code is still on the old structure: `mix.exs` sets `main: "readme"`, hard-codes `source_ref: "v#{@version}"`, lists flat `docs/*.md` extras, and the package/release-preview tests assert that same flat list. [VERIFIED: mix.exs] [VERIFIED: test/scoria/package_surface_test.exs] [VERIFIED: lib/mix/tasks/scoria.release_preview.ex] ExDoc 0.40.3 supports the needed primitives directly: grouped extras/modules, extensionless redirects, Markdown output, SVG logo/favicon, and inferred GitHub source links from `source_url` plus `source_ref`. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html]

**Primary recommendation:** Plan this as a RED-contract-first docs migration: update/extend the contract tests for the new ladder, grouping, redirects, dynamic source refs, and package assets; then migrate guide files and ExDoc config; then regenerate docs/package preview and run focused contracts plus `mix scoria.release_preview`. [VERIFIED: 48-CONTEXT.md] [VERIFIED: focused test runs 2026-07-10]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| HexDocs entry, extras, groups, redirects, source links, formatters, logo, favicon | Build/Package Config | Static Docs Output | `mix.exs` owns ExDoc and Hex package metadata, while `mix docs` materializes static HTML/Markdown output. [VERIFIED: mix.exs] [CITED: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html] |
| Guide ladder content and compatibility stubs | Repository Docs | Static Docs Output | Markdown source files are canonical in the repo, and ExDoc renders only files listed in `extras`. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |
| Old HexDocs page compatibility | Static Docs Output | Build/Package Config | ExDoc `redirects` generates static redirects for old extensionless page IDs, while old source-path stubs preserve copied GitHub links. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] [VERIFIED: 48-CONTEXT.md] |
| Public API reference curation | Library Source | Build/Package Config | Public modules expose `@moduledoc` contracts, while `filter_modules`, `@moduledoc false`, and `groups_for_modules` control ExDoc visibility and grouping. [CITED: https://hexdocs.pm/elixir/writing-documentation.html] [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |
| Package surface validation | Test Suite | Build/Package Config | Existing ExUnit tests already assert docs extras, package paths, source ref, and release-preview inventory; those tests need new expected contracts. [VERIFIED: test/scoria/package_surface_test.exs] [VERIFIED: test/mix/tasks/scoria.release_preview_test.exs] |

## Project Constraints

No root `AGENTS.md`, `CLAUDE.md`, `.claude/CLAUDE.md`, `.claude/skills/*/SKILL.md`, or `.agents/skills/*/SKILL.md` was found in `/Users/jon/projects/scoria`; nested `AGENTS.md` files exist only under vendored example dependencies and were excluded from project-root constraints. [VERIFIED: hidden-aware file discovery] [VERIFIED: find . -maxdepth 3]

`workflow.nyquist_validation` is absent from `.planning/config.json`, so validation architecture is included. [VERIFIED: .planning/config.json]

`security_enforcement` is absent from `.planning/config.json`, so security-domain review is included. [VERIFIED: .planning/config.json]

## Standard Stack

### Core

| Library/Tool | Version | Purpose | Why Standard |
|--------------|---------|---------|--------------|
| Elixir / Mix | Elixir 1.19.5, Mix 1.19.5, Erlang/OTP 28 | Compiles the library, runs ExUnit, and runs `mix docs`/`mix hex.build`. | This is the local project toolchain used during research. [VERIFIED: mix --version] |
| ExDoc | 0.40.3 locked, current on Hex as of 2026-07-10 | Generates HexDocs HTML/Markdown output, grouped sidebars, extras, source links, redirects, logo, favicon, and generated Markdown artifacts. | It is the existing docs generator dependency and supports every locked Phase 48 docs feature without new packages. [VERIFIED: mix deps] [CITED: https://hex.pm/packages/ex_doc] [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |
| Hex | 2.5.0 archive | Builds and unpacks local Hex package previews. | `mix hex.build --unpack --output ...` is already used by `mix scoria.release_preview`. [VERIFIED: mix help hex.build] [VERIFIED: lib/mix/tasks/scoria.release_preview.ex] |
| ExUnit | Built into Elixir 1.19.5 | Runs docs, package, terminology, and release-preview contract tests. | Existing focused tests are green and cover the surfaces Phase 48 must change. [VERIFIED: focused test runs 2026-07-10] |

### Supporting

| Library/Tool | Version | Purpose | When to Use |
|--------------|---------|---------|-------------|
| Git | 2.41.0 | Detect whether the current build is exactly at tag `v#{@version}` for `docs_source_ref/0`. | Use in the helper only for exact-tag detection; fall back to `"main"` when not at the matching tag. [VERIFIED: git --version] [VERIFIED: 48-CONTEXT.md] |
| Brand SVG assets | Existing tracked files | Provide ExDoc `logo`, `favicon`, and package brand assets. | Use `brandbook/logo-mark.svg`, `brandbook/favicon.svg`, `brandbook/logo-primary.svg`, and `brandbook/logo-primary-light.svg`. [VERIFIED: git ls-files brandbook] [VERIFIED: 48-CONTEXT.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| ExDoc inferred GitHub source links | Custom `source_url_pattern` | Not needed for normal `github.com` hosting because ExDoc derives the pattern from `source_url` and `source_ref`; custom patterns are for self-hosted or unsupported source hosts. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |
| Shallow `guides/` ladder | Fully nested Diataxis tree | Deferred by locked decision because current stable guide count does not justify deeper physical folders. [VERIFIED: 48-CONTEXT.md] |
| Compatibility stubs plus ExDoc redirects | Only moving files | Moving extras without redirects breaks old static HexDocs page URLs, and moving source files without stubs breaks copied GitHub source links. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] [VERIFIED: 48-CONTEXT.md] |

**Installation:**

No new package installation is required for Phase 48 because `:ex_doc` is already in `mix.exs` and locked at 0.40.3. [VERIFIED: mix.exs] [VERIFIED: mix deps]

```bash
# Only needed if local deps are missing:
mix deps.get
```

## Package Legitimacy Audit

Phase 48 should not install new external packages; it should use the existing `:ex_doc` dev dependency and existing Elixir/Mix/Hex tooling. [VERIFIED: mix.exs] [VERIFIED: 48-CONTEXT.md]

The GSD package-legitimacy seam available in this session accepts `npm`, `pypi`, and `crates`, but not Hex, so `ex_doc` was verified through Hex package metadata, the local lock, `mix hex.info`, and `mix hex.outdated` instead of a seam verdict. [VERIFIED: package-legitimacy usage output] [VERIFIED: mix deps] [VERIFIED: mix hex.info ex_doc] [VERIFIED: mix hex.outdated ex_doc]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `ex_doc` | Hex | Version 0.40.3 was updated May 21, 2026. [CITED: https://hex.pm/packages/ex_doc] | Hex showed 262,783 last-30-day downloads and `mix hex.info` showed 97,770,341 all-time downloads. [CITED: https://hex.pm/packages/ex_doc] [VERIFIED: mix hex.info ex_doc] | `https://github.com/elixir-lang/ex_doc`. [CITED: https://hex.pm/packages/ex_doc] | Existing dependency, current, authoritative package. [VERIFIED: mix hex.outdated ex_doc] | Approved; no install task needed. [VERIFIED: mix.exs] |

**Packages removed due to [SLOP] verdict:** none; no new packages are proposed. [VERIFIED: package audit scope]
**Packages flagged as suspicious [SUS]:** none; no new packages are proposed. [VERIFIED: package audit scope]

## Architecture Patterns

### System Architecture Diagram

```text
Maintainer edits docs + mix.exs
        |
        v
Contract tests define expected guide ladder, groups, redirects, source refs, package files
        |
        v
mix.exs docs()/package()
        |-----------------------------|
        v                             v
ExDoc retriever + extras builder      Hex package file list
        |                             |
        v                             v
HTML + Markdown HexDocs output        mix hex.build --unpack preview
        |                             |
        v                             v
Static pages, sidebar groups,         Package contains canonical guides,
source links, redirects, logo,        README, changelog/license, brand assets,
favicon                              and compatibility stubs
        |
        v
Adopter navigates Start Here -> capabilities -> operate/verify -> reference
```

The primary decision point is whether a file is canonical guide content, compatibility-only source stub, maintainer-only packaged content, or repo-only dev documentation. [VERIFIED: 48-CONTEXT.md]

### Recommended Project Structure

```text
guides/
├── getting-started.md
├── golden-path.md
├── jtbd-and-user-flows.md
├── ownership-boundary.md
├── capabilities/
│   ├── default-runtime.md
│   ├── bounded-handoffs.md
│   ├── semantic-cache.md
│   ├── connectors-and-mcp.md
│   └── support-copilot-gallery.md
├── reviewer-verification.md
├── troubleshooting.md
├── scoria-vs-external-llm-ops.md
├── cheatsheet.cheatmd
├── reference/
│   └── glossary.md
└── maintainers.md

docs/
├── semantic_fast_path.md        # compatibility stub, excluded from ExDoc extras
├── operator_verification.md     # compatibility stub, excluded from ExDoc extras
└── ...                          # compatibility stubs for copied old source links
```

This structure is locked by Phase 48 context and should be the planner default. [VERIFIED: 48-CONTEXT.md]

### Pattern 1: ExDoc Config as the Docs SSOT

**What:** Put docs metadata, extras, groups, redirects, source refs, and brand assets behind `docs/0` in `mix.exs`, and make package file inclusion align with the same canonical guide list. [VERIFIED: 48-CONTEXT.md] [VERIFIED: mix.exs]

**When to use:** Use this for all Phase 48 ExDoc and Hex package surface changes. [VERIFIED: 48-CONTEXT.md]

**Example:**

```elixir
# Source: ExDoc options documented at https://hexdocs.pm/ex_doc/ExDoc.html
defp docs do
  [
    main: "getting-started",
    source_url: @source_url,
    source_ref: docs_source_ref(),
    extra_section: "Guides",
    formatters: ["html", "markdown"],
    logo: "brandbook/logo-mark.svg",
    favicon: "brandbook/favicon.svg",
    extras: docs_extras(),
    groups_for_extras: docs_extra_groups(),
    groups_for_modules: docs_module_groups(),
    redirects: docs_redirects()
  ]
end
```

### Pattern 2: Compatibility Stubs Plus Extensionless Redirects

**What:** Keep old `docs/*.md` source paths as thin stubs for copied GitHub links, omit those stubs from ExDoc `extras`, and map old generated page IDs to new page IDs with ExDoc `redirects`. [VERIFIED: 48-CONTEXT.md] [CITED: https://hexdocs.pm/ex_doc/ExDoc.html]

**When to use:** Use this whenever a canonical guide source path or generated HexDocs page ID changes. [VERIFIED: 48-CONTEXT.md]

**Example:**

```elixir
# Source: ExDoc redirects omit file extensions; anchors are allowed.
defp docs_redirects do
  %{
    "semantic_fast_path" => "semantic-cache",
    "operator_verification" => "reviewer-verification",
    "adoption_lanes" => "capabilities/default-runtime"
  }
end
```

### Pattern 3: Dynamic Source Ref Helper

**What:** Resolve source links from `SCORIA_DOCS_SOURCE_REF`, exact matching git tag, or `"main"` in that order. [VERIFIED: 48-CONTEXT.md]

**When to use:** Use this in `docs/0` and test all three branches without requiring real network access. [VERIFIED: 48-CONTEXT.md]

**Example:**

```elixir
# Source: Phase 48 D-07; ExDoc source_ref semantics documented at https://hexdocs.pm/ex_doc/ExDoc.html
defp docs_source_ref do
  cond do
    ref = System.get_env("SCORIA_DOCS_SOURCE_REF") ->
      ref

    building_release_tag?("v#{@version}") ->
      "v#{@version}"

    true ->
      "main"
  end
end
```

### Anti-Patterns to Avoid

- **Duplicating guide path lists across `mix.exs`, tests, and release-preview tasks:** This already exists in the flat docs setup and Phase 48 D-21 explicitly warns against drift. [VERIFIED: mix.exs] [VERIFIED: test/scoria/package_surface_test.exs] [VERIFIED: 48-CONTEXT.md]
- **Surfacing compatibility stubs in ExDoc extras:** This duplicates sidebar pages and undermines the new guide ladder. [VERIFIED: 48-CONTEXT.md]
- **Leaving `source_ref: "v#{@version}"` for unreleased main builds:** ExDoc expects the referenced tag to exist for version-specific source links, and the current generated `doc/` output shows links to `blob/v0.1.2/...`. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] [VERIFIED: doc/*.html grep]
- **Using `@doc false` as a visibility substitute for internal modules:** Elixir warns that `@doc false` does not make functions private and recommends moving internals into hidden modules or using leading-underscore names where appropriate. [CITED: https://hexdocs.pm/elixir/writing-documentation.html]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Static redirect pages for old HexDocs IDs | Custom HTML files or Phoenix routes | ExDoc `redirects` | ExDoc directly supports extensionless old-to-new redirects and anchors in static docs. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |
| Source URL construction for GitHub | Custom `source_url_pattern` | `source_url` plus dynamic `source_ref` | ExDoc derives GitHub patterns automatically for normal `github.com` URLs. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |
| Sidebar grouping | Custom generated nav files | `groups_for_extras` and `groups_for_modules` | ExDoc already groups extras/modules in generated sidebars. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |
| Internal-module hiding | Regex-only docs filtering as the sole control | `@moduledoc false` for true internals plus `filter_modules` where needed | Elixir docs treat public documentation as an API contract, and hidden modules are ignored by docs tooling. [CITED: https://hexdocs.pm/elixir/writing-documentation.html] |
| Package preview checks | Ad hoc shell checks | Existing `mix scoria.release_preview` plus ExUnit contracts | The release-preview task already builds docs and unpacks the Hex package before asserting required paths. [VERIFIED: lib/mix/tasks/scoria.release_preview.ex] |

**Key insight:** ExDoc already owns the hard parts of docs navigation, redirects, source links, and generated Markdown; Phase 48 should spend effort on Scoria's information architecture and drift-proof contracts instead of custom docs tooling. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] [VERIFIED: 48-CONTEXT.md]

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | None found for docs path names in migrations or runtime datastores; old strings are present in source/tests/docs, not database rows. [VERIFIED: rg priv/repo priv/fixtures lib test docs] | No data migration; update source docs/tests/contracts only. [VERIFIED: runtime-state audit] |
| Live service config | No external live service config was found in the repo for old guide paths; public HexDocs/GitHub links copied by users are the relevant external state. [VERIFIED: rg .github docs README mix.exs] | Preserve copied source links with `docs/*.md` stubs and preserve old HexDocs URLs with ExDoc `redirects`. [VERIFIED: 48-CONTEXT.md] [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |
| OS-registered state | No launchd, systemd user, or pm2 entries matching Scoria docs path names were found. [VERIFIED: launchctl/systemctl/pm2 probes] | No OS re-registration. [VERIFIED: runtime-state audit] |
| Secrets/env vars | `.env`, `.env.example`, `.env.op.example`, compose files, and current environment did not contain old guide path names or `SCORIA_DOCS_SOURCE_REF`. [VERIFIED: env/compose grep] | Add `SCORIA_DOCS_SOURCE_REF` support in code/tests only; no secret rename is required. [VERIFIED: 48-CONTEXT.md] |
| Build artifacts | Local `doc/` and `tmp/scoria-release-preview/` exist and embed old page IDs/source links such as `adoption_lanes`, `semantic_fast_path`, `operator_verification`, and `blob/v0.1.2/...`. [VERIFIED: rg doc tmp] | Regenerate docs and release preview after migration; do not use stale generated artifacts as proof. [VERIFIED: runtime-state audit] |

## Common Pitfalls

### Pitfall 1: Moving Guides Without Redirects

**What goes wrong:** Existing HexDocs links such as `semantic_fast_path.html` or `operator_verification.html` return 404 after source files move. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html]  
**Why it happens:** ExDoc generated page IDs are based on extra filenames unless overridden, and static docs hosts show 404 for missing pages. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html]  
**How to avoid:** Add extensionless `redirects` from old IDs to new target IDs and test the redirect map. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html]  
**Warning signs:** Old docs IDs appear in README/moduledocs/tests after the new `guides/` ladder is introduced. [VERIFIED: rg README.md docs lib test]

### Pitfall 2: Source Links Point at Missing Tags

**What goes wrong:** Dev or main-branch docs point to `github.com/szTheory/scoria/blob/v0.1.2/...` even when the changed docs only exist on `main`. [VERIFIED: doc/*.html grep]  
**Why it happens:** Current `mix.exs` hard-codes `source_ref: "v#{@version}"`. [VERIFIED: mix.exs]  
**How to avoid:** Implement `docs_source_ref/0` with env override, exact tag detection, and `"main"` fallback. [VERIFIED: 48-CONTEXT.md]  
**Warning signs:** `project[:docs][:source_ref] == "v#{project[:version]}"` remains in tests after Phase 48. [VERIFIED: test/scoria/package_surface_test.exs]

### Pitfall 3: Duplicate Path Lists Drift

**What goes wrong:** `mix.exs`, release-preview required paths, package tests, and README link assertions disagree after the guide migration. [VERIFIED: mix.exs] [VERIFIED: lib/mix/tasks/scoria.release_preview.ex] [VERIFIED: test/scoria/package_surface_test.exs]  
**Why it happens:** Current code repeats the same flat guide path list in multiple files. [VERIFIED: codebase grep]  
**How to avoid:** Introduce a single helper/list or a deliberate drift contract that compares the lists. [VERIFIED: 48-CONTEXT.md]  
**Warning signs:** Updating one guide path requires editing more than one hard-coded list. [VERIFIED: codebase grep]

### Pitfall 4: Public API Reference Exposes Internals

**What goes wrong:** Ecto schemas, LiveViews, controllers, copy helpers, dev tooling, and test-support modules appear as public API contracts. [VERIFIED: rg '^defmodule ' lib/scoria lib/scoria_web] [VERIFIED: 48-CONTEXT.md]  
**Why it happens:** ExDoc includes modules unless filtered or hidden, and documentation is an API contract for users. [CITED: https://hexdocs.pm/elixir/writing-documentation.html] [CITED: https://hexdocs.pm/ex_doc/ExDoc.html]  
**How to avoid:** Use `@moduledoc false` for true internals and `filter_modules`/`groups_for_modules` for curated public reference shape. [CITED: https://hexdocs.pm/elixir/writing-documentation.html] [CITED: https://hexdocs.pm/ex_doc/ExDoc.html]  
**Warning signs:** `ScoriaWeb.*Live`, controller, component, schema, warning, or support helper modules remain in the public API sidebar without an intentional group. [VERIFIED: 48-CONTEXT.md]

### Pitfall 5: Turning Phase 48 Into Broad Docs Warning Cleanup

**What goes wrong:** The phase expands into all `mix docs --warnings-as-errors` cleanup instead of the locked ExDoc/guide ladder restructure. [VERIFIED: 48-CONTEXT.md]  
**Why it happens:** ExDoc can fail on undefined references under `--warnings-as-errors`, and the repository has many existing docs and moduledocs. [CITED: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html] [VERIFIED: rg docs lib test]  
**How to avoid:** Add focused contracts now, keep `mix scoria.release_preview` passing, and defer broad WAE enforcement unless it is already green after focused edits. [VERIFIED: 48-CONTEXT.md]  
**Warning signs:** Planner adds a root CI docs-WAE gate before the guide migration contracts are green. [VERIFIED: 48-CONTEXT.md]

## Code Examples

### Docs Source Ref Helper

```elixir
# Source: Phase 48 D-07 and ExDoc source_ref docs.
defp docs_source_ref do
  env_ref = System.get_env("SCORIA_DOCS_SOURCE_REF")
  release_ref = "v#{@version}"

  cond do
    is_binary(env_ref) and env_ref != "" ->
      env_ref

    git_exact_ref?(release_ref) ->
      release_ref

    true ->
      "main"
  end
end

defp git_exact_ref?(ref) do
  case System.cmd("git", ["tag", "--points-at", "HEAD"], stderr_to_stdout: true) do
    {tags, 0} -> ref in String.split(tags)
    _ -> false
  end
end
```

### Groups for Extras

```elixir
# Source: Phase 48 D-10 and ExDoc groups_for_extras docs.
defp docs_extra_groups do
  [
    "Start Here": [
      "README.md",
      "guides/getting-started.md",
      "guides/golden-path.md",
      "guides/jtbd-and-user-flows.md",
      "guides/ownership-boundary.md",
      "guides/cheatsheet.cheatmd"
    ],
    "Capabilities": Path.wildcard("guides/capabilities/*.md"),
    "Operate & Verify": [
      "guides/reviewer-verification.md",
      "guides/troubleshooting.md"
    ],
    "Compare & Decide": ["guides/scoria-vs-external-llm-ops.md"],
    "Reference": ["guides/reference/glossary.md"],
    "Maintainers": ["guides/maintainers.md", "CHANGELOG.md", "LICENSE"]
  ]
end
```

### Contract Test Shape

```elixir
# Source: existing package_surface_test pattern plus Phase 48 D-20.
test "docs config exposes the guide ladder with redirects and dynamic source refs" do
  docs = Mix.Project.config()[:docs]

  assert docs[:main] == "getting-started"
  assert docs[:extra_section] == "Guides"
  assert "guides/getting-started.md" in docs[:extras]
  refute "docs/semantic_fast_path.md" in docs[:extras]
  assert docs[:redirects]["semantic_fast_path"] == "semantic-cache"
  assert docs[:formatters] == ["html", "markdown"]
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| HTML-only docs mindset | ExDoc 0.40 generates Markdown output and `llms.txt` by default, with copy-Markdown affordances. [CITED: https://hexdocs.pm/ex_doc/changelog.html] | ExDoc v0.40.0, 2026-01-20. [CITED: https://hexdocs.pm/ex_doc/changelog.html] | Phase 48 should keep `formatters: ["html", "markdown"]` and defer curated root AI docs to Phase 49. [VERIFIED: 48-CONTEXT.md] |
| Manual static compatibility pages | ExDoc `redirects` with extensionless IDs and anchor targets. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] | Redirect anchors are documented in ExDoc v0.40.0 changelog. [CITED: https://hexdocs.pm/ex_doc/changelog.html] | Old HexDocs page IDs can be preserved without custom HTML files. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |
| Implicit logo-as-favicon behavior | Explicit `logo` and `favicon` options. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] | Favicon support appears in ExDoc v0.37.0 changelog. [CITED: https://hexdocs.pm/ex_doc/changelog.html] | Configure both `brandbook/logo-mark.svg` and `brandbook/favicon.svg`. [VERIFIED: 48-CONTEXT.md] |
| Flat module and page sidebar | Explicit `groups_for_modules` and `groups_for_extras`. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] | Current ExDoc 0.40.3 supports both group options. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] | Use reader-job groups for extras and consumer-journey groups for modules. [VERIFIED: 48-CONTEXT.md] |

**Deprecated/outdated:**
- Keeping `main: "readme"` as HexDocs entry is outdated for this phase because Phase 48 locks `main: "getting-started"`. [VERIFIED: 48-CONTEXT.md] [VERIFIED: mix.exs]
- Keeping `docs/*.md` files as canonical guide sources is outdated for this phase because Phase 48 locks a canonical `guides/` ladder with `docs/*.md` compatibility stubs only. [VERIFIED: 48-CONTEXT.md]
- Keeping `source_ref: "v#{@version}"` unconditionally is outdated for this phase because Phase 48 locks dynamic source-ref behavior. [VERIFIED: 48-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | No `[ASSUMED]` claims are used in this research. [VERIFIED: manual source-tag review] | All | None from assumptions; remaining risks are implementation choices and stale future package docs. [VERIFIED: manual source-tag review] |

## Open Questions (RESOLVED)

1. **RESOLVED: Exact generated target IDs for redirects**  
   - Decision: Use extensionless basename IDs derived from the canonical guide filenames, with no per-extra `filename:` overrides planned for redirect targets. Plan 07 locks this map in `docs_redirects/0`: `adoption_lanes` -> `jtbd-and-user-flows`, `phoenix_runtime_example` -> `golden-path`, `bounded_handoffs` -> `bounded-handoffs`, `semantic_fast_path` -> `semantic-cache`, `operator_verification` -> `reviewer-verification`, `connector_adoption` -> `connectors-and-mcp`, `support_copilot_gallery` -> `support-copilot-gallery`, `scoria_vs_external_llm_ops` -> `scoria-vs-external-llm-ops`, and `MAINTAINERS` -> `maintainers`. Plan 01 locks RED redirect coverage before moving content. [VERIFIED: 48-CONTEXT.md] [VERIFIED: 48-01-PLAN.md] [VERIFIED: 48-07-PLAN.md]

2. **RESOLVED: How aggressive `filter_modules` should be on first pass**  
   - Decision: Use a positive public-module allowlist in `mix.exs` through `docs_public_modules/0` and `docs_public_module?/2`. The visible set starts from D-13 and D-17, adds runtime summary/detail DTOs needed by public APIs, and keeps D-15 compatibility wrappers visible in a dedicated Compatibility Aliases group. Implementation details named by D-14 stay hidden or filtered. Plans 02, 07, 08, and 09 create the contracts, ExDoc config, and public moduledoc updates for that allowlist. [VERIFIED: 48-CONTEXT.md] [VERIFIED: 48-02-PLAN.md] [VERIFIED: 48-07-PLAN.md] [VERIFIED: 48-08-PLAN.md] [VERIFIED: 48-09-PLAN.md]

3. **RESOLVED: Whether docs warning-as-error can be added now**  
   - Decision: Phase 48 does not add a broad `mix docs --warnings-as-errors` CI or phase gate. D-22 and Plan 10 set the Phase 48 gate to the focused docs/package contract suite, `mix scoria.release_preview`, and generated docs assertions. The broader warning-clean docs command remains owned by Phase 49's DOCS-04 requirement and Phase 50 release hardening. [VERIFIED: 48-CONTEXT.md] [VERIFIED: 48-10-PLAN.md] [VERIFIED: .planning/REQUIREMENTS.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Compilation, ExUnit, `mix docs` | Yes | 1.19.5 | None needed. [VERIFIED: elixir --version] |
| Mix | Docs/package/test tasks | Yes | 1.19.5 | None needed. [VERIFIED: mix --version] |
| Erlang/OTP | Elixir runtime | Yes | OTP 28 | None needed. [VERIFIED: mix --version] |
| ExDoc | HexDocs generation | Yes | 0.40.3 locked and current | Use existing dependency; no install needed. [VERIFIED: mix deps] [VERIFIED: mix hex.outdated ex_doc] |
| Hex | Package preview | Yes | 2.5.0 archive | Existing `mix hex.build --unpack` task is available. [VERIFIED: mix help hex.build] |
| Git | Source-ref exact-tag detection | Yes | 2.41.0 | Fall back to `"main"` if git command fails. [VERIFIED: git --version] [VERIFIED: 48-CONTEXT.md] |
| Brand assets | ExDoc logo/favicon and package assets | Yes | SVG files in `brandbook/` | Planner should fail contract tests if any required asset is missing. [VERIFIED: git ls-files brandbook] |

**Missing dependencies with no fallback:** none found for Phase 48. [VERIFIED: environment probes]

**Missing dependencies with fallback:** Context7 CLI/MCP was unavailable, so official docs were fetched via websearch/open and cached through the GSD research seam. [VERIFIED: command -v ctx7] [VERIFIED: GSD research-store put]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Elixir 1.19.5. [VERIFIED: mix --version] |
| Config file | `test/test_helper.exs` exists as part of the existing ExUnit suite. [VERIFIED: git ls-files test/test_helper.exs] |
| Quick run command | `MIX_ENV=test mix test test/scoria/package_surface_test.exs test/mix/tasks/scoria.release_preview_test.exs` [VERIFIED: focused test run 2026-07-10] |
| Full phase docs command | `mix scoria.release_preview` should remain passing after migration. [VERIFIED: 48-CONTEXT.md] [VERIFIED: lib/mix/tasks/scoria.release_preview.ex] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| DOCS-01 | ExDoc docs config groups modules and extras instead of a flat sidebar. [VERIFIED: .planning/REQUIREMENTS.md] | Unit/contract | `MIX_ENV=test mix test test/scoria/package_surface_test.exs -x` | Exists but currently asserts old flat extras; update in Wave 0. [VERIFIED: test/scoria/package_surface_test.exs] |
| DOCS-02 | Source/ref/doc links, release docs URLs, logo/favicon, and `["html", "markdown"]` formatters are configured with dynamic dev source refs. [VERIFIED: .planning/REQUIREMENTS.md] | Unit/contract | `MIX_ENV=test mix test test/scoria/package_surface_test.exs test/mix/tasks/scoria.release_preview_test.exs -x` | Exists but currently asserts `source_ref == "v#{version}"`; update in Wave 0. [VERIFIED: test/scoria/package_surface_test.exs] |
| DOCS-03 | Stable guide ladder exists and README/moduledoc links point at canonical `guides/` paths. [VERIFIED: .planning/REQUIREMENTS.md] | Unit/contract | `MIX_ENV=test mix test test/scoria/terminology_contract_test.exs test/scoria/adoption_surface_test.exs -x` | Exists but currently references flat `docs/*.md`; update in Wave 0. [VERIFIED: test/scoria/terminology_contract_test.exs] [VERIFIED: test/scoria/adoption_surface_test.exs] |

### Sampling Rate

- **Per task commit:** Run the focused contract for the touched surface, starting with `MIX_ENV=test mix test test/scoria/package_surface_test.exs test/mix/tasks/scoria.release_preview_test.exs`. [VERIFIED: focused test run 2026-07-10]
- **Per wave merge:** Run package/release-preview contracts plus stable docs terminology/adoption contracts. [VERIFIED: focused test run 2026-07-10]
- **Phase gate:** Run `mix scoria.release_preview` plus the updated focused contracts before `$gsd-verify-work`. [VERIFIED: 48-CONTEXT.md]

### Wave 0 Gaps

- [ ] Update or add a docs surface contract for `main`, `extra_section`, `formatters`, `logo`, `favicon`, `groups_for_extras`, `groups_for_modules`, `redirects`, and dynamic `docs_source_ref/0`. [VERIFIED: 48-CONTEXT.md] [VERIFIED: existing tests]
- [ ] Update package/release-preview required path contracts for canonical `guides/` files, compatibility `docs/*.md` stubs that must ship, and required brand assets. [VERIFIED: 48-CONTEXT.md] [VERIFIED: lib/mix/tasks/scoria.release_preview.ex]
- [ ] Update stable docs/adoption/terminology contracts from flat `docs/*.md` paths to canonical `guides/` paths while preserving legacy alias compatibility assertions. [VERIFIED: test/scoria/terminology_contract_test.exs] [VERIFIED: test/scoria/adoption_surface_test.exs]
- [ ] Add redirect coverage for old generated page IDs before moving content. [VERIFIED: 48-CONTEXT.md] [CITED: https://hexdocs.pm/ex_doc/ExDoc.html]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | No | Phase 48 does not change runtime authentication; docs must continue saying host auth owns reviewer identity. [VERIFIED: 48-CONTEXT.md] |
| V3 Session Management | No | Phase 48 does not change session handling; docs must preserve `session_id` versus `run_id` guidance. [VERIFIED: 48-CONTEXT.md] |
| V4 Access Control | Yes, documentation integrity only | Public docs must keep dashboard tenant scope host-authenticated rather than query-param selected. [VERIFIED: 48-CONTEXT.md] |
| V5 Input Validation | Yes | Treat docs paths, redirect IDs, package paths, and source-ref env override as explicit allow-list contracts; test existence and expected values. [VERIFIED: 48-CONTEXT.md] |
| V6 Cryptography | No | Phase 48 does not add cryptographic behavior; brand assets and docs config do not change crypto surfaces. [VERIFIED: 48-CONTEXT.md] |

### Known Threat Patterns for Docs/Package Surface

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Dev-only docs or internals shipped in adopter HexDocs/package | Information Disclosure | Explicit package file allow-list, `groups_for_modules`, `@moduledoc false`, and tests that keep dev-only docs out of extras. [VERIFIED: 48-CONTEXT.md] [CITED: https://hexdocs.pm/elixir/writing-documentation.html] |
| Source links point at missing or wrong refs | Repudiation/Tampering | Dynamic `docs_source_ref/0`, env override, exact tag detection, and tests for non-tag fallback. [VERIFIED: 48-CONTEXT.md] |
| Compatibility redirects send old docs IDs to wrong semantics | Spoofing/Information Integrity | Explicit redirect map reviewed against final file IDs and tested for every old public page ID. [VERIFIED: 48-CONTEXT.md] [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |
| Public moduledocs imply Scoria owns host auth/policy/business nouns | Elevation of Privilege/Information Integrity | Keep ownership-boundary links and host-owned auth/policy language in public docs and prioritized moduledocs. [VERIFIED: 48-CONTEXT.md] |

## Sources

### Primary (HIGH Confidence)

- Local project context: `.planning/phases/48-exdoc-and-guide-ladder-restructure/48-CONTEXT.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`. [VERIFIED: file reads]
- Local code contracts: `mix.exs`, `test/scoria/package_surface_test.exs`, `lib/mix/tasks/scoria.release_preview.ex`, `test/mix/tasks/scoria.release_preview_test.exs`, `test/scoria/terminology_contract_test.exs`, `test/scoria/adoption_surface_test.exs`. [VERIFIED: file reads]
- Local dependency/tooling: `mix deps`, `mix --version`, `mix help docs`, `mix help hex.build`, `git --version`. [VERIFIED: command outputs]

### Secondary (MEDIUM Confidence)

- ExDoc options and `mix docs`: https://hexdocs.pm/ex_doc/ExDoc.html and https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html. [CITED: official docs]
- ExDoc current package metadata: https://hex.pm/packages/ex_doc. [CITED: Hex package page]
- ExDoc changelog: https://hexdocs.pm/ex_doc/changelog.html. [CITED: official docs]
- Elixir writing documentation guide: https://hexdocs.pm/elixir/writing-documentation.html. [CITED: official docs]
- Diataxis framework: https://diataxis.fr/. [CITED: official docs]
- Phoenix guide overview and Ecto getting-started guide: https://hexdocs.pm/phoenix/overview.html and https://hexdocs.pm/ecto/getting-started.html. [CITED: official docs]

### Tertiary (LOW Confidence)

- None used for recommendations. [VERIFIED: source review]

## Metadata

**Confidence breakdown:**
- Standard stack: MEDIUM - ExDoc version and local lock were verified via local Mix/Hex, and current package metadata was checked on Hex; package-legitimacy seam has no Hex-specific OK verdict path in this session. [VERIFIED: mix deps] [CITED: https://hex.pm/packages/ex_doc]
- Architecture: HIGH - Phase architecture is mostly locked by Phase 48 context and existing local contracts. [VERIFIED: 48-CONTEXT.md] [VERIFIED: codebase grep]
- Pitfalls: MEDIUM - Pitfalls are supported by official ExDoc/Elixir docs plus local current-state evidence. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] [CITED: https://hexdocs.pm/elixir/writing-documentation.html] [VERIFIED: codebase grep]

**Research date:** 2026-07-10 [VERIFIED: system date]
**Valid until:** 2026-08-09 for local project decisions; re-check ExDoc/Hex package metadata if planning starts after that date. [VERIFIED: research date]
