# Phase 43: Canonical Adoption Proof & Milestone Closeout - Context

**Gathered:** 2026-05-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove the bounded handoff lane through one boring canonical adoption path, then close `v2.0 Relay` with an explicit recommendation about whether bounded handoffs are done for now or deserve one narrow follow-up.

This phase does not widen the product, does not reopen already-shipped handoff contract or delegated-evidence work, and does not turn milestone closeout into a repo-wide cleanup campaign. Its job is proof and closure for `ADPT-02`.

</domain>

<decisions>
## Implementation Decisions

### Canonical proof scope
- **D-01:** `mix test.adoption` is the canonical proof lane for Phase 43. It is the explicit `ADPT-02` acceptance harness for the default public-runtime and bounded-handoff adoption story.
- **D-02:** `mix test` remains maintainer repo-health context, not the canonical phase-proof gate. The phase should report broader suite status separately instead of redefining bounded-handoff proof around unrelated red.
- **D-03:** The canonical proof story stays runtime-first and adopter-shaped: install, migration compatibility, public runtime facade, bounded handoff docs/source alignment, exact readback, and operator evidence.
- **D-04:** Optional knowledge-lane setup must stay outside the canonical proof. Phase 43 should preserve the existing distinction between the default runtime lane and optional knowledge features.

### Proof artifact shape
- **D-05:** Phase 43 should produce one thin canonical closeout ledger rather than many sibling proof docs or implicit state-only closure.
- **D-06:** The ledger should be pointer-first, not transcript-first. Link the exact proof sources, tests, docs, and prior phase verification artifacts instead of duplicating their content.
- **D-07:** The closeout ledger should answer four questions in one place:
  - what the canonical proof lane is
  - what evidence proves docs/source/runtime alignment
  - whether broader suite noise exists and why it does or does not matter to `ADPT-02`
  - whether Scoria should stop bounded-handoff work after Relay or carry one narrow follow-up
- **D-08:** The recommended artifact shape is a single Phase 43 closeout/proof document such as `43-CLOSEOUT.md` or equivalent planner-selected name, provided it serves as the canonical synthesis object for this phase.

### Closeout bar
- **D-09:** The default closeout recommendation after Relay is: stop touching bounded handoffs for now unless the canonical proof exposes a concrete adopter-facing failure in the default lane.
- **D-10:** A follow-up is justified only when the proof shows a specific failure in the runtime-first adoption path, such as confusing `run_id`/`session_id` semantics, missing delegated lineage visibility, broken docs/source alignment, or unclear operator evidence for the same durable run.
- **D-11:** “Would be nice” examples, richer delegated notebooks, broader orchestration UX, or general handoff marketing polish do not justify keeping bounded handoffs open after Relay.
- **D-12:** If a follow-up is needed, it should be exactly one narrow adopter-facing fix tied to the failed proof seam, not a vague bucket of possible handoff work.

### Policy for unrelated failures and noise
- **D-13:** Only failures that break `mix test.adoption` or falsify the bounded-handoff support story block `ADPT-02`.
- **D-14:** Broader full-suite failures, warning noise, or adjacent regressions must be named explicitly in the closeout ledger when present, but they should be recorded as unrelated repo debt unless they affect:
  - compile stability
  - migrations
  - the public `Scoria` runtime facade
  - bounded-handoff behavior
  - docs/source fragments in the adoption lane
  - security/trust invariants
- **D-15:** The closeout policy must not use fuzzy “seems unrelated” judgment. Escalation triggers should be explicit so future maintainers can apply the same rule consistently.
- **D-16:** The ledger should preserve repo-health honesty without letting unrelated failures hijack a narrowly defined milestone proof.

### Shift-left and escalation posture
- **D-17:** Planning and future GSD flows should shift low-impact closeout choices left by default. For this lane, the default bias is:
  - one canonical adoption proof command
  - one canonical synthesis ledger
  - one stop-by-default closeout recommendation
  - one explicit unrelated-failure policy
- **D-18:** Only escalate to the user when a choice changes product shape, durable truth, security/policy boundary, tenant blast radius, or the meaning of the canonical proof claim itself.
- **D-19:** This phase should encode those defaults clearly enough that downstream research/planning/execution agents do not need to re-ask routine closeout-structure or proof-scope questions.

### the agent's Discretion
- Exact ledger filename and section naming, provided there is one obvious canonical closeout artifact.
- Exact wording for the final closeout recommendation, provided it remains decisive and falsifiable.
- Exact presentation of broader suite debt, provided the distinction between `ADPT-02` proof and repo-health context stays explicit.
- Exact cross-links into prior verification artifacts, provided downstream readers can follow the proof chain without archaeology.

</decisions>

<specifics>
## Specific Ideas

- The closeout artifact should feel like a calm operator-grade audit note, not a prose-heavy postmortem.
- The right mental model is “one obvious place to answer whether Relay proved the handoff lane” rather than “many checklists the maintainer has to mentally join.”
- The best developer ergonomics here are least-surprise ergonomics: one command maps to one claim, and one ledger maps to one milestone decision.
- User preference to preserve: shift low-impact planning and proof-structure choices left inside GSD; only interrupt on materially consequential boundary decisions.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirement truth
- `.planning/ROADMAP.md` - Phase 43 goal, success criteria, and plan breakdown for canonical adoption proof and closeout.
- `.planning/PROJECT.md` - `v2.0 Relay` thesis, bounded-handoff product boundary, and current milestone posture.
- `.planning/REQUIREMENTS.md` - `ADPT-02` plus the conditional future-candidate framing for stronger examples.
- `.planning/STATE.md` - current milestone state, prior accepted debt, and the narrow bounded-handoff posture.
- `.planning/METHODOLOGY.md` - decisive-defaults lens and shift-left escalation guidance.

