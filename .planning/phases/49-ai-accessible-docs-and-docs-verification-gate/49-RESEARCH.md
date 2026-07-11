# Phase 49: AI-accessible docs and docs verification gate - Research

**Researched:** 2026-07-10 [VERIFIED: system date]
**Domain:** Elixir ExDoc markdown output, root AI documentation entry points, coding-agent repo guidance, and docs warning gates [VERIFIED: .planning/phases/49-ai-accessible-docs-and-docs-verification-gate/49-CONTEXT.md]
**Confidence:** MEDIUM [VERIFIED: official docs and local commands were used; Context7 MCP/CLI was unavailable, so external docs were fetched through web search/open and local dependency source]

<user_constraints>
## User Constraints (from CONTEXT.md)

All content in this section is copied from `.planning/phases/49-ai-accessible-docs-and-docs-verification-gate/49-CONTEXT.md`; treat it as locked project input for planning. [VERIFIED: .planning/phases/49-ai-accessible-docs-and-docs-verification-gate/49-CONTEXT.md]

### Locked Decisions

## Implementation Decisions

### Root AI Entry Point

- **D-01:** Use a three-file root entry strategy: `llms.txt` for public AI-readable docs navigation, `AGENTS.md` for coding-agent operating instructions, and a minimal `GEMINI.md` bridge. Do not rely on only one vendor-specific file.
- **D-02:** Root `llms.txt` should be the curated public map. It should follow the emerging llms.txt shape: project H1, short summary, concise notes, H2 sections with Markdown links and short descriptions. It should point to `README.md`, canonical `guides/` docs, glossary, public facade/module docs, capability guides, and verification suites.
- **D-03:** Root `AGENTS.md` should be the coding-agent contract. It should be short, task-oriented, and repo-specific: source-of-truth order, setup and verification commands, generated-file rules, terminology rules, public facade boundaries, no-Ash rule, docs command, and where not to add maintainer-only or planning-only content.
- **D-04:** `GEMINI.md` should stay tiny. Preserve the current non-goal that Scoria does not use Ash, then point Gemini users to `AGENTS.md` rather than duplicating all guidance.
- **D-05:** Do not create `CLAUDE.md`, `CODEX.md`, or multiple agent-specific root documents in this phase. `AGENTS.md` is the shared repo-agent document; vendor-specific files should be adapters only when already present or required.

### Source Docs vs Generated ExDoc

- **D-06:** Treat `README.md` and `guides/` as canonical source docs. Treat old `docs/*.md` files as compatibility stubs. Treat `doc/` output, including `doc/llms.txt`, as generated derived reference.
- **D-07:** Root AI docs must explicitly say that agents should edit source docs and tests, not generated `doc/` output. Generated markdown is useful for ingestion and published HexDocs inspection, but it is not the authoritative edit surface.
- **D-08:** Do not make generated ExDoc output the source of truth, and do not commit a full generated mirror. This avoids stale ignored output, duplicated guide content, and source/generated ambiguity.
- **D-09:** The curated root `llms.txt` should link to source paths in the repository. It may mention the generated `doc/llms.txt` as a derived local artifact rebuilt by the docs command, but it should not depend on it for correctness.
- **D-10:** The public docs surface should stay adopter/job focused. Do not expose `.planning/`, raw prompt corpus, dev-only docs, compatibility stubs, or internal modules as primary AI-reader paths.

### Docs Warning Gate

- **D-11:** Make `mix scoria.release_preview` the canonical docs warning gate by running ExDoc with warnings-as-errors inside the existing release-preview task. Keep the maintainer-facing command contract as `mix scoria.release_preview`; do not introduce a new first-class public docs-check command unless implementation needs a private helper.
- **D-12:** Use `MIX_ENV=dev mix docs --warnings-as-errors` as the diagnostic shortcut for maintainers. It should be documented as troubleshooting, not as the primary release proof.
- **D-13:** Do not wire a separate raw `mix docs --warnings-as-errors` step into the CI policy job in this phase. The policy job is `MIX_ENV=test` and ExDoc is dev-only; moving the gate there would create workflow/env churn and bypass `Scoria.VerificationSuites`.
- **D-14:** Fix the current warning failure before flipping the gate. Current local evidence: `MIX_ENV=dev mix docs --warnings-as-errors` fails with many ExDoc `reference to a filtered module` warnings, mostly around command literals such as `mix test.adoption`, `mix scoria.release_preview`, `mix test.knowledge`, and hidden/internal references. `MIX_ENV=dev mix scoria.release_preview` currently passes but prints those warnings because it runs `mix docs` without `--warnings-as-errors`.
- **D-15:** Prefer ExDoc-supported escapes or wording changes for command literals and intentional hidden-module references. Do not make internal modules public merely to silence warnings unless the module is truly part of the public API.

### Drift Contract Strictness

- **D-16:** Use layered contracts, not a brittle exact snapshot. The tests should combine positive coverage of required AI docs links, source/generated boundary text, glossary/guide references, public facade and verification-suite references, docs warning gate behavior, and negative checks for stale vocabulary or internal/planning-only links.
- **D-17:** Extend the existing pattern around `Scoria.AdopterDocContract`, `Scoria.VerificationSuites`, `test/scoria/adoption_surface_test.exs`, `test/scoria/package_surface_test.exs`, `test/scoria/terminology_contract_test.exs`, and `test/mix/tasks/scoria.release_preview_test.exs`. Add a small `Scoria.AiDocContract` only if keeping AI docs constants inside `AdopterDocContract` would make that module too broad.
- **D-18:** Contract tests should pin facts and boundaries, not prose. Avoid snapshotting exact `llms.txt` or `AGENTS.md` bodies. Assert headings/anchors and required fragments where they represent a contract.
- **D-19:** Generated artifact checks should be light. It is enough to prove `doc/llms.txt` exists after docs generation and includes the public surface groups/facade; do not assert full generated text.
- **D-20:** Keep package inventory aligned. If root `llms.txt`, `AGENTS.md`, or the `GEMINI.md` bridge are intended to ship in Hex, add them to `mix.exs` package files, `Mix.Tasks.Scoria.ReleasePreview.required_package_paths/0`, and package surface tests. If not shipped, the context must explicitly explain why. Recommendation: ship root `llms.txt` and `AGENTS.md`; ship `GEMINI.md` only if the planner decides the Gemini bridge is useful to Hex consumers rather than repo contributors only.

