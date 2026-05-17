# Phase 17: Re-verify Keystone Defaults and Adoption Surface - Context

**Gathered:** 2026-05-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Backfill the missing verification chain for Keystone defaults/install ergonomics and the public adoption surface, then reconcile every live milestone truth surface so the repo reflects verified current reality instead of summary-only closure.

This phase verifies and records already-shipped Phase 14 and Phase 15 behavior. It does not reopen the product-shape decisions from those phases, and it does not pull Phase 18 executable guard work into scope except where Phase 17 should establish the default verification/reconciliation pattern that Phase 18 can later automate.

</domain>

<decisions>
## Implementation Decisions

### Phase 14 canonical proof bar
- **D-01:** `POLY-01`, `POLY-02`, and `POLY-03` should be proven primarily by requirement-mapped targeted seam tests, not by a monolithic green suite alone.
- **D-02:** Phase 14 targeted proof should reuse the existing repo seams that already express the real contract: prompt-policy normalization, runtime default precedence, runtime metadata projection, installer mutation/idempotence, installed `/scoria` route viability, explicit knowledge-lane command contract, and migration-lane compatibility.
- **D-03:** One phase-closeout `SCORIA_DB_PORT=55432 MIX_ENV=test mix test` pass should still be recorded, but it is secondary regression-confidence evidence rather than the canonical requirement proof source.
- **D-04:** Phase 14 canonical verification should also include one bounded manual walkthrough for the adopter-visible success lane: install, migrate, test, start one run, read it back, and confirm `/scoria` and `/scoria/workflows/:run_id` expose the same durable run.
- **D-05:** The manual walkthrough must be short, date-stamped, and observation-based. It should record expected facts, not screenshots or vague “looked good” language.

### Phase 15 canonical proof bar
- **D-06:** `ADOP-01` through `ADOP-04` should be proven by a layered repo-native proof matrix: targeted runtime/install tests, bounded semantic content assertions against README and docs, and compile/doc-presence checks for the public modules.
- **D-07:** The existing runtime integration suite remains the strongest behavioral anchor for the docs/example story. Phase 15 verification should treat the public runtime seam as truth and the docs as aligned projections of that seam.
- **D-08:** Because `/scoria/workflows/:run_id` is part of the promised operator-evidence lane, Phase 15 canonical verification should include one bounded manual operator walkthrough in addition to automation.
- **D-09:** Raw wording-grep checks are acceptable as a narrow backfill tactic, but they should stay semantic and contract-oriented rather than overfitting exact prose. Presence-only assertions must not be mistaken for behavioral proof.
- **D-10:** Executable docs, doctest-backed snippets, or a sample Phoenix app are valuable future hardening layers, but they are not required to close Phase 17. Those belong as optional follow-on guards once the canonical proof chain exists.

### Verification artifact shape
- **D-11:** Canonical verification must be restored inside the original phase directories as `.planning/phases/14-policy-defaults-and-install-ergonomics/14-VERIFICATION.md` and `.planning/phases/15-adoption-surface-docs-and-example-flow/15-VERIFICATION.md`.
- **D-12:** Phase 17 may also emit a small aggregate summary or verification index, but that file must declare itself derived from the canonical phase-local verification files rather than acting as the sole source of truth.
- **D-13:** Verification files should follow the same chronology-aware shape established in Phases 12, 13, and 7: explicit `verified_on`, explicit `verified_by_phase`, requirement coverage tied to real proof commands, and evidence-chain notes that preserve the backfill history.
- **D-14:** Machine-readable verification manifests or attestation-style sidecars are not required for this phase. They are only worth adding later if downstream agent automation or CI policy enforcement genuinely needs them.

### Reconciliation breadth
- **D-15:** After backfilling Phase 14 and Phase 15 verification, Scoria should reconcile all non-historical live truth surfaces that still imply the defaults/adoption work is pending or only summary-closed.
- **D-16:** Reconciliation should be broad enough that maintainers, adopters, operators, and downstream planning agents all read the same present-tense story. At minimum, this includes `ROADMAP.md`, `REQUIREMENTS.md`, `STATE.md`, `PROJECT.md`, `MILESTONES.md`, and the relevant phase `VALIDATION.md` files.
- **D-17:** Because Phase 15’s adoption surface is public product surface, reconciliation may also update current public docs when they still speak in a pre-verification or speculative posture, provided the edits are current-truth alignment rather than new product decisions.
- **D-18:** Historical milestone audits and dated summaries remain immutable forensic snapshots. Phase 17 must supersede them with fresh current-truth artifacts, not rewrite them.

