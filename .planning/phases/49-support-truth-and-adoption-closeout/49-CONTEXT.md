# Phase 49: Support truth and adoption closeout - Context

**Gathered:** 2026-05-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Align Scoria's public docs, installer/task output, and milestone-closeout verification around one truthful lane model for OSS adopters and maintainers.

Phase 49 does not add new runtime capability, new installer mutations, or new optional surfaces. It closes wording drift, command-family drift, and support-truth ambiguity across the already-shipped default runtime, bounded handoff, semantic fast-path, and optional knowledge lanes.

</domain>

<decisions>
## Implementation Decisions

### Default runtime lane proof
- **D-01:** `mix test.adoption` is the single canonical default-lane verifier everywhere Scoria describes the default Phoenix adoption path.
- **D-02:** `mix test` remains broader repo-health context only. It should not be described as the canonical default-lane proof in README, operator docs, installer output, or milestone closeout language.
- **D-03:** The boring default-lane order should read as `mix scoria.install` -> `mix ecto.migrate` -> `mix test.adoption` -> inspect `/scoria` and `/scoria/workflows/:run_id`.
- **D-04:** Default-lane wording must continue to state explicitly that pgvector, retrieval, grounding, semantic-fast-path setup, and knowledge-lane verification are not prerequisites for first adoption.

### Bounded handoff lane posture
- **D-05:** Bounded handoffs stay inside the canonical default runtime adoption story. Scoria should not create a separate public handoff verification lane in Phase 49.
- **D-06:** Public docs should clarify that adopters validate the base runtime lane with `mix test.adoption`, then exercise `Scoria.start_handoff_run/3` only when they intentionally expand into the bounded-handoff lane.
- **D-07:** Handoffs remain an additive same-run runtime capability, not a separate prerequisite tier or a fourth mandatory proof command.

### Verification command family
- **D-08:** Scoria's public verification family should converge on `mix test.*` for lane verifiers and reserve `mix scoria.*` for installers, setup/bootstrap tasks, and implementation aliases.
- **D-09:** `mix test.semantic_fast_path` remains the canonical semantic-fast-path verifier. `mix scoria.test.semantic_fast_path` remains a compatibility/implementation alias.
- **D-10:** `mix test.knowledge` should become the canonical public verifier for the optional knowledge lane. `mix scoria.test.knowledge` should remain supported as a compatibility alias, but not promoted as the primary public command.
- **D-11:** Phase 49 should avoid presenting multiple equivalent public names for the same verifier. One canonical command per lane is part of the support contract.

### Maintainer closeout and support hierarchy
- **D-12:** The bounded maintainer closeout proof chain for `v2.2 OSS adopter onramp` should be exactly:
  `mix scoria.release_preview`
  `mix test.adoption`
- **D-13:** `mix scoria.release_preview` proves publish-facing docs and package-inventory truth; `mix test.adoption` proves the default host-app adoption boundary. These two commands together are the canonical milestone closeout answer.
- **D-14:** `mix test.semantic_fast_path` and `mix test.knowledge` are lane-specific validation commands, not part of the canonical `v2.2` closeout chain.
- **D-15:** `mix test` remains advisory repo-health context for maintainers, not canonical support proof.

### Wording and UX hierarchy
- **D-16:** Docs and task output should use a four-tier hierarchy:
  canonical closeout proof,
  canonical default adoption lane,
  lane-specific optional/troubleshooting verifiers,
  broader repo-health context.
- **D-17:** The installer's "Optional later lanes" inventory should remain truthful and compact, but surrounding docs should make `mix test.adoption` visually primary for first adoption and `mix test.knowledge`/`mix test.semantic_fast_path` clearly secondary.
- **D-18:** Public wording should favor least surprise over historical consistency when the two conflict. That means removing wording drift even if backward-compatible aliases remain in code.

### Shift-left defaults for future GSD runs
- **D-19:** Future discuss/planning work in this repo should research gray areas before escalating them: phase artifacts, prior contexts, `.planning/research/*`, and relevant `prompts/*` files should be consulted automatically when they shape product posture, DX, or support truth.
- **D-20:** Future discuss/planning should compare serious alternatives against idiomatic Phoenix/Plug/Ecto/LiveView library conventions and strong adjacent OSS prior art, then recommend one cohesive answer by default.
- **D-21:** User escalation should be reserved for decisions that still lack a clear winner after research and that materially affect product shape, security/policy boundary, durable truth, tenant blast radius, or a meaningfully different adopter/operator workflow.

### the agent's Discretion
- Exact sentence-level rewrite strategy across `README.md`, `docs/operator_verification.md`, `docs/adoption_lanes.md`, installer output, and source tests.
- Whether Phase 49 updates public docs to mention the compatibility aliases explicitly or leaves aliases undocumented.
- Whether the installer's "Optional later lanes" heading stays as-is or is retitled slightly, as long as the default-lane primacy and optional-lane boundaries stay clear.

</decisions>

<specifics>
## Specific Ideas

- Support answer hierarchy should feel like:
  `release_preview -> test.adoption` for milestone closeout,
  `test.adoption` for first adopter proof,
  `test.semantic_fast_path` only for semantic troubleshooting,
  `test.knowledge` only for intentional retrieval/grounding validation.
- Developer mental model should be simple:
  verification lanes live under `mix test.*`;
  setup and bootstrap work lives under `mix scoria.*`.