### User/JTBD and DX Posture

- **D-21:** The AI docs surface serves two jobs:
  - A Phoenix adopter or AI assistant can find the public facade, guide ladder, glossary, capabilities, and verification suites without reading planning history.
  - A coding agent working in the repo can avoid common mistakes, run the right commands, edit source docs instead of generated artifacts, and preserve Scoria's public vocabulary.
- **D-22:** Keep the copy field-engineer oriented: calm, exact, evidence-based, and copy-pasteable. Use Scoria's current vocabulary: run, trace, reviewer, capability, verification suite, scoped context, semantic cache, optional knowledge base. Avoid "Scoria AI", magical/autonomous overclaims, generic AI hype, and backend-guts-first explanations.
- **D-23:** Hide implementation details unless they are a real contract. The agent docs may name `mix.exs`, `VerificationSuites`, release preview, and generated docs boundaries because those are operational contracts. They should not teach internal module topology as the first reader path.

### the agent's Discretion

Downstream agents may choose exact module/test names and exact wording. They should preserve the decisions above unless blocked by live ExDoc behavior or package constraints.

Recommended implementation shape:

- `llms.txt` with sections such as Start Here, Public API, Capability Guides, Verify, Source vs Generated, and Optional/Derived References.
- `AGENTS.md` with sections such as Project Boundary, Source of Truth, Generated Files, Setup and Verification, Docs Language, Public API, and Avoid.
- `GEMINI.md` as a short bridge to `AGENTS.md`, preserving the existing no-Ash rule.
- Either extend `Scoria.AdopterDocContract` or add `Scoria.AiDocContract` for AI docs paths/fragments.
- Harden `Mix.Tasks.Scoria.ReleasePreview` to call `Mix.Task.run("docs", ["--warnings-as-errors"])` after cleaning generated docs output.

### Deferred Ideas (OUT OF SCOPE)