### Ecosystem and DX posture
- **D-19:** The verification shape should stay idiomatic to an embedded Phoenix/Ecto/Plug library: explicit install/config/router proof like Phoenix LiveDashboard and Oban, test-first public seams, and minimal bespoke harnesses.
- **D-20:** Scoria should avoid the common AI-framework footgun of treating “green tests” or a dashboard screenshot as sufficient proof of adoption success. Canonical proof must connect the public runtime seam, durable truth, and operator evidence chain.
- **D-21:** Scoria should also avoid the opposite footgun of over-building a second sample product or generator-heavy fixture app just to prove a narrow backfill. Phase 17 should stay boring, explicit, and maintainable.
- **D-22:** Future GSD defaults should shift this verification pattern left: backfill phases should default to targeted requirement proof, one secondary full-suite confidence pass, bounded manual acceptance only where the product promise is inherently human-visible, canonical phase-local verification files, and broad current-truth reconciliation with immutable historical audits.
- **D-23:** User interruption should be reserved only for materially product-shaping exceptions to that pattern. Artifact placement, chronology fields, reconciliation scope across active docs, and proof-matrix conventions should become GSD defaults.

### the agent's Discretion
- Exact command grouping for the Phase 14 and Phase 15 proof matrices, provided each requirement still maps to a primary seam-specific proof command.
- Exact wording of the bounded manual walkthrough scripts, provided they record explicit expected observations and durable identifiers.
- Exact aggregate-summary filename and shape for Phase 17, provided it is clearly derived and does not compete with the phase-local verification files.
- Exact list of non-historical live docs to reconcile beyond the required minimum, provided the line between active truth and immutable historical snapshots stays explicit.

</decisions>

<specifics>
## Specific Ideas

- The right overall shape is the same one successful Phoenix libraries teach:
  - obvious install/config/router proof
  - explicit public seam tests
  - current docs aligned to shipped behavior
  - no mystery second runtime or hidden generated app as the real source of truth
- Phoenix and Oban are good local precedent for boring, explicit DX: stable install path, normal tests, normal docs, and clear upgrade/current-truth surfaces.
- Ash is a good lesson for docs shape: separate tutorials/how-to/reference cleanly, and use a real example app as an optional teaching asset rather than making it the canonical proof bar for every phase.
- Popular adjacent AI ecosystems reinforce the same split:
  - LangGraph and OpenAI Agents get durable run/session/tracing continuity right and treat that as contract, not just implementation detail.
  - Rust/Go-style executable docs are excellent for tight API snippets, but they are not a great substitute for a stateful Phoenix operator walkthrough.
  - Supply-chain attestation formats are useful inspiration for future machine-readable verification, but they are too heavy for this planning backfill unless Phase 18 or later needs strict agent/CI enforcement.
- Phase 17 should intentionally prepare the repo for Phase 18:
  - restore canonical verification first
  - align live truth second
  - only then add executable drift guards

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone intent and current truth
- `.planning/ROADMAP.md` - Phase 17 goal, plan breakdown, and requirement coverage.
- `.planning/PROJECT.md` - Keystone milestone boundary, embedded Phoenix-first product posture, and current product thesis.
- `.planning/REQUIREMENTS.md` - `POLY-01`, `POLY-02`, `POLY-03`, `ADOP-01`, `ADOP-02`, `ADOP-03`, and `ADOP-04`.
- `.planning/STATE.md` - current milestone posture and the handoff from Phase 16 into Phase 17.
- `.planning/MILESTONES.md` - active milestone summary surface that may need reconciliation.

### Prior phase decisions and verification precedent
- `.planning/phases/14-policy-defaults-and-install-ergonomics/14-CONTEXT.md` - locked defaults/install decisions that Phase 17 must verify rather than reopen.
- `.planning/phases/15-adoption-surface-docs-and-example-flow/15-CONTEXT.md` - locked docs/example/verification-lane decisions that Phase 17 must verify rather than reopen.
- `.planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-CONTEXT.md` - direct precedent for backfill scope, artifact shape, and reconciliation philosophy.
- `.planning/phases/12-canonical-runtime-identity/12-VERIFICATION.md` - example of chronology-aware backfilled verification in the original phase directory.
- `.planning/phases/13-public-runtime-api-and-session-lifecycle/13-VERIFICATION.md` - example of requirement-to-command matrix for public seam verification.
- `.planning/phases/07-seismograph/07-VERIFICATION.md` - precedent for canonical verification plus live-state supersession over immutable historical audits.
- `.planning/phases/11-re-verify-seismograph-and-align-milestone-state/11-CONTEXT.md` - earlier backfill-phase precedent for artifact placement and state alignment.

