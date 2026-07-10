# Phase 49: AI-accessible docs and docs verification gate - Context

**Gathered:** 2026-07-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 49 makes Scoria's public documentation reliably navigable by humans and coding agents, and makes publish-facing docs drift fail before the `0.1.3` release.

This phase owns:

- Root AI-readable docs entry points for coding agents and LLM-assisted readers.
- Clear source-of-truth boundaries between canonical source docs and generated ExDoc artifacts.
- Warning-clean docs generation as part of the release-preview verification suite.
- Focused contracts that keep the AI docs front door aligned with glossary, guide ladder, public facade, capabilities, and verification suites.

In scope:

- Add a curated root `llms.txt`.
- Add a concise root `AGENTS.md` for repo-aware coding agents.
- Keep `GEMINI.md` as a tiny Gemini-compatible bridge that preserves the existing Ash non-goal and points to shared agent guidance.
- Label generated ExDoc output such as `doc/llms.txt` as derived, ignored, and rebuildable.
- Fix current ExDoc warnings so `MIX_ENV=dev mix docs --warnings-as-errors` is green.
- Harden `mix scoria.release_preview` so it fails on docs warnings.
- Extend docs/source contracts to cover AI entry points, guide index, glossary, source/generated boundary, forbidden stale vocabulary, and the docs warning gate.

Out of scope:

- New product capabilities, new dashboard UI, or new hosted onboarding.
- Release cut, release notes finalization, Hex publish, and post-publish smoke. Phase 50 owns those.
- A committed full generated docs mirror. Generated `doc/` output remains build artifact truth, not source truth.
- New AI feature guides for unbuilt future seeds such as OpenInference export, lethal-trifecta governance, deeper eval calibration, retrieval eval depth, privacy/purge/masking, or persistent AI feature grouping.

</domain>

<decisions>
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

### Claude's Discretion

Downstream agents may choose exact module/test names and exact wording. They should preserve the decisions above unless blocked by live ExDoc behavior or package constraints.

Recommended implementation shape:

- `llms.txt` with sections such as Start Here, Public API, Capability Guides, Verify, Source vs Generated, and Optional/Derived References.
- `AGENTS.md` with sections such as Project Boundary, Source of Truth, Generated Files, Setup and Verification, Docs Language, Public API, and Avoid.
- `GEMINI.md` as a short bridge to `AGENTS.md`, preserving the existing no-Ash rule.
- Either extend `Scoria.AdopterDocContract` or add `Scoria.AiDocContract` for AI docs paths/fragments.
- Harden `Mix.Tasks.Scoria.ReleasePreview` to call `Mix.Task.run("docs", ["--warnings-as-errors"])` after cleaning generated docs output.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning and Prior Phase Context

- `.planning/ROADMAP.md` - Phase 49 goal, dependency on Phase 48, and success criteria.
- `.planning/REQUIREMENTS.md` - DOCS-04, AI-01, AI-02 and current milestone boundaries.
- `.planning/PROJECT.md` - v3.5 project posture, n=1 reviewer/operator lens, and current docs/release readiness state.
- `.planning/STATE.md` - Current phase status and recent Phase 46-48 decisions.
- `.planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md` - Locked public vocabulary and evidence/trace boundary.
- `.planning/phases/47-readme-first-screen-positioning-and-scope-doctrine/47-CONTEXT.md` - README front-door positioning, roles-not-headcount persona, and public scope doctrine.
- `.planning/phases/48-exdoc-and-guide-ladder-restructure/48-CONTEXT.md` - Canonical `guides/` ladder, ExDoc grouping, compatibility stubs, generated docs, public module curation, and Phase 49 deferrals.

### Brand, Product, and Prompt Research

- `brandbook/brand-book.md` - Canonical current brandbook; use this over older prompt research if they disagree.
- `prompts/sztheory-elixir-dna.md` - Batteries-included but composable Phoenix/Ecto/LiveView library posture.
- `prompts/phoenix-ai-lib-deep-research.md` - Phoenix-native AI ops positioning and docs/DX lessons from adjacent AI ecosystems.
- `prompts/ai-eval-best-practices-deep-research.md` - Eval and verification as operating system for probabilistic product features.
- `prompts/scoria-brand-book-deep-research.md` - Older but useful docs identity, voice, copy-pasteable docs, and "Trace the run. Prove the change. Ship the agent." framing. Defer to `brandbook/brand-book.md` on conflicts.
- `prompts/scoria-ideal-admin-operator-ui-ux-storyboard-deep-research.md` - JTBD framing: orient, act, investigate, recover, improve, govern, audit. Useful for keeping docs user-flow oriented.
- `prompts/scoria-gsd-kickoff.md` - Project vision, field engineer archetype, and core capabilities.