- The docs should read like a calm field guide, not a buffet of equivalent commands.
- The recommendation posture for future GSD runs should be research-first and recommendation-first: narrow the field, pick the obvious Scoria answer, and escalate only for major unresolved architectural forks.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and milestone contract
- `.planning/ROADMAP.md` — Phase 49 goal, plan slots, success criteria, and milestone progress table.
- `.planning/PROJECT.md` — `v2.2 OSS adopter onramp` posture and support-truth boundary.
- `.planning/REQUIREMENTS.md` — authoritative wording for `DOCS-01` and `DOCS-02`.
- `.planning/STATE.md` — current execution state and prior verification notes.
- `.planning/METHODOLOGY.md` — decisive-defaults and research-first escalation rules for this repo.

### Prior locked context
- `.planning/phases/48-host-app-install-contract-and-consumer-proof/48-CONTEXT.md` — locked default-lane installer and proof posture.
- `.planning/phases/46-operator-evidence-and-verification/46-CONTEXT.md` — locked semantic-fast-path proof posture and named troubleshooting lane.
- `.planning/milestones/v1.4-ROADMAP.md` — historical note that knowledge-lane public naming still had mild friction.

### Adopter-facing docs and task surfaces
- `README.md` — public install story, lane ordering, and current verification wording drift.
- `docs/adoption_lanes.md` — lane vocabulary, order, and proof command structure.
- `docs/operator_verification.md` — canonical default-lane, maintainer, semantic, and optional-knowledge verification guidance.
- `docs/bounded_handoffs.md` — bounded-handoff public lane posture and same-run delegation framing.
- `docs/semantic_fast_path.md` — semantic lane wording and separation from default adoption.
- `lib/mix/tasks/scoria.install.ex` — installer inventory and optional-lane messaging surface.
- `lib/mix/tasks/scoria.release_preview.ex` — bounded publish-facing maintainer proof lane.
- `lib/mix/tasks/test.adoption.ex` — canonical default-lane verifier implementation and wrapper.
- `lib/mix/tasks/test.semantic_fast_path.ex` — canonical semantic verifier wrapper.
- `lib/mix/tasks/scoria.test.knowledge.ex` — optional knowledge-lane implementation plus compatibility wrapper.
- `mix.exs` — task discoverability and `preferred_envs` support for both canonical and compatibility names.
- `test/scoria/adoption_surface_test.exs` — current docs/source truth assertions guarding adopter-facing language.

### Research and product posture
- `prompts/phoenix-ai-lib-deep-research.md` — Phoenix-native AI ops product and OSS onboarding posture.
- `prompts/scoria-brand-book-deep-research.md` — calm, field-engineer, evidence-first docs/UX posture.
- `prompts/scoria-gsd-kickoff.md` — batteries-included installer and operator-first product objective.
- `prompts/sztheory-elixir-dna.md` — zero-config onboarding, embedded dashboard, and operator-first DX principles.
- `.planning/research/elixir-ai-ecosystem.md` — compose-normalize-operationalize posture for Scoria in the Elixir ecosystem.
- `.planning/research/agentcore-lessons.md` — lessons about explicit boundaries, observability, and not widening the product surface.
- `.planning/research/liveview-operator-ux.md` — calm, supportable operator UX posture.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Mix.Tasks.Test.Adoption` already gives Scoria the right canonical wrapper shape for a bounded public verification lane.
- `Mix.Tasks.Test.SemanticFastPath` already shows the preferred public-named verifier plus a namespaced implementation alias pattern.
- `Mix.Tasks.Scoria.ReleasePreview` already provides the exact bounded publish-surface proof Phase 49 needs for milestone closeout.
- `Mix.Tasks.Scoria.Install` already emits a truthful three-bucket inventory that Phase 49 should align with, not replace.
- `test/scoria/adoption_surface_test.exs` already guards public wording and should remain the main drift-prevention seam.

### Established Patterns
- Scoria prefers one named verification command per support surface instead of vague full-suite guidance.
- Optional lanes are meant to stay explicit and separated from the default runtime lane.
- Compatibility aliases may exist in code, but public support truth wants one promoted command per lane.
- Milestone proof and adopter proof are related but not identical; closeout proof should stay bounded and phase-owned.

### Integration Points
- Command-family convergence touches `README.md`, `docs/adoption_lanes.md`, `docs/operator_verification.md`, installer output copy, and adoption-surface tests together.
- Knowledge-lane naming convergence can be done without runtime risk because both `test.knowledge` and `scoria.test.knowledge` already resolve via `mix.exs`.
- Future GSD automation behavior should read from `.planning/METHODOLOGY.md`, prior CONTEXT files, and the prompt corpus before reopening routine choices.

</code_context>

<deferred>
## Deferred Ideas

- A dedicated public handoff verifier such as `mix test.handoffs` — defer unless real support evidence shows `mix test.adoption` is insufficient.
- Any attempt to fold semantic or knowledge verification into the default adoption or milestone closeout chain.
- Renaming internal implementation tasks or removing compatibility aliases immediately; public naming convergence is higher leverage than alias removal.
- Broader “all green” repo-health sweeps as canonical closeout language; keep them secondary unless a future milestone intentionally redefines support posture.

</deferred>

---

*Phase: 49-support-truth-and-adoption-closeout*
*Context gathered: 2026-05-26*
