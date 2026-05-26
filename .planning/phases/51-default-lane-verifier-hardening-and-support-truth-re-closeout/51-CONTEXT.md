# Phase 51: Default-lane verifier hardening and support-truth re-closeout - Context

**Gathered:** 2026-05-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Make Scoria's canonical default-lane verifier truthful, bounded, and green again in the supported test environment, then re-close the support-truth work from Phase 49 with executable proof.

Phase 51 does not rename the lane model, add a second public verifier, or widen the default adoption path to absorb optional semantic or knowledge surfaces. It hardens the existing `mix test.adoption` contract, preserves generated-host proof inside that command, and writes the missing `49-VERIFICATION.md` from fresh bounded evidence.

</domain>

<decisions>
## Implementation Decisions

### Timeout contract
- **D-01:** `mix test.adoption` remains the single canonical default-lane verifier. Scoria should not hide the generated-host proof behind a second public command or a maintainer-only verifier.
- **D-02:** The current implicit ExUnit default timeout is false for the generated-host proof. Phase 51 should replace that accidental contract with an explicit scoped timeout budget for the fresh-host proof itself, while leaving the rest of the suite on normal defaults.
- **D-03:** The published budget should be honest and boring rather than aspirational. Downstream planning should assume a narrow verifier-specific budget on the order of minutes, not the default `60_000ms`, unless implementation work proves a shorter real budget with margin.
- **D-04:** `mix test.adoption --trace` is a debugging tool, not part of the support contract. Phase 51 proof and docs must use the non-trace command path only.

### Fresh-host proof strictness
- **D-05:** The fresh generated-host proof stays inside `mix test.adoption`. Phase 51 must preserve real proof that a fresh Phoenix host can adopt Scoria through the public install and runtime path.
- **D-06:** Scoria may accelerate the verifier only by reducing duplicated harness cost, not by downgrading the proof to a checked-in sample app, a purely synthetic fixture, or a hidden warm post-install host.
- **D-07:** The generated-host proof should collapse to the smallest honest host-side assertion set:
  current dependency wiring,
  `mix scoria.install`,
  `mix ecto.create`,
  `mix ecto.migrate`,
  `/scoria` route visibility,
  and one durable run/readback/operator-evidence smoke.
- **D-08:** Deeper runtime semantics should remain owned by repo-local adoption/runtime tests instead of being redundantly reproven inside multiple expensive host-side boots.
- **D-09:** A cached pristine Phoenix skeleton is acceptable only as a fail-closed implementation detail if each verifier run still copies it into a fresh workspace, reapplies the current Scoria overlay, reruns the public commands, and invalidates on generator-relevant drift. Cached post-install or post-migrate hosts are not acceptable.

### Phase 49 re-closeout evidence bar
- **D-10:** Re-closing Phase 49 should stay bounded to the already-locked maintainer proof chain:
  `mix scoria.release_preview`
  `mix test.adoption`
- **D-11:** `49-VERIFICATION.md` should not be a prose-only summary. It must explicitly map what the two commands machine-check and cite the source-truth seams that keep README, installer output, and verification guides aligned.
- **D-12:** `49-VERIFICATION.md` should state clearly that `mix test.semantic_fast_path`, `mix test.knowledge`, and `mix test` are not part of the canonical Phase 49 closeout proof.
- **D-13:** Phase 51 should prefer a command-plus-source-truth evidence bar over either extreme:
  not command-only with vague claims,
  and not a broadened “run everything” repo-health sweep.

### Ecosystem posture and DX
- **D-14:** Scoria should stay aligned with idiomatic Phoenix/Elixir library ergonomics: explicit installer/task seams, bounded verification commands, Ecto-backed durable truth, and explicit optional-lane expansion rather than magical sample-app demos.
- **D-15:** Principle of least surprise wins over aggressive speed claims. A real 2-3 minute canonical verifier is preferable to a “fast” verifier that silently depends on hidden caches or no longer proves fresh-host adoption.
- **D-16:** Future optimization work should treat the current host harness like a field proof, not a benchmark target. Cheap structural wins are encouraged; weakening the product claim is not.

### the agent's Discretion
- Exact verifier timeout value and whether it is applied per-test or per-module, as long as the budget is explicit, scoped, and reflected truthfully in docs and verification artifacts.
- Exact host-harness restructuring technique, as long as it preserves one fresh-host proof inside `mix test.adoption` and reduces duplicated host-side boot cost.
- Exact structure of `49-VERIFICATION.md`, as long as it cites the command proof and the source-truth seams that enforce `DOCS-01` and `DOCS-02`.
- Exact implementation of any pristine-host caching optimization, provided it fails closed on drift and never reuses a patched or migrated host as proof.

</decisions>

<specifics>
## Specific Ideas

- The canonical default-lane verifier should feel like a calm field check, not a magic benchmark:
  run the boring command,
  wait a bounded amount of time,
  get one trustworthy answer.
- The right Phoenix-native mental model is installer plus explicit host proof, similar to strong Elixir library prior art that documents installation and verification as operational seams rather than folklore.
- The bad failure mode to avoid is “green only when warm”:
  hidden generator caches,
  checked-in sample apps,
  or `--trace`-only success all weaken the support story.
- Prompt-corpus posture still applies here:
  evidence over intuition,
  visible structure over magic,
  production before spectacle,
  and batteries-included but composable DX.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase And Requirement Contract
- `.planning/ROADMAP.md` — Phase 51 scope, success criteria, and explicit gap-closure statement for the timed-out `mix test.adoption` chain and missing `49-VERIFICATION.md`.
- `.planning/PROJECT.md` — milestone posture: Phoenix-first embedded product shape, support truth, and boring adopter ergonomics.
- `.planning/REQUIREMENTS.md` — authoritative wording for `DOCS-01` and `DOCS-02`.
- `.planning/STATE.md` — active milestone state and current focus on Phase 51.
- `.planning/METHODOLOGY.md` — decisive-defaults and research-first escalation rules; optimize for honest support contracts, not option sprawl.