### Current Source Docs and Generated Docs

- `README.md` - Human front door and current guide ladder links.
- `guides/getting-started.md` - First-run adopter guide.
- `guides/golden-path.md` - End-to-end default runtime guide.
- `guides/jtbd-and-user-flows.md` - Capability/JTBD guide index.
- `guides/ownership-boundary.md` - Public owns-vs-delegates scope doctrine.
- `guides/capabilities/default-runtime.md` - Default runtime capability docs.
- `guides/capabilities/bounded-handoffs.md` - Bounded handoff capability docs.
- `guides/capabilities/semantic-cache.md` - Semantic cache capability docs.
- `guides/capabilities/connectors-and-mcp.md` - Connector/MCP capability docs.
- `guides/capabilities/support-copilot-gallery.md` - Support-copilot gallery docs.
- `guides/reviewer-verification.md` - Verification suite and release-preview guidance.
- `guides/troubleshooting.md` - Docs/release-preview troubleshooting targets.
- `guides/scoria-vs-external-llm-ops.md` - External LLM-ops comparison guide.
- `guides/cheatsheet.cheatmd` - Compact guide surface for adopters.
- `guides/reference/glossary.md` - Canonical public vocabulary and compatibility aliases.
- `guides/maintainers.md` - Maintainer-only CI, release preview, warning, and docs maintenance guidance.
- `docs/*.md` - Compatibility stubs only; do not treat as canonical Phase 49 source docs.
- `doc/llms.txt` - Generated ExDoc markdown index; derived artifact only, not source truth.
- `GEMINI.md` - Existing Gemini-specific root context containing the Ash non-goal; convert into a bridge rather than duplicating shared agent guidance.

### Current Code, Tests, and CI Integration Points

- `mix.exs` - ExDoc configuration, guide extras, module groups, redirects, package files, source refs, public module filter.
- `lib/mix/tasks/scoria.release_preview.ex` - Existing release-preview task to harden with docs warnings-as-errors.
- `lib/scoria/verification_suites.ex` - Public verification suite command contracts; release preview is already the publish-facing proof.
- `lib/scoria/adopter_doc_contract.ex` - Existing docs contract constants; likely home or neighbor for AI docs contract constants.
- `test/scoria/package_surface_test.exs` - Package/docs surface contract.
- `test/scoria/adoption_surface_test.exs` - Public docs, README, moduledoc, guide, and vocabulary contract tests.
- `test/scoria/terminology_contract_test.exs` - Public vocabulary and forbidden stale terminology tests.
- `test/mix/tasks/scoria.release_preview_test.exs` - Release-preview task contract tests.
- `.github/workflows/ci.yml` - PR entrypoint and `CI / ci-gate`.
- `.github/workflows/ci-verify.yml` - Current reusable CI topology; `MIX_ENV=dev mix scoria.release_preview` already runs in the `test` job.

### Local Verification Evidence

- `MIX_ENV=dev mix docs --warnings-as-errors` - Ran on 2026-07-10 and failed on ExDoc warnings, primarily `reference to a filtered module`.
- `MIX_ENV=dev mix scoria.release_preview` - Ran on 2026-07-10 and passed package preview while printing the same docs warnings, proving the current release-preview task is not warning-clean.

### External References for Planner/Researcher

