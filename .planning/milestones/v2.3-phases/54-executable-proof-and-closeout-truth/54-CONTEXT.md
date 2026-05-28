# Phase 54: Executable proof and closeout truth - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Back the runtime-to-handoff adopter example with one bounded, executable proof lane and align all support surfaces to the same verified command, while preserving the default-lane-first adoption contract and recording milestone closeout truth with auditable verification evidence.

</domain>

<decisions>
## Implementation Decisions

### Proof lane command and scope
- **D-01:** Publish a dedicated canonical runtime-to-handoff proof lane command: `mix test.runtime_to_handoff`, backed by `mix scoria.test.runtime_to_handoff`.
- **D-02:** Keep `mix test.adoption` as the canonical default-lane verifier; do not fold runtime-to-handoff proof into the default lane.
- **D-03:** The runtime-to-handoff lane remains bounded to public-contract runtime-to-handoff coverage and command-alignment proof, not broad full-suite behavior.

### Prerequisite-independence proof
- **D-04:** The runtime-to-handoff proof lane must explicitly prove that semantic fast path, knowledge/pgvector setup, retrieval setup, and hosted onboarding are not hidden prerequisites.
- **D-05:** Add negative-contract assertions that the runtime-to-handoff lane does not invoke optional-lane setup behavior (for example, no knowledge bootstrap requirements) while still passing end-to-end runtime-to-handoff verification.
- **D-06:** Run the canonical runtime-to-handoff lane in a minimal environment profile in CI and local proof guidance; optional mirrored runs can be added for drift detection but are not part of the canonical command contract.

### Support-surface command alignment
- **D-07:** README, operator verification, adoption lane guide, runtime example, and bounded handoff guide must all reference the same canonical runtime-to-handoff command string.
- **D-08:** Use shared source fragments in `Scoria.TestSupport.AdoptionExample` plus existing docs drift tests to enforce command consistency and lane-boundary wording.
- **D-09:** Replace Phase 53 placeholder-command refutes with Phase 54 canonical-command assertions and refutes for unsupported synonyms that would dilute support truth.

### Closeout verification truth
- **D-10:** Milestone closeout proof chain for `v2.3` is: `MIX_ENV=dev mix scoria.release_preview`, `MIX_ENV=test mix test.adoption`, then `MIX_ENV=test mix test.runtime_to_handoff`.
- **D-11:** Plan-level narrow verification is allowed during implementation, but milestone closeout requires the full closeout chain unless a documented temporary exception is recorded.
- **D-12:** Any exception to the full closeout chain requires explicit ledger evidence: blocked command, blocker evidence, compensating checks, owner, expiry, and follow-up rerun before final closeout.

### Claude's Discretion
- Exact file membership in `mix scoria.test.runtime_to_handoff` may be tuned for speed and stability as long as the lane still proves runtime-to-handoff behavior and prerequisite independence.
- Optional secondary CI matrix coverage may be added if it does not change the canonical command contract presented to adopters.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and product constraints
- `.planning/ROADMAP.md` - Phase 54 goal, success criteria, and plan split.
- `.planning/REQUIREMENTS.md` - `DOCS-02`, `PROOF-01`, and `PROOF-02` requirement ownership.
- `.planning/PROJECT.md` - milestone goals, support-truth boundary, and default-lane-first product contract.
- `.planning/STATE.md` - active milestone state and prior phase decisions.
- `.planning/phases/53-operator-evidence-and-lane-guidance/53-CONTEXT.md` - locked Phase 53 lane wording and boundary decisions carried into Phase 54.
- `.planning/phases/53-operator-evidence-and-lane-guidance/53-DISCUSSION-LOG.md` - alternatives considered for default-lane vs handoff guidance.

### Existing proof lane/task surfaces
- `mix.exs` - `preferred_envs` and task discoverability contract.
- `lib/mix/tasks/test.adoption.ex` - default-lane bounded verifier pattern.
- `lib/mix/tasks/scoria.release_preview.ex` - package/docs proof lane pattern.
- `lib/mix/tasks/test.semantic_fast_path.ex` - optional semantic lane wrapper pattern.
- `lib/mix/tasks/scoria.test.knowledge.ex` - optional knowledge lane setup pattern.