### Prior Locked Context
- `.planning/phases/48-host-app-install-contract-and-consumer-proof/48-CONTEXT.md` — locked choice to prefer a fresh generated-host proof inside one canonical default-lane verifier.
- `.planning/phases/49-support-truth-and-adoption-closeout/49-CONTEXT.md` — locked lane vocabulary, command family, and milestone closeout chain.
- `.planning/phases/50-release-preview-ci-truth-and-phase-47-verification/50-VERIFICATION.md` — recent precedent for bounded proof artifacts and truthful command-contract repair.
- `.planning/v2.2-MILESTONE-AUDIT.md` — reproduced gaps, including the `mix test.adoption` timeout and missing `49-VERIFICATION.md`.

### Current Verifier And Host-Proof Surfaces
- `lib/mix/tasks/test.adoption.ex` — canonical default-lane verifier composition.
- `test/mix/tasks/test.adoption_test.exs` — exact verifier file-list and discoverability contract.
- `test/scoria/host_app_consumer_proof_test.exs` — current top-level generated-host proof and timeout seam.
- `test/support/scoria/host_app_proof/runner.ex` — nested Mix-step orchestration and current duplicated host-side boot cost.
- `test/support/scoria/host_app_proof/generator.ex` — fresh Phoenix host generation, overlay, and config patch seam.
- `test/support/scoria/host_app_proof/overlay/test/host_runtime_smoke_test.exs` — runtime/operator-evidence smoke executed inside the generated host.
- `test/scoria/runtime_integration_test.exs` — repo-local deep runtime proof that should keep owning semantics beyond the generated-host smoke.

### Adopter-Facing Support Surfaces
- `README.md` — public default-lane story and verification order.
- `docs/operator_verification.md` — canonical maintainer closeout chain and default-lane verification guidance.
- `docs/adoption_lanes.md` — lane hierarchy and optional-lane boundaries.
- `docs/bounded_handoffs.md` — additive handoff posture inside the default runtime story.
- `docs/semantic_fast_path.md` — optional semantic troubleshooting lane and explicit separation from first adoption.
- `lib/mix/tasks/scoria.install.ex` — installer output, optional-lane inventory, and verifier wording surface.
- `test/scoria/adoption_surface_test.exs` — source-truth assertions enforcing public lane wording and command hierarchy.

### Product Posture And Research
- `prompts/phoenix-ai-lib-deep-research.md` — Phoenix-native AI ops posture: compose, normalize, operationalize; explicit bounded nouns and operator-first DX.
- `prompts/scoria-brand-book-deep-research.md` — field-engineer brand posture: evidence over magic, calm operational UX, visible structure.
- `prompts/scoria-gsd-kickoff.md` — batteries-included install and trace-first operator objective.
- `prompts/sztheory-elixir-dna.md` — batteries-included but composable library DNA, zero-config onboarding, operator-first ergonomics.
- `.planning/research/elixir-ai-ecosystem.md` — Scoria’s role as a Phoenix-native quality layer rather than a magical agent platform.
- `.planning/research/agentcore-lessons.md` — explicit session/tool/observability boundaries and anti-magic posture.
- `.planning/research/SUMMARY.md` — v2.2 milestone recommendation to treat adoption closure as truthful package/install/proof work.
- `.planning/research/STACK.md` — guidance to keep publish/adoption helpers inside Mix-task and test-support seams.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Mix.Tasks.Scoria.Test.Adoption` already provides the right bounded task seam; Phase 51 should harden its contract rather than invent a new command family.
- `Scoria.TestSupport.HostAppProof.Generator` already gives Scoria a real fresh-host proof surface; it should remain the freshness anchor.
- `Scoria.TestSupport.HostAppProof.Runner` is the main runtime-cost seam and the best place to collapse duplicate host-side work.
- `test/scoria/adoption_surface_test.exs` already enforces support-truth wording and should remain the primary drift guard for docs/task output alignment.
- `Mix.Tasks.Scoria.ReleasePreview` and `50-VERIFICATION.md` already establish the package/docs closeout half of the final proof chain.

### Established Patterns
- One named verification command per public lane.
- Installer/setup tasks under `mix scoria.*`; verifier tasks under `mix test.*`.
- Durable truth and executable proof over prose-only guidance.
- Optional lanes remain explicit rather than silently folded into the default path.
- Generated-host proof is acceptable when it stays bounded, explicit, and current.

### Integration Points
- Timeout-truth changes will touch the generated-host proof test/module, `mix test.adoption` expectations, and adopter-facing verification docs together.
- Harness acceleration centers on `test/support/scoria/host_app_proof/{generator,runner}.ex` and the host-side smoke overlay.
- Re-closeout work centers on `49-VERIFICATION.md` plus the existing source-truth seams already exercised by `mix test.adoption`.

</code_context>

<deferred>
## Deferred Ideas

- Replacing the fresh generated-host proof with a checked-in sample app or long-lived fixture.
- Introducing a second public verifier to hide or bypass the slow host proof.
- Treating hidden warm caches, prepatched hosts, or `--trace`-only success as acceptable default-lane proof.
- Folding semantic or knowledge verification into the default-lane or Phase 49 closeout chain.
- Broader repo-health closure based on `mix test` instead of the bounded milestone proof chain.

</deferred>

---

*Phase: 51-default-lane-verifier-hardening-and-support-truth-re-closeout*
*Context gathered: 2026-05-26*