- `https://llmstxt.org/` - llms.txt proposal, format, and source/generated markdown guidance.
- `https://developers.openai.com/codex/guides/agents-md` - OpenAI/Codex guidance for `AGENTS.md`.
- `https://agents.md/` - AGENTS.md convention and rationale.
- `https://docs.anthropic.com/en/docs/claude-code/memory` - CLAUDE.md context behavior; useful as contrast, not a required Scoria file.
- `https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/gemini-md.md` - Gemini CLI `GEMINI.md` context behavior.
- `https://ex-doc.hexdocs.pm/Mix.Tasks.Docs.html` - Official `mix docs --warnings-as-errors` behavior.
- `https://ex-doc.hexdocs.pm/ExDoc.html` - ExDoc options, grouping, redirects, filters, and warnings behavior.
- `https://hexdocs.pm/elixir/writing-documentation.html` - Elixir documentation as first-class API contract.
- `https://hexdocs.pm/phoenix/overview.html` - Phoenix guide organization precedent.
- `https://developers.openai.com/api/docs/llms.txt` - Example of a curated public LLM docs index with Markdown twins.
- `https://www.twilio.com/docs/llms.txt` - Example of a large docs site exposing AI-oriented docs and AI coding-agent guidance via llms.txt.
- `https://posthog.com/docs/ai-engineering/markdown-llms-txt` - Example of product docs explaining Markdown and llms.txt for AI readers.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `mix.exs` already centralizes ExDoc source refs, `formatters: ["html", "markdown"]`, guide extras, module groups, redirects, public module filtering, and package files.
- `Mix.Tasks.Scoria.ReleasePreview` already cleans generated docs, runs docs generation, builds an unpacked Hex preview, and verifies required package paths.
- `Scoria.VerificationSuites` already names `mix scoria.release_preview` as the release preview verification suite and `MIX_ENV=dev mix scoria.release_preview` as its CI command.
- `Scoria.AdopterDocContract` already centralizes public docs paths and required/forbidden fragments. Extend this pattern for AI docs instead of duplicating hardcoded paths across tests.
- `test/scoria/package_surface_test.exs`, `test/scoria/adoption_surface_test.exs`, and `test/mix/tasks/scoria.release_preview_test.exs` already provide good insertion points for package, source docs, module docs, and release-preview contracts.
- `doc/llms.txt` already exists after docs generation because ExDoc markdown output is enabled. This is a useful generated reference but should remain ignored/derived.

### Established Patterns

- Scoria docs are public API. Prior phases already use focused ExUnit contracts to pin guide paths, vocabulary, README order, package paths, ExDoc grouping, public module docs, and release-preview behavior.
- Public docs favor final vocabulary and compatibility notes: reviewer, trace, capabilities, verification suite, scoped context, semantic cache, optional knowledge base.
- Canonical public docs moved to `guides/`; old `docs/` paths are compatibility-only and excluded from ExDoc extras.
- Maintainer-only commands live in `guides/maintainers.md`, not README first-run copy.
- Dev-only docs and generated artifacts stay out of adopter-facing HexDocs unless a phase explicitly packages them.

### Integration Points

- Add `llms.txt` and `AGENTS.md` to package files if they should ship with Hex.
- Update `Mix.Tasks.Scoria.ReleasePreview.required_package_paths/0` if root AI docs ship.
- Update release-preview tests to assert docs warnings-as-errors is part of the task contract.
- Add or extend docs contract tests to assert root AI docs include guide ladder, glossary, public facade, verification suites, source/generated boundary, and no planning-only or stale vocabulary.
- If `GEMINI.md` remains repo-only, package tests should assert that choice explicitly rather than accidentally omitting it.

</code_context>

<specifics>
## Specific Ideas

Research-backed recommendation across all four gray areas:

1. Root `llms.txt` as public map.
2. Root `AGENTS.md` as coding-agent operating guide.
3. Minimal `GEMINI.md` bridge.
4. Canonical source docs under `README.md` and `guides/`.
5. Generated ExDoc markdown under `doc/` as derived artifact only.
6. `mix scoria.release_preview` as the canonical warning-clean docs/package gate.
7. `MIX_ENV=dev mix docs --warnings-as-errors` as diagnostic shortcut.
8. Layered contracts rather than exact prose snapshots.

Suggested `llms.txt` sections:

- Start Here
- Public API
- Capability Guides
- Verify
- Source vs Generated
- Optional or Derived References

Suggested `AGENTS.md` sections:

- Project Boundary
- Source of Truth
- Generated Files
- Setup and Verification
- Docs Language
- Public API
- Avoid

The AI docs front door should help agents answer the same Scoria docs questions humans need answered:

- What is Scoria?
- What do I read first?
- What source files should I edit?
- Which generated files must not be edited?
- Which public modules are real contracts?
- Which verification suite proves this change?
- Which words are current vocabulary, and which words are legacy only?

</specifics>

<deferred>
## Deferred Ideas

- A committed generated `llms-full.txt` or full docs mirror is deferred. Generated docs remain rebuildable artifacts.
- New product guides for future seeds such as OpenInference export, lethal-trifecta governance, eval-depth calibration, retrieval eval/reranking, privacy/purge/masking, and persistent AI feature grouping remain deferred until those features ship.
- New root files for every agent vendor are deferred. `AGENTS.md` is the shared contract; vendor files should be thin adapters only.
- Moving docs warning proof into the CI policy job is deferred unless a future phase intentionally restructures dev/test CI boundaries.
- New dashboard UI/UX work is out of scope for this docs gate.

</deferred>

---

*Phase: 49-AI-accessible docs and docs verification gate*
*Context gathered: 2026-07-10*