- A committed generated `llms-full.txt` or full docs mirror is deferred. Generated docs remain rebuildable artifacts.
- New product guides for future seeds such as OpenInference export, lethal-trifecta governance, eval-depth calibration, retrieval eval/reranking, privacy/purge/masking, and persistent AI feature grouping remain deferred until those features ship.
- New root files for every agent vendor are deferred. `AGENTS.md` is the shared contract; vendor files should be thin adapters only.
- Moving docs warning proof into the CI policy job is deferred unless a future phase intentionally restructures dev/test CI boundaries.
- New dashboard UI/UX work is out of scope for this docs gate.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOCS-04 | Public moduledocs and guide links are warning-clean under the milestone's docs verification command. [VERIFIED: .planning/REQUIREMENTS.md] | `MIX_ENV=dev mix docs --warnings-as-errors` currently exits 1 with 107 ExDoc reference warnings, while `MIX_ENV=dev mix scoria.release_preview` exits 0 and prints the same 107 warnings because the task runs `Mix.Task.run("docs")` without WAE. [VERIFIED: `/tmp/scoria-phase49-docs-wae.log`] [VERIFIED: `/tmp/scoria-phase49-release-preview.log`] [VERIFIED: lib/mix/tasks/scoria.release_preview.ex] |
| AI-01 | An LLM or coding agent can use a curated root `llms.txt` and/or `AGENTS.md` to find Scoria's public facade, guide ladder, glossary, capabilities, and verification suites. [VERIFIED: .planning/REQUIREMENTS.md] | Root `llms.txt` should be a concise Markdown map with H1, summary, notes, H2 sections, and Markdown links with descriptions; `AGENTS.md` should contain practical repo setup, tests, conventions, constraints, and done criteria. [CITED: https://llmstxt.org/] [CITED: https://developers.openai.com/codex/guides/agents-md] [CITED: https://agents.md/] |
| AI-02 | The AI-accessibility surface distinguishes curated source docs from generated ExDoc artifacts and avoids stale or internal planning-only vocabulary. [VERIFIED: .planning/REQUIREMENTS.md] | `.gitignore` ignores `/doc/`; `doc/llms.txt` is generated by ExDoc markdown output and already lists guide groups/modules; root AI docs must point to source `README.md`/`guides/` and mark `doc/llms.txt` as derived. [VERIFIED: .gitignore] [VERIFIED: doc/llms.txt] [CITED: https://hexdocs.pm/ex_doc/changelog.html] |
</phase_requirements>

## Summary

Phase 49 should be planned as a docs contract and release-gate hardening phase, not a new docs generator or AI feature phase. [VERIFIED: .planning/phases/49-ai-accessible-docs-and-docs-verification-gate/49-CONTEXT.md] The repository already has the Phase 48 ExDoc guide ladder, `formatters: ["html", "markdown"]`, generated `doc/llms.txt`, package-surface tests, release-preview task, and CI job that runs `MIX_ENV=dev mix scoria.release_preview`. [VERIFIED: mix.exs] [VERIFIED: doc/llms.txt] [VERIFIED: test/scoria/package_surface_test.exs] [VERIFIED: .github/workflows/ci-verify.yml]

The planning center of gravity is: add a curated root `llms.txt`, add root `AGENTS.md`, convert `GEMINI.md` to a tiny bridge, document source/generated boundaries, add fact-level contracts, clean 107 ExDoc warnings, then change release preview to run docs with `--warnings-as-errors`. [VERIFIED: .planning/phases/49-ai-accessible-docs-and-docs-verification-gate/49-CONTEXT.md] [VERIFIED: `/tmp/scoria-phase49-docs-wae.log`]

**Primary recommendation:** Use the existing Scoria contract-test pattern, add a small `Scoria.AiDocContract` only if `Scoria.AdopterDocContract` becomes too broad, ship root `llms.txt` and `AGENTS.md` in the Hex package, keep `GEMINI.md` as a root bridge, and make `mix scoria.release_preview` the only canonical release gate by changing its docs step to `Mix.Task.run("docs", ["--warnings-as-errors"])`. [VERIFIED: .planning/phases/49-ai-accessible-docs-and-docs-verification-gate/49-CONTEXT.md] [VERIFIED: lib/scoria/adopter_doc_contract.ex] [VERIFIED: lib/mix/tasks/scoria.release_preview.ex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Curated public AI docs navigation | Repository Docs | Package Surface | Root `llms.txt` is source truth and should link to `README.md`, canonical `guides/`, public modules, and verification suites; package files decide whether Hex consumers receive it. [VERIFIED: 49-CONTEXT.md] [CITED: https://llmstxt.org/] |
| Coding-agent operating guidance | Repository Docs | Package Surface | Root `AGENTS.md` is the agent contract for setup, commands, generated-file rules, terminology, no-Ash, and verification; package inclusion must be explicit if intended for Hex consumers. [VERIFIED: 49-CONTEXT.md] [CITED: https://developers.openai.com/codex/guides/agents-md] |
| Gemini compatibility bridge | Repository Docs | Agent Adapter | Existing `GEMINI.md` carries the no-Ash rule and should point to `AGENTS.md` instead of duplicating shared guidance. [VERIFIED: GEMINI.md] [CITED: https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/gemini-md.md] |
| Generated ExDoc Markdown and `doc/llms.txt` | Build Artifact | Static Docs Output | ExDoc 0.40.3 generates Markdown and `llms.txt` under the output directory; `.gitignore` excludes `/doc/`, so it is derived local output. [CITED: https://hexdocs.pm/ex_doc/changelog.html] [VERIFIED: .gitignore] [VERIFIED: doc/llms.txt] |
| Docs warning gate | Mix Task / Build Tooling | CI Test Job | `mix scoria.release_preview` already runs in CI's `test` job under `MIX_ENV=dev`; hardening this task avoids a separate `MIX_ENV=test` policy docs step. [VERIFIED: .github/workflows/ci-verify.yml] [VERIFIED: lib/mix/tasks/scoria.release_preview.ex] |
| Drift contracts | Test Suite | Docs Contract Module | Existing tests already pin README, guide, glossary, terminology, package, and release-preview facts; Phase 49 should extend that pattern for AI docs and docs warnings. [VERIFIED: test/scoria/adoption_surface_test.exs] [VERIFIED: test/scoria/package_surface_test.exs] [VERIFIED: test/mix/tasks/scoria.release_preview_test.exs] |

## Project Constraints

No root `AGENTS.md`, root `CLAUDE.md`, `.claude/CLAUDE.md`, `.claude/skills/*/SKILL.md`, or `.agents/skills/*/SKILL.md` was found in `/Users/jon/projects/scoria`; nested `AGENTS.md` files exist only under bundled example dependencies and should not drive root project constraints. [VERIFIED: hidden-aware `rg --files`] [VERIFIED: `find .claude/skills .agents/skills .codex/skills`]

Existing root `GEMINI.md` contains the actionable non-goal that Scoria does not use Ash and is all-in on standard Phoenix and Ecto architectures; Phase 49 must preserve that rule while turning the file into a bridge to `AGENTS.md`. [VERIFIED: GEMINI.md]

`workflow.nyquist_validation` is absent from `.planning/config.json`, so Validation Architecture is included. [VERIFIED: .planning/config.json]

`security_enforcement` is absent from `.planning/config.json`, so Security Domain is included. [VERIFIED: .planning/config.json]

No `.planning/graphs/graph.json` file was found, so no graph context was available for this research. [VERIFIED: hidden-aware file discovery]

## Standard Stack

### Core

| Library/Tool | Version | Purpose | Why Standard |
|--------------|---------|---------|--------------|
| Elixir / Mix | Elixir 1.19.5, Mix 1.19.5, Erlang/OTP 28 | Runs ExUnit, `mix docs`, and `mix scoria.release_preview`. | This is the local project toolchain used for current verification. [VERIFIED: `mix --version`] |
| ExDoc | 0.40.3 | Generates HTML and Markdown docs, including generated `doc/llms.txt`, and supports warnings-as-errors. | It is the existing docs dependency and is current on Hex; no new docs package is needed. [VERIFIED: `mix deps`] [VERIFIED: `mix hex.info ex_doc`] [CITED: https://hexdocs.pm/ex_doc/changelog.html] |
| Hex | 2.5.0 | Builds unpacked package previews for release proof. | `mix scoria.release_preview` already shells to `mix hex.build --unpack --output tmp/scoria-release-preview`. [VERIFIED: `mix hex --version`] [VERIFIED: lib/mix/tasks/scoria.release_preview.ex] |
| ExUnit | Built into Elixir 1.19.5 | Runs package, adoption surface, terminology, and release-preview contract tests. | Existing focused contracts passed 49 tests on 2026-07-10. [VERIFIED: focused ExUnit run 2026-07-10] |
| GitHub Actions | Existing `.github/workflows/ci.yml` and `ci-verify.yml` | Executes release-preview in CI. | The current CI `test` job already runs `MIX_ENV=dev mix scoria.release_preview`. [VERIFIED: .github/workflows/ci-verify.yml] |

### Supporting

| Library/Tool/Convention | Version | Purpose | When to Use |
|-------------------------|---------|---------|-------------|
| `llms.txt` | Proposal published 2024-09-03 | Root public AI-readable map for source docs and public surface. | Use for concise public navigation; do not treat generated ExDoc `doc/llms.txt` as the root source file. [CITED: https://llmstxt.org/] |
| `AGENTS.md` | Open convention, no package version | Repo-aware coding-agent operating instructions. | Use as the shared root agent contract for setup, verification, generated-file rules, terminology, and avoid-list. [CITED: https://agents.md/] [CITED: https://developers.openai.com/codex/guides/agents-md] |
| `GEMINI.md` | Gemini CLI default context filename | Vendor bridge for Gemini users. | Keep tiny and point to `AGENTS.md`; preserve no-Ash rule. [VERIFIED: GEMINI.md] [CITED: https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/gemini-md.md] |
| `Scoria.AdopterDocContract` / optional `Scoria.AiDocContract` | Local code | Centralizes docs contract fragments. | Extend existing constants first; add AI-specific module only if root AI docs make AdopterDocContract too broad. [VERIFIED: lib/scoria/adopter_doc_contract.ex] [VERIFIED: 49-CONTEXT.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Root `llms.txt` plus `AGENTS.md` | Only generated `doc/llms.txt` | Generated output uses derived Markdown paths and is ignored; it cannot carry repository source-of-truth rules or source/generated boundary policy. [VERIFIED: .gitignore] [VERIFIED: doc/llms.txt] |
| Shared `AGENTS.md` with tiny `GEMINI.md` bridge | Separate `CLAUDE.md`, `CODEX.md`, and full `GEMINI.md` copies | Locked decision forbids multiplying vendor-specific root docs; duplicated instructions would drift. [VERIFIED: 49-CONTEXT.md] |
| Harden existing release-preview task | Add raw `mix docs --warnings-as-errors` to CI policy job | The policy job runs `MIX_ENV=test`, while ExDoc is dev-only and release preview already runs under `MIX_ENV=dev` in the CI `test` job. [VERIFIED: mix.exs] [VERIFIED: .github/workflows/ci-verify.yml] |
| Targeted ExDoc autolink skip/prose cleanup | Make internal modules public to silence warnings | ExDoc supports skip options for intentional literal/private references; exposing internals would contradict public API curation. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] [VERIFIED: mix.exs] |

**Installation:**

No new package installation is required for Phase 49. [VERIFIED: mix.exs] [VERIFIED: 49-CONTEXT.md]

```bash
# Only needed if local dependencies are missing:
mix deps.get
```

## Package Legitimacy Audit

Phase 49 should not install any new external package. [VERIFIED: mix.exs] [VERIFIED: 49-CONTEXT.md]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `ex_doc` | Hex | Current locked release 0.40.3 was released 2026-05-21. [VERIFIED: `mix hex.info ex_doc`] | Hex reported 130,893 downloads in the last 7 days and 97,770,341 all-time downloads during research. [VERIFIED: `mix hex.info ex_doc`] | `https://github.com/elixir-lang/ex_doc`. [VERIFIED: `mix hex.info ex_doc`] | Existing dependency, current, and already locked. [VERIFIED: `mix hex.outdated ex_doc`] | Approved existing dependency; no install task. |

**Packages removed due to [SLOP] verdict:** none; no new packages are proposed. [VERIFIED: package audit scope]
**Packages flagged as suspicious [SUS]:** none; no new packages are proposed. [VERIFIED: package audit scope]

The GSD package-legitimacy seam is required only for phases that install new packages; this phase uses the existing Hex dependency set. [VERIFIED: package audit scope]

## Architecture Patterns

### System Architecture Diagram

```text
Human maintainer / coding agent
        |
        v
Root AI entry files
  - llms.txt: curated public docs map
  - AGENTS.md: repo-agent operating contract
  - GEMINI.md: tiny adapter to AGENTS.md
        |
        v
Canonical source docs and public surface
  README.md -> guides/ -> glossary -> public modules -> VerificationSuites
        |
        v
Contract tests
  package_surface + adoption_surface + terminology + release_preview + AI doc contract
        |
        v
mix scoria.release_preview
  clean doc/ -> mix docs --warnings-as-errors -> generated doc/llms.txt -> hex.build --unpack
        |
        v
CI test job
  MIX_ENV=dev mix scoria.release_preview
        |
        v
Release blocked on docs warnings or package inventory drift
```

Decision points: root files are curated source, `doc/` is generated output, `docs/*.md` are compatibility stubs, and `.planning/`/prompt corpus/dev-only docs are not public AI-reader paths. [VERIFIED: 49-CONTEXT.md] [VERIFIED: .gitignore]

### Recommended Project Structure

```text
.
├── llms.txt                  # curated public AI-readable source map
├── AGENTS.md                 # repo-aware coding-agent contract
├── GEMINI.md                 # tiny bridge to AGENTS.md, preserves no-Ash rule
├── README.md                 # human/package front door
├── guides/                   # canonical source docs
├── docs/                     # compatibility stubs only
├── doc/                      # generated ExDoc output, ignored
├── lib/scoria/
│   ├── adopter_doc_contract.ex
│   └── ai_doc_contract.ex    # add only if AI doc constants do not fit existing contract
└── test/scoria/
    ├── adoption_surface_test.exs
    ├── package_surface_test.exs
    ├── terminology_contract_test.exs
    └── ai_doc_contract_test.exs
```

This structure follows the locked Phase 49 boundary and the current Phase 48 guide ladder. [VERIFIED: 49-CONTEXT.md] [VERIFIED: mix.exs] [VERIFIED: guides/]

### Pattern 1: Curated Root `llms.txt`

**What:** A concise source-file map that starts with `# Scoria`, gives a short summary, adds notes, and groups Markdown links under H2 sections. [CITED: https://llmstxt.org/] [VERIFIED: 49-CONTEXT.md]

**When to use:** Use for public AI-readable navigation to source docs, not generated `doc/` content. [VERIFIED: 49-CONTEXT.md]

**Example:**

```markdown
# Scoria

> Embedded Phoenix library for durable, inspectable AI/LLM work.

## Start Here

- [README](README.md): Human front door and capability ladder.
- [Getting Started](guides/getting-started.md): Shortest path to one visible run.

## Verify

- [Reviewer Verification](guides/reviewer-verification.md): Verification suite order and release-preview proof.
```

Source: llms.txt format guidance and Phase 49 locked sections. [CITED: https://llmstxt.org/] [VERIFIED: 49-CONTEXT.md]

### Pattern 2: `AGENTS.md` as the Repo-Agent Contract

**What:** A short root instruction file with source-of-truth order, generated-file rules, setup/verification commands, terminology rules, public API boundaries, and avoid-list. [CITED: https://developers.openai.com/codex/guides/agents-md] [CITED: https://agents.md/] [VERIFIED: 49-CONTEXT.md]

**When to use:** Use for coding agents editing the repo; do not duplicate the full content into `GEMINI.md`. [VERIFIED: 49-CONTEXT.md]

**Example sections:** Project Boundary, Source of Truth, Generated Files, Setup and Verification, Docs Language, Public API, Avoid. [VERIFIED: 49-CONTEXT.md]

### Pattern 3: ExDoc Warning Cleanup Before Gate Flip

**What:** First make `MIX_ENV=dev mix docs --warnings-as-errors` green; then change release preview to run docs with WAE. [VERIFIED: `/tmp/scoria-phase49-docs-wae.log`] [VERIFIED: lib/mix/tasks/scoria.release_preview.ex]

**When to use:** Use before changing `Mix.Tasks.Scoria.ReleasePreview.run/1`, because flipping first would make the release-preview task fail immediately. [VERIFIED: `/tmp/scoria-phase49-docs-wae.log`]

**Example:**

```elixir
# Source: ExDoc mix docs supports --warnings-as-errors.
Mix.Task.reenable("docs")
Mix.Task.run("docs", ["--warnings-as-errors"])
```

Source: ExDoc `mix docs` docs and current release-preview task. [CITED: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html] [VERIFIED: lib/mix/tasks/scoria.release_preview.ex]

### Pattern 4: Targeted Autolink Suppression for Literal Commands

**What:** Use `:skip_code_autolink_to` for intentionally literal command names and hidden helper names instead of exposing internals or skipping entire files. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html]

**When to use:** Use after verifying each warning is a false positive from command literals or intentional private references. [VERIFIED: `/tmp/scoria-phase49-docs-wae.log`]

**Example:**

```elixir
# Source: ExDoc supports :skip_code_autolink_to as a list or function.
defp docs do
  [
    formatters: ["html", "markdown"],
    skip_code_autolink_to: &docs_literal_code?/1
  ]
end

defp docs_literal_code?("mix " <> _command), do: true
defp docs_literal_code?("MIX_ENV=" <> _command), do: true
defp docs_literal_code?("Scoria.SupportJourney"), do: true
defp docs_literal_code?(_term), do: false
```

Source: ExDoc skip-code-autolink option and current warning inventory. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] [VERIFIED: `/tmp/scoria-phase49-docs-wae.log`]

### Anti-Patterns to Avoid

- **Making internal modules public to silence ExDoc:** It contradicts the Phase 48 public module allowlist and hides the real warning problem. [VERIFIED: mix.exs] [VERIFIED: 49-CONTEXT.md]
- **Snapshotting full AI docs:** It makes wording changes expensive; pin required headings, links, boundaries, and forbidden fragments instead. [VERIFIED: 49-CONTEXT.md]
- **Treating `doc/llms.txt` as source:** `doc/` is ignored and rebuilt by ExDoc; root `llms.txt` is the curated source entry point. [VERIFIED: .gitignore] [VERIFIED: doc/llms.txt]
- **Adding a new public docs-check command by default:** The locked contract says `mix scoria.release_preview` remains the canonical release proof. [VERIFIED: 49-CONTEXT.md]
- **Putting `.planning/` or prompt research into root AI docs:** Phase 49 explicitly keeps the public AI surface adopter/job focused. [VERIFIED: 49-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Docs generation and Markdown output | A custom Markdown docs generator or root generated mirror | Existing ExDoc 0.40.3 markdown formatter plus curated root `llms.txt` | ExDoc already emits Markdown and `doc/llms.txt`; root `llms.txt` should curate source docs, not duplicate generated output. [CITED: https://hexdocs.pm/ex_doc/changelog.html] [VERIFIED: doc/llms.txt] |
| Agent instruction discovery | Multiple full vendor-specific root docs | Root `AGENTS.md` plus tiny `GEMINI.md` bridge | OpenAI and agents.md both standardize practical AGENTS guidance; Phase 49 forbids `CLAUDE.md`/`CODEX.md` proliferation. [CITED: https://agents.md/] [VERIFIED: 49-CONTEXT.md] |
| Docs warning gate | A new CI topology or first-class public docs check | Existing `mix scoria.release_preview` and `Scoria.VerificationSuites` | CI already runs release preview under `MIX_ENV=dev`; moving to policy `MIX_ENV=test` conflicts with dev-only ExDoc. [VERIFIED: .github/workflows/ci-verify.yml] [VERIFIED: mix.exs] |
| AI docs drift checks | Full-file snapshots | Fact-level ExUnit contracts and doc contract constants | Existing Scoria docs contracts pin behavior and boundaries without freezing prose. [VERIFIED: lib/scoria/adopter_doc_contract.ex] [VERIFIED: test/scoria/adoption_surface_test.exs] |
| Package inventory drift | Manual release checklist only | `Mix.Tasks.Scoria.ReleasePreview.required_package_paths/0` plus package tests | Existing release preview fails on missing package files; add root AI docs there if they ship. [VERIFIED: lib/mix/tasks/scoria.release_preview.ex] |

**Key insight:** The hard part is not creating `llms.txt`; it is keeping source, generated docs, package inventory, CI proof, and agent instructions from disagreeing after the next docs edit. [VERIFIED: 49-CONTEXT.md] [VERIFIED: current contract tests]

## Common Pitfalls

### Pitfall 1: ExDoc Autolinks Command Literals
**What goes wrong:** Backticked command strings such as `mix test.adoption` produce `reference to a filtered module` warnings. [VERIFIED: `/tmp/scoria-phase49-docs-wae.log`]
**Why it happens:** ExDoc autolinks code terms and warns when it cannot resolve a reference in the current docs. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html]
**How to avoid:** Use targeted `skip_code_autolink_to` for literal commands and intentional private helpers, or reword only where a string is not a real command contract. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] [VERIFIED: 49-CONTEXT.md]
**Warning signs:** `MIX_ENV=dev mix docs --warnings-as-errors` fails while normal `mix docs` still writes `doc/`. [VERIFIED: `/tmp/scoria-phase49-docs-wae.log`]

### Pitfall 2: Warning Cleanup Expands Public API
**What goes wrong:** A planner makes hidden modules public just because ExDoc warns about them. [VERIFIED: 49-CONTEXT.md]
**Why it happens:** `reference to a filtered module` can look like a missing public module problem even when the reference should remain literal or private. [VERIFIED: `/tmp/scoria-phase49-docs-wae.log`]
**How to avoid:** Keep `docs_public_modules/0` curated and use skip/prose fixes for `Scoria.SupportJourney`, `Scoria.AdopterDocContract`, `Scoria.HexConsumerContract`, and other non-public contract/helper references. [VERIFIED: mix.exs] [VERIFIED: `/tmp/scoria-phase49-docs-wae.log`]
**Warning signs:** Package/API docs begin surfacing contract modules, fixtures, support journey internals, or UI helpers as first-class adopter APIs. [VERIFIED: mix.exs] [VERIFIED: 49-CONTEXT.md]

### Pitfall 3: Source vs Generated Boundary Blurs
**What goes wrong:** Agents edit `doc/*.md` or rely on `doc/llms.txt` as source truth. [VERIFIED: .gitignore] [VERIFIED: doc/llms.txt]
**Why it happens:** ExDoc's generated Markdown looks source-like and includes a useful generated `llms.txt`. [CITED: https://hexdocs.pm/ex_doc/changelog.html]
**How to avoid:** Root `llms.txt` and `AGENTS.md` must state that `README.md` and `guides/` are source, `docs/` are compatibility stubs, and `doc/` is derived. [VERIFIED: 49-CONTEXT.md]
**Warning signs:** A docs PR changes ignored `doc/` output or links root AI docs primarily to `doc/*.md`. [VERIFIED: .gitignore]

### Pitfall 4: CI Gate Lands in the Wrong Environment
**What goes wrong:** A new policy-job `mix docs --warnings-as-errors` step fails because ExDoc is `only: :dev`. [VERIFIED: mix.exs] [VERIFIED: 49-CONTEXT.md]
**Why it happens:** The policy job uses `MIX_ENV=test`, while release preview intentionally uses `MIX_ENV=dev`. [VERIFIED: .github/workflows/ci-verify.yml]
**How to avoid:** Harden `mix scoria.release_preview` and leave the existing CI `test` job as the path that runs it. [VERIFIED: .github/workflows/ci-verify.yml] [VERIFIED: 49-CONTEXT.md]
**Warning signs:** CI YAML gains a raw docs command outside the release-preview task. [VERIFIED: 49-CONTEXT.md]

### Pitfall 5: Package Surface Drifts
**What goes wrong:** Root `llms.txt` or `AGENTS.md` exists in git but is missing from Hex package preview and release-preview required paths. [VERIFIED: 49-CONTEXT.md]
**Why it happens:** `mix.exs` package files, release-preview required paths, and package tests currently duplicate explicit docs inventory. [VERIFIED: mix.exs] [VERIFIED: lib/mix/tasks/scoria.release_preview.ex] [VERIFIED: test/scoria/package_surface_test.exs]
**How to avoid:** Update all three surfaces in one plan if root AI docs are shipped, and add a test asserting the choice for `GEMINI.md`. [VERIFIED: 49-CONTEXT.md]
**Warning signs:** `mix hex.build --unpack` succeeds but root AI docs are absent from `tmp/scoria-release-preview`. [VERIFIED: lib/mix/tasks/scoria.release_preview.ex]

## Code Examples

Verified patterns from official and local sources:

### Root AI Docs Contract Constants

```elixir
# Source: local docs contract pattern in Scoria.AdopterDocContract.
defmodule Scoria.AiDocContract do
  @root_llms "llms.txt"
  @root_agents "AGENTS.md"
  @gemini_bridge "GEMINI.md"

  @required_llms_paths [
    "README.md",
    "guides/getting-started.md",
    "guides/jtbd-and-user-flows.md",
    "guides/reference/glossary.md",
    "guides/reviewer-verification.md"
  ]

  def root_llms, do: @root_llms
  def root_agents, do: @root_agents
  def gemini_bridge, do: @gemini_bridge
  def required_llms_paths, do: @required_llms_paths
end
```

Source: existing contract module pattern and Phase 49 discretion. [VERIFIED: lib/scoria/adopter_doc_contract.ex] [VERIFIED: 49-CONTEXT.md]

### Warning Gate in Release Preview

```elixir
# Source: ExDoc mix docs supports --warnings-as-errors.
Mix.shell().info("==> Building publish-facing docs")
clean_generated_docs_output!()
Mix.Task.reenable("docs")
Mix.Task.run("docs", ["--warnings-as-errors"])
```

Source: current release-preview structure and official ExDoc task docs. [VERIFIED: lib/mix/tasks/scoria.release_preview.ex] [CITED: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html]

### Generated Artifact Contract

```elixir
# Source: Phase 49 D-19 says generated artifact checks should be light.
test "generated ExDoc llms index is derived and includes public groups" do
  Mix.Task.reenable("docs")
  Mix.Task.run("docs", ["--formatter", "markdown"])

  generated = File.read!("doc/llms.txt")
  assert generated =~ "## Guides"
  assert generated =~ "## Modules"
  assert generated =~ "[Scoria](Scoria.md)"
  assert generated =~ "[Reviewer Verification](reviewer-verification.md)"
end
```

Source: generated `doc/llms.txt` and Phase 49 contract rule. [VERIFIED: doc/llms.txt] [VERIFIED: 49-CONTEXT.md]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| HTML-only HexDocs mindset | ExDoc Markdown formatter plus generated `llms.txt` and Copy Markdown affordances | ExDoc 0.40.0, 2026-01-20 | Scoria can use generated `doc/llms.txt` as a derived reference while still adding a curated root source `llms.txt`. [CITED: https://hexdocs.pm/ex_doc/changelog.html] |
| README-only human front door | Separate human README, public AI `llms.txt`, and coding-agent `AGENTS.md` | llms.txt proposal published 2024-09-03; AGENTS.md convention is current in OpenAI Codex docs | AI readers get concise source maps and coding agents get repo operating instructions without cluttering README. [CITED: https://llmstxt.org/] [CITED: https://developers.openai.com/codex/guides/agents-md] |
| Vendor-specific agent files as full instruction copies | Shared `AGENTS.md` plus thin vendor adapters | Current OpenAI/Gemini docs support AGENTS and GEMINI context files | Scoria should avoid `CLAUDE.md`/`CODEX.md` proliferation and preserve `GEMINI.md` as a bridge. [CITED: https://agents.md/] [CITED: https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/gemini-md.md] [VERIFIED: 49-CONTEXT.md] |

**Deprecated/outdated:**
- Treating generated `doc/` output as editable docs is wrong for this repo because `/doc/` is ignored and release preview rebuilds it. [VERIFIED: .gitignore] [VERIFIED: lib/mix/tasks/scoria.release_preview.ex]
- Putting docs warning proof in a raw `MIX_ENV=test` CI policy step is out of scope and conflicts with the dev-only ExDoc dependency. [VERIFIED: 49-CONTEXT.md] [VERIFIED: mix.exs]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| - | No `[ASSUMED]` factual claims are used in this research. | All | No user confirmation is needed for factual claims; the planning choices below are resolved. |

## Open Questions (RESOLVED)

1. **Should root `GEMINI.md` ship in Hex?**
   - What we know: Phase 49 recommends shipping `llms.txt` and `AGENTS.md`; it leaves `GEMINI.md` packaging to planner judgment. [VERIFIED: 49-CONTEXT.md]
   - RESOLVED: `llms.txt` and `AGENTS.md` ship in the Hex package and release-preview inventory; `GEMINI.md` remains repo-only as a vendor bridge for contributors and is explicitly excluded from package inventory. [VERIFIED: 49-01-PLAN.md] [VERIFIED: 49-02-PLAN.md]
   - Plan outcome: Plan 01 encodes this in `Scoria.AiDocContract.packaged_ai_doc_paths/0` and `repo_only_ai_doc_paths/0`; Plan 02 adds package and release-preview tests that assert `GEMINI.md` is excluded. [VERIFIED: 49-01-PLAN.md] [VERIFIED: 49-02-PLAN.md]

2. **Should warning cleanup be mostly config or prose?**
   - What we know: ExDoc supports `skip_code_autolink_to`, and the current 107 warnings are mostly literal Mix command strings plus a few private helper/module references. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] [VERIFIED: `/tmp/scoria-phase49-docs-wae.log`]
   - RESOLVED: warning cleanup starts with targeted `skip_code_autolink_to` for command literals and intentional hidden helper references; prose fixes are reserved for remaining non-command warnings after the targeted skip is in place. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] [VERIFIED: 49-02-PLAN.md]
   - Plan outcome: Plan 02 Task 2 wires `skip_code_autolink_to` in `mix.exs`, keeps `docs_public_modules/0` curated, and permits source-doc wording changes only if the WAE command still reports non-command prose problems. [VERIFIED: 49-02-PLAN.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir / Mix | Tests, docs, release preview | Yes | Elixir 1.19.5, Mix 1.19.5 | None needed. [VERIFIED: `mix --version`] |
| Erlang/OTP | Elixir runtime | Yes | OTP 28 | None needed. [VERIFIED: `elixir --version`] |
| Hex | `mix hex.build --unpack` | Yes | 2.5.0 | None needed. [VERIFIED: `mix hex --version`] |
| ExDoc | `mix docs --warnings-as-errors` | Yes | 0.40.3 | Existing dependency; no fallback recommended. [VERIFIED: `mix deps`] |
| Git | Dynamic docs source refs | Yes | 2.41.0 | `docs_source_ref/0` already falls back to `"main"` if git tag lookup fails. [VERIFIED: `git --version`] [VERIFIED: mix.exs] |
| GitHub Actions | CI release-preview path | Remote | Existing workflows | Document release gate if CI wiring cannot be edited, but current CI already runs release preview. [VERIFIED: .github/workflows/ci-verify.yml] |

**Missing dependencies with no fallback:** none identified for Phase 49. [VERIFIED: environment probes]

**Missing dependencies with fallback:** Context7 MCP/CLI was unavailable for research; official web docs and local dependency source were used instead. [VERIFIED: `command -v ctx7`] [VERIFIED: web search/open results]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir 1.19.5 [VERIFIED: `mix --version`] |
| Config file | `test/test_helper.exs` [VERIFIED: git ls-files] |
| Quick run command | `MIX_ENV=test mix test test/scoria/package_surface_test.exs test/mix/tasks/scoria.release_preview_test.exs test/scoria/adoption_surface_test.exs test/scoria/terminology_contract_test.exs --warnings-as-errors` [VERIFIED: focused run passed 49 tests] |
| Docs diagnostic command | `MIX_ENV=dev mix docs --warnings-as-errors` currently fails with 107 warnings. [VERIFIED: `/tmp/scoria-phase49-docs-wae.log`] |
| Phase gate command | `MIX_ENV=dev mix scoria.release_preview` after warning cleanup and WAE hardening. [VERIFIED: .github/workflows/ci-verify.yml] [VERIFIED: 49-CONTEXT.md] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| DOCS-04 | Docs generation is warning-clean under the milestone gate and release preview runs docs with WAE. [VERIFIED: .planning/REQUIREMENTS.md] | integration/source contract | `MIX_ENV=dev mix docs --warnings-as-errors`; `MIX_ENV=test mix test test/mix/tasks/scoria.release_preview_test.exs --warnings-as-errors` | Partial - release-preview test exists; WAE assertion missing. [VERIFIED: test/mix/tasks/scoria.release_preview_test.exs] |
| AI-01 | Root `llms.txt` and `AGENTS.md` point to public facade, guide ladder, glossary, capabilities, and verification suites. [VERIFIED: .planning/REQUIREMENTS.md] | docs contract | `MIX_ENV=test mix test test/scoria/ai_doc_contract_test.exs --warnings-as-errors` | No - Wave 0 should add or extend AI docs contract. [VERIFIED: git ls-files test/scoria] |
| AI-02 | AI docs distinguish source docs from generated ExDoc output and avoid stale/internal planning vocabulary. [VERIFIED: .planning/REQUIREMENTS.md] | docs/negative contract | `MIX_ENV=test mix test test/scoria/ai_doc_contract_test.exs test/scoria/terminology_contract_test.exs --warnings-as-errors` | Partial - terminology test exists; AI source/generated test missing. [VERIFIED: test/scoria/terminology_contract_test.exs] |

### Sampling Rate

- **Per task commit:** Run the focused test for the touched surface plus `MIX_ENV=dev mix docs --warnings-as-errors` after any docs warning cleanup. [VERIFIED: current warning command]
- **Per wave merge:** Run the quick run command plus `MIX_ENV=dev mix scoria.release_preview`. [VERIFIED: focused run passed] [VERIFIED: release-preview pass]
- **Phase gate:** `MIX_ENV=dev mix scoria.release_preview` must be warning-clean after release-preview calls `docs --warnings-as-errors`. [VERIFIED: 49-CONTEXT.md]

### Wave 0 Gaps

- [ ] `test/scoria/ai_doc_contract_test.exs` - covers AI-01 and AI-02 root docs/source-generated boundaries. [VERIFIED: required test absent]
- [ ] `lib/scoria/ai_doc_contract.ex` or extension of `lib/scoria/adopter_doc_contract.ex` - centralizes root AI doc required paths/fragments. [VERIFIED: 49-CONTEXT.md] [VERIFIED: lib/scoria/adopter_doc_contract.ex]
- [ ] Add release-preview test assertion that docs run with `--warnings-as-errors`. [VERIFIED: test/mix/tasks/scoria.release_preview_test.exs]
- [ ] Add package-surface assertions for `llms.txt`, `AGENTS.md`, and explicit `GEMINI.md` package decision. [VERIFIED: test/scoria/package_surface_test.exs] [VERIFIED: 49-CONTEXT.md]
- [ ] Clean current 107 ExDoc warnings before flipping release preview to WAE. [VERIFIED: `/tmp/scoria-phase49-docs-wae.log`]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | No | No authentication surface changes in this docs phase. [VERIFIED: 49-CONTEXT.md] |
| V3 Session Management | No | No session-state changes in this docs phase. [VERIFIED: 49-CONTEXT.md] |
| V4 Access Control | Indirect | Agent docs must preserve the host-owned auth/authorization boundary and not imply Scoria owns host roles or tenant policy. [VERIFIED: guides/ownership-boundary.md] [VERIFIED: GEMINI.md] |
| V5 Input Validation | Yes | Validate root docs links/fragments, forbidden planning/internal vocabulary, and package paths with ExUnit contracts. [VERIFIED: 49-CONTEXT.md] [VERIFIED: test/scoria/terminology_contract_test.exs] |
| V6 Cryptography | No | No cryptographic code or secret handling changes are planned. [VERIFIED: 49-CONTEXT.md] |

### Known Threat Patterns for Docs/Agent Guidance

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Public docs expose planning-only or internal implementation paths | Information Disclosure | Negative contract tests for `.planning/`, prompt corpus, dev-only docs, and internal module links in root AI docs. [VERIFIED: 49-CONTEXT.md] |
| Agents edit generated `doc/` output instead of source docs | Tampering | Root `AGENTS.md` and `llms.txt` explicitly define source order and generated-file rules; `.gitignore` keeps `/doc/` ignored. [VERIFIED: .gitignore] [VERIFIED: 49-CONTEXT.md] |
| Docs release gate can pass despite warnings | Repudiation / Tampering | `mix scoria.release_preview` must run `mix docs --warnings-as-errors` and CI already runs release preview. [VERIFIED: .github/workflows/ci-verify.yml] [VERIFIED: lib/mix/tasks/scoria.release_preview.ex] |
| Agent docs overstate future AI/security capabilities | Spoofing / Information Disclosure | Reuse Phase 46/47/48 terminology and deferred-claim guards; do not add future-seed feature guides. [VERIFIED: 49-CONTEXT.md] [VERIFIED: test/scoria/terminology_contract_test.exs] |
| Package inventory omits root AI docs after release | Tampering | Add root AI docs to `mix.exs` package files, release-preview required paths, and package-surface tests when shipping. [VERIFIED: mix.exs] [VERIFIED: lib/mix/tasks/scoria.release_preview.ex] |

## Sources

### Primary (official or local, MEDIUM/HIGH confidence by seam and verification)

- `.planning/phases/49-ai-accessible-docs-and-docs-verification-gate/49-CONTEXT.md` - locked decisions, discretion, deferred scope. [VERIFIED: file read]
- `.planning/REQUIREMENTS.md` - DOCS-04, AI-01, AI-02 requirement text. [VERIFIED: file read]
- `.planning/STATE.md` and `.planning/ROADMAP.md` - phase status, dependency, and milestone sequencing. [VERIFIED: file read]
- `mix.exs`, `lib/mix/tasks/scoria.release_preview.ex`, `lib/scoria/verification_suites.ex`, `lib/scoria/adopter_doc_contract.ex` - local docs/package/release-preview implementation. [VERIFIED: file read]
- `test/scoria/package_surface_test.exs`, `test/scoria/adoption_surface_test.exs`, `test/scoria/terminology_contract_test.exs`, `test/mix/tasks/scoria.release_preview_test.exs` - current contract patterns. [VERIFIED: file read]
- `https://llmstxt.org/` - llms.txt proposal, format, Markdown links, optional sections, generated context guidance. [CITED: https://llmstxt.org/]
- `https://developers.openai.com/codex/guides/agents-md` - Codex AGENTS.md discovery and project instruction guidance. [CITED: https://developers.openai.com/codex/guides/agents-md]
- `https://agents.md/` - open AGENTS.md convention and recommended content. [CITED: https://agents.md/]
- `https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/gemini-md.md` - Gemini CLI `GEMINI.md` hierarchy and context-file behavior. [CITED: https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/gemini-md.md]
- `https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html` - `mix docs` options including `--warnings-as-errors`. [CITED: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html]
- `https://hexdocs.pm/ex_doc/ExDoc.html` - ExDoc options including `skip_undefined_reference_warnings_on` and `skip_code_autolink_to`. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html]
- `https://hexdocs.pm/ex_doc/changelog.html` - ExDoc 0.40 Markdown formatter and generated `llms.txt` change. [CITED: https://hexdocs.pm/ex_doc/changelog.html]
- `https://hexdocs.pm/elixir/writing-documentation.html` - Elixir documentation attributes and docs-as-tooling behavior. [CITED: https://hexdocs.pm/elixir/writing-documentation.html]

### Secondary (local command evidence)

- `MIX_ENV=dev mix docs --warnings-as-errors` - failed with 107 warnings. [VERIFIED: `/tmp/scoria-phase49-docs-wae.log`]
- `MIX_ENV=dev mix scoria.release_preview` - passed while printing the same 107 warnings. [VERIFIED: `/tmp/scoria-phase49-release-preview.log`]
- Focused ExUnit run - 49 tests passed. [VERIFIED: command output 2026-07-10]
- `mix hex.info ex_doc` and `mix hex.outdated ex_doc` - ExDoc version/download/source/currentness. [VERIFIED: command output 2026-07-10]

### Tertiary (LOW confidence)

- None used as authority. [VERIFIED: Assumptions Log]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - verified from local commands, `mix.exs`, and Hex package metadata. [VERIFIED: `mix --version`] [VERIFIED: `mix hex.info ex_doc`]
- Architecture: HIGH - locked by Phase 49 context and current code/CI topology. [VERIFIED: 49-CONTEXT.md] [VERIFIED: .github/workflows/ci-verify.yml]
- Pitfalls: HIGH for current ExDoc warnings because they were reproduced locally; MEDIUM for external convention guidance because it came from official web docs through websearch/open rather than Context7 MCP. [VERIFIED: `/tmp/scoria-phase49-docs-wae.log`] [CITED: https://llmstxt.org/]
- Package legitimacy: HIGH for "no new packages"; MEDIUM for existing `ex_doc` metadata via Hex commands. [VERIFIED: mix.exs] [VERIFIED: `mix hex.info ex_doc`]

**Research date:** 2026-07-10 [VERIFIED: system date]
**Valid until:** 2026-07-24 for external AI-entry conventions; local code findings should be refreshed after the first Phase 49 implementation commit. [VERIFIED: research date]