### Support surfaces to align
- `README.md` - top-level lane contract and verification commands.
- `docs/operator_verification.md` - canonical closeout and verifier wording.
- `docs/adoption_lanes.md` - lane hierarchy and escalation wording.
- `docs/phoenix_runtime_example.md` - runtime-to-handoff example contract.
- `docs/bounded_handoffs.md` - bounded handoff contract and safety wording.

### Contract tests and runtime proof anchors
- `test/scoria/adoption_surface_test.exs` - docs/support truth invariant checks.
- `test/support/scoria/adoption_example.ex` - shared source fragments for docs consistency.
- `test/scoria/phoenix_example_source_test.exs` - runtime example source-fragment contract.
- `test/scoria/handoff_example_source_test.exs` - bounded handoff source-fragment contract.
- `test/scoria/runtime_test.exs` - runtime and handoff contract assertions.
- `test/scoria/runtime_integration_test.exs` - end-to-end runtime public facade proof.
- `test/scoria/host_app_consumer_proof_test.exs` - generated-host proof harness baseline.

### Prior research and project guidance
- `.planning/phases/53-operator-evidence-and-lane-guidance/53-RESEARCH.md` - prior phase evidence and lane wording research.
- `.planning/phases/53-operator-evidence-and-lane-guidance/53-PATTERNS.md` - existing patterns for docs/test/operator surfaces.
- `prompts/phoenix-ai-lib-deep-research.md` - ecosystem-level architecture, DX, and ops lessons.
- `prompts/sztheory-elixir-dna.md` - batteries-included, operator-first, Phoenix/Ecto-native standards.
- `prompts/scoria-brand-book-deep-research.md` - product voice and support-truth UX language constraints.
- `prompts/scoria-gsd-kickoff.md` - project objective and execution emphasis.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mix test.adoption` and existing lane wrappers provide the exact task-shape pattern to reuse for a new bounded proof lane.
- `Scoria.AdoptionSurfaceTest` already enforces docs command and lane wording contracts through lightweight ExUnit file assertions.
- `Scoria.TestSupport.AdoptionExample` already centralizes reusable docs fragments and can carry canonical command fragments for Phase 54.
- Runtime contract tests (`test/scoria/runtime_test.exs`, `test/scoria/runtime_integration_test.exs`) already validate core start/run/handoff/readback behavior on public surfaces.

### Established Patterns
- Scoria publishes named bounded proof lanes rather than broad suite instructions for adopter-facing verification.
- Optional lanes (semantic, knowledge) are explicit commands and must not become hidden prerequisites for default or bounded runtime adoption proof.
- Support truth is protected by docs drift assertions and explicit refutes for unsupported command shapes.

### Integration Points
- Add new runtime-to-handoff task and wrapper under `lib/mix/tasks/` and wire `preferred_envs` in `mix.exs`.
- Update canonical command wording in `README.md` and docs under `docs/`.
- Update docs/source drift contracts in `test/scoria/adoption_surface_test.exs` and `test/support/scoria/adoption_example.ex`.
- Add verification/ledger artifact for closeout evidence in this phase directory.

</code_context>

<specifics>
## Specific Ideas

- Recommendation style is intentionally one-shot and coherent: one canonical runtime-to-handoff command, one lane hierarchy story, one closeout truth chain.
- Principle of least surprise is treated as a hard constraint: each lane does one job and command naming never implies optional prerequisites.
- UX/DX emphasis is explicit: contributors should be able to run one bounded command, understand why it failed, and trust that docs/CI/use-site wording match.

</specifics>

<deferred>
## Deferred Ideas

- Host-app-heavy runtime-to-handoff proof as the primary canonical verifier (can be a supplemental lane if needed later).
- Command registry/generator system for docs strings (defer unless command surface grows beyond lightweight fragment-based drift tests).
- Broad multi-command alias matrix for the same lane (defer to avoid support ambiguity).

</deferred>

---

*Phase: 54-executable-proof-and-closeout-truth*
*Context gathered: 2026-05-27*