### Locked prior phase context
- `.planning/phases/41-bounded-handoff-contract-safety/41-CONTEXT.md` - locked public handoff contract, same-run lineage, and projected-context safety boundary.
- `.planning/phases/42-delegated-evidence-adoption-story/42-CONTEXT.md` - locked delegated-evidence read model and runtime-first docs alignment posture.
- `.planning/phases/42-delegated-evidence-adoption-story/42-GAP-LEDGER.md` - current conclusion that no remaining adopter-facing gap is required unless proof shows otherwise.

### Current adoption and proof surfaces
- `README.md` - canonical runtime-first adoption story and bounded-handoff signpost.
- `docs/operator_verification.md` - default Phoenix verification lane and maintainer closeout guidance.
- `docs/bounded_handoffs.md` - bounded handoff guide, inspectability promise, and current deferred-follow-up language.
- `docs/phoenix_runtime_example.md` - controller-triggered runtime-first example and bounded-handoff branch point.
- `lib/mix/tasks/test.adoption.ex` - canonical adoption verification task and owned file list.
- `test/scoria/adoption_surface_test.exs` - docs/public-surface assertions that back the adoption proof story.
- `test/scoria/handoff_example_source_test.exs` - checked bounded-handoff fragment alignment.
- `test/support/scoria/adoption_example.ex` - canonical checked fragments and route/runtime wording.
- `test/scoria/runtime_integration_test.exs` - runtime-first exact-run proof and workflow evidence alignment.
- `test/scoria/runtime_test.exs` - bounded-handoff contract and delegated-lineage readback expectations.

### Prior verification and milestone-closeout precedent
- `.planning/phases/18-add-executable-adoption-flow-guards/18-VERIFICATION.md` - precedent for executable adoption proof shaping.
- `.planning/phases/36-vanguard-milestone-state-reconciliation/36-VERIFICATION.md` - precedent for explicit planning-truth reconciliation.
- `.planning/phases/40-online-scoring-review-queue/40-VERIFICATION.md` - precedent for pointer-first verification against multiple surfaces.
- `.planning/v1.3-MILESTONE-AUDIT.md` - precedent for one explicit milestone-quality audit artifact over linked evidence.

### Product and ecosystem guidance
- `prompts/scoria-gsd-kickoff.md` - Scoria product vision and operator-grade framing.
- `prompts/phoenix-ai-lib-deep-research.md` - Phoenix-native AI ops product shape, verification-loop lessons, and cross-ecosystem guidance.
- `prompts/scoria-brand-book-deep-research.md` - calm evidence-first brand posture relevant to closeout tone and UX.
- `prompts/sztheory-elixir-dna.md` - batteries-included but composable posture, operator-first DX, and embedded dashboard principles.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Mix.Tasks.Scoria.Test.Adoption` already defines a curated proof lane over the exact surfaces Phase 43 cares about.
- `Scoria.AdoptionSurfaceTest` already verifies README, runtime example, bounded handoff guide, operator-verification guide, and closeout-gap wording as one coherent story.
- `Scoria.RuntimeIntegrationTest` already proves the exact-run runtime path and workflow evidence surface expected by the adoption docs.
- `Scoria.RuntimeTest` already proves the bounded-handoff facade, explicit contract inputs, and delegated readback behavior that Phase 43 should treat as contract truth rather than redesign work.

### Established Patterns
- Scoria prefers one calm public story with deeper layers linked underneath rather than multiple competing onboarding or proof paths.
- Planning artifacts in this repo work best when one top-level document synthesizes and links deeper evidence rather than scattering milestone truth.
- The product posture is explicit, Phoenix-native, operator-visible, and least-surprise by default.

### Integration Points
- Phase 43 planning should center on the adoption verification task, adoption/docs tests, runtime integration/runtime contract tests, roadmap/requirements/state updates, and one canonical closeout ledger artifact.
- If broader suite failures are reported, the plan should record them in the closeout artifact only after checking whether they cross the explicit escalation triggers above.
- The planner should bake the user’s shift-left preference into the plan so future proof-structure decisions are not re-escalated unnecessarily.

</code_context>

<deferred>
## Deferred Ideas

- Richer delegated notebook-style forensics or heavier operator UX beyond the current runtime/detail and workflow evidence surfaces.
- Stronger bounded-handoff example families beyond the current runtime example and bounded-handoff guide unless canonical proof shows a real adoption failure.
- Any broader multi-agent or orchestration positioning beyond the narrow bounded-handoff lane.
- Turning Phase 43 into a repo-wide cleanup project for unrelated eval, prompt, replay, or operator-surface failures.

</deferred>

---

*Phase: 43-canonical-adoption-proof-milestone-closeout*
*Context gathered: 2026-05-24*