### Current validation and code/docs proof seams
- `.planning/phases/14-policy-defaults-and-install-ergonomics/14-VALIDATION.md` - Phase 14 automated proof matrix and current test lanes.
- `.planning/phases/15-adoption-surface-docs-and-example-flow/15-VALIDATION.md` - Phase 15 automated proof matrix and current docs/runtime lanes.
- `README.md` - current public adoption surface that must align with verified runtime truth.
- `docs/operator_verification.md` - current default operator verification lane and likely source for bounded manual acceptance.
- `docs/phoenix_runtime_example.md` - current canonical Phoenix runtime example.
- `lib/scoria.ex` - top-level public facade that the docs and proof should treat as the happy-path API.
- `lib/scoria/runtime.ex` - fuller public runtime lifecycle layer.
- `lib/scoria/identity.ex` - canonical identity normalization seam used in the docs example.
- `lib/scoria/prompt_policy.ex` - canonical prompt-policy noun from Phase 14.
- `lib/mix/tasks/scoria.install.ex` - installer output and default-lane messaging.
- `test/scoria/runtime/defaults_test.exs` - policy/defaults proof seam.
- `test/scoria/runtime_test.exs` - runtime-level public seam coverage.
- `test/scoria/runtime_integration_test.exs` - strongest end-to-end runtime/operator alignment proof lane.
- `test/mix/tasks/scoria.install_test.exs` - installer mutation/idempotence proof seam.
- `test/mix/tasks/scoria.install_route_smoke_test.exs` - installed `/scoria` route viability proof seam.
- `test/scoria/bootstrap/migration_lane_compatibility_test.exs` - default core lane vs optional knowledge lane boundary proof seam.
- `test/mix/tasks/scoria.test_knowledge_test.exs` - explicit knowledge-lane command contract.

### Research and product-shape guidance
- `prompts/scoria-gsd-kickoff.md` - batteries-included, operator-grade, Phoenix-native vision.
- `prompts/sztheory-elixir-dna.md` - batteries-included but composable, operator-first, zero-config onboarding rules.
- `prompts/phoenix-ai-lib-deep-research.md` - ecosystem lessons around Phoenix-native AI ops, trace/eval/product shape, and adjacent library patterns.
- `prompts/scoria-brand-book-deep-research.md` - evidence-first and operator-grade public posture.
- `.planning/research/milestone-options-2026-05-12.md` - rationale for Keystone-first sequencing and least-surprise Phoenix adoption.
- `.planning/seeds/SEED-001-agentcore-lessons.md` - explicit session identity, tool governance, observability, and anti-platform-drift guidance.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The existing Phase 14 validation matrix already identifies the exact automated proof seams needed for `POLY-*`; Phase 17 should promote those into canonical verification rather than inventing new coverage categories.
- The existing Phase 15 validation matrix already combines runtime tests, docs assertions, and moduledoc checks; Phase 17 should harden that into a canonical verification narrative with clearer distinction between behavioral proof and wording checks.
- `test/scoria/runtime_integration_test.exs` is the strongest single file tying together runtime truth, session/run semantics, and `/scoria/workflows/:run_id` operator evidence.
- `docs/operator_verification.md` already provides the bones of the bounded manual acceptance script the research recommends.
- The Phase 12, 13, and 7 verification files already model the right chronology-aware artifact shape.

### Established Patterns
- Scoria prefers phase-local canonical truth, with later phases reconciling around it rather than relocating it.
- The repo already distinguishes primary seam-specific proof from secondary confidence passes.
- Live docs and state files are meant to reflect current truth; dated audits are forensic snapshots.
- The product posture is embedded and Phoenix-first, so verification should feel like proving a normal library integration, not a hosted platform rollout.

### Integration Points
- Create `.planning/phases/14-policy-defaults-and-install-ergonomics/14-VERIFICATION.md`.
- Create `.planning/phases/15-adoption-surface-docs-and-example-flow/15-VERIFICATION.md`.
- Update `.planning/phases/14-policy-defaults-and-install-ergonomics/14-VALIDATION.md` and `.planning/phases/15-adoption-surface-docs-and-example-flow/15-VALIDATION.md` so they agree with terminal truth after verification closes.
- Reconcile active truth surfaces including roadmap/state/project/requirements/milestones and any still-stale current public docs.
- If Phase 17 emits its own summary/index, keep it link-first and derived from the phase-local verification artifacts.

</code_context>

<deferred>
## Deferred Ideas

- Adding doctest-backed executable docs for selected public API snippets as a Phase 18+ hardening layer.
- Building a long-lived sample Phoenix app or fixture-app smoke suite as a stronger adoption regression guard if the installer surface grows materially.
- Introducing machine-readable verification manifests or attestation-style sidecars before there is a concrete CI/agent enforcement use case.
- Rewriting historical milestone audits or dated summaries to erase the fact that the verification gaps existed.

</deferred>

---

*Phase: 17-re-verify-keystone-defaults-and-adoption-surface*
*Context gathered: 2026-05-16*
