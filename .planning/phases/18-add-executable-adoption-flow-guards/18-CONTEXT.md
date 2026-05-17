# Phase 18: Add Executable Adoption Flow Guards - Context

**Gathered:** 2026-05-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Add lightweight executable guards around Scoria's public adoption surface so the README, canonical Phoenix example, and operator verification flow stay aligned with the shipped Keystone runtime contract.

This phase hardens the existing adoption story. It does not introduce a new runtime model, a second sample product, browser-heavy app testing, or a broader docs IA rewrite. The goal is to make the current boring Phoenix install path harder to drift and easier to trust.

</domain>

<decisions>
## Implementation Decisions

### README and public surface guard strictness
- **D-01:** README and public adoption guards should use medium strictness: semantic contract assertions plus executable checks for stable pure snippets, not whole-README snapshots or whole-guide execution.
- **D-02:** The README should remain a curated public narrative. Scoria should not treat the full README as the executable spec or force prose structure to satisfy test harnesses.
- **D-03:** Stable public API examples around `Scoria`, `Scoria.Identity`, and other pure facade-level contracts should move toward doctested moduledocs or small shared markdown/code fragments so argument shapes and return expectations cannot silently drift.
- **D-04:** Stateful Phoenix adoption flow proof must live in dedicated integration tests, not in README-wide doctests or brittle snapshots.

### Canonical Phoenix example executability
- **D-05:** The canonical Phoenix example should remain docs-first, but its code fragments should be derived from reusable checked example helpers or modules exercised by the existing runtime integration lane.
- **D-06:** Scoria should harden the current truth source instead of inventing a fixture Phoenix app. The existing runtime integration seam is the canonical behavioral source for the example flow.
- **D-07:** Doctests or `doctest_file` coverage are appropriate only for narrow pure snippets such as facade usage or identity normalization. They are not the right mechanism for controller/session/router/operator walkthroughs.
- **D-08:** The docs must continue teaching the controller-triggered Phoenix flow as the default adoption story, with code that is copy-pasteable and traceable back to checked runtime helpers.

### Operator verification harness
- **D-09:** The operator verification guide remains the human walkthrough, but the canonical executable guard should be a repo-native layered harness: installer mutation checks, route smoke checks, runtime truth assertions, and a bounded LiveView acceptance test for `/scoria/workflows/:run_id`.
- **D-10:** The LiveView/operator guard should start a real run through the public `Scoria` facade, read it back through the public runtime contract, and assert that the mounted operator page reflects the same durable run state.
- **D-11:** Operator-facing assertions should prefer durable identifiers and state transitions over brittle copy assertions wherever possible.
- **D-12:** Browser E2E rigs and a long-lived fixture host app are out of scope for the default Phase 18 harness unless future UI behavior becomes meaningfully client-side or the installer surface grows beyond what the current Phoenix-native test seam can credibly prove.

### Guard placement and lane strategy
- **D-13:** Adoption guards should remain normal ExUnit tests that pass under `mix test`. The default Phoenix adoption path is first-class and should not be hidden behind opt-in tags by default.
- **D-14:** Scoria should add one explicit adoption-focused lane such as `mix test.adoption` or `mix scoria.test.adoption` that runs the targeted adoption guard files for fast local and CI feedback, while still keeping those tests eligible for the full default suite.
- **D-15:** `mix test.knowledge` remains the distinct heavier lane for the optional knowledge path. Adoption guards should follow the same “boring core lane vs explicit heavier lane” posture established in earlier phases.
- **D-16:** ExUnit tags, separate CI jobs, or heavier fixture-app lanes should be reserved for genuinely heavier future checks, not for the default docs/runtime/operator contract.

### Ecosystem and architecture posture
- **D-17:** Phase 18 should follow idiomatic Elixir/Phoenix library patterns: doctest pure examples, verify mounted routes and LiveView surfaces with normal Phoenix test tools, and avoid shadow products that become a second source of truth.
- **D-18:** Strong outside precedents to learn from are: Oban's shared-source docs posture, Phoenix/LiveDashboard's normal router-mount-and-test model, and broader ecosystem practice where executable docs cover small API examples while integration stories use dedicated tests.
- **D-19:** Phase 18 should explicitly avoid the common footguns seen in adjacent AI/tooling ecosystems:
  - docs-only flows that silently drift from runtime truth
  - sample apps that become the real maintained product
  - snapshot-heavy public-surface tests that calcify wording and UI
  - browser E2E lanes introduced before the server-driven surface actually requires them

### Shift-left preference for GSD
- **D-20:** Low-impact adoption-hardening decisions like guard strictness, doctest-vs-integration split, and default lane placement should be shifted left within GSD for future phases. The default preference should be:
  - keep curated docs curated
  - derive stable pure examples from checked code
  - prove stateful Phoenix flows with integration tests
  - keep the default adoption lane first-class
- **D-21:** User interruption should be reserved only for materially impactful escalations such as introducing a fixture host app, browser E2E infrastructure, snapshot-enforced public presentation, or a materially different product-shape teaching posture.

### the agent's Discretion
- Exact naming and implementation shape of the adoption-focused test lane, provided it remains easy to discover, run locally, and wire into CI.
- Exact mechanism for sharing code between docs and tests, provided the canonical Phoenix example is derived from checked code rather than maintained as disconnected prose.
- Exact assertion style for README and operator guards, provided the tests emphasize stable contract semantics and durable state over wording trivia.
- Exact file layout for example helper modules or shared fragments, provided the public docs remain readable and the test source of truth stays obvious.

</decisions>

<specifics>
## Specific Ideas

- The coherent Phase 18 shape is:
  - README stays polished and human-readable
  - pure facade snippets become executable where practical
  - the canonical Phoenix example is derived from checked runtime helpers
  - the operator flow is proven through Phoenix-native integration + LiveView acceptance tests
  - the whole adoption surface stays in the boring default lane, with one named focused lane for quick feedback
- The repo already contains the right underlying building blocks:
  - `test/scoria/adoption_surface_test.exs` for semantic docs/public-surface checks
  - `test/scoria/runtime_integration_test.exs` for public runtime truth, same-session semantics, and operator-page alignment
  - `test/mix/tasks/scoria.install_test.exs` and `test/mix/tasks/scoria.install_route_smoke_test.exs` for install and mount seams
  - `.github/workflows/ci.yml` already treating adoption closure as an explicit subset before the broader suite
- Strong ecosystem lessons to carry forward:
  - Oban is a good model for shared-source docs and explicit install/test posture.
  - Phoenix and LiveDashboard are good models for router-mounted surfaces proven by normal framework tests rather than browser-heavy harnesses.
  - Rust and Go are good reminders that executable examples work best for small stable API slices, not full stateful application walkthroughs.
- Phase 18 should preserve Scoria's public feel:
  - operator-grade and evidence-first
  - copy-pasteable and boring to adopt
  - embedded Phoenix library, not managed platform theater
  - principle-of-least-surprise for maintainers and adopters

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirement intent
- `.planning/ROADMAP.md` - Phase 18 goal, plan breakdown, and Keystone sequencing.
- `.planning/PROJECT.md` - embedded Phoenix-first product boundary and least-surprise adoption thesis.
- `.planning/REQUIREMENTS.md` - `ADOP-01`, `ADOP-02`, and `ADOP-03` as the adoption contract this phase is hardening.
- `.planning/STATE.md` - current transition from Phase 17 verification closeout into Phase 18 hardening work.
- `.planning/MILESTONE-ARC.md` - milestone sequencing rule that adoption prerequisites outrank adjacent expansion.

### Prior Keystone decisions
- `.planning/phases/14-policy-defaults-and-install-ergonomics/14-CONTEXT.md` - boring default lane vs optional knowledge lane and shift-left preference for low-impact defaults.
- `.planning/phases/15-adoption-surface-docs-and-example-flow/15-CONTEXT.md` - locked adoption semantics, canonical Phoenix example posture, and operator verification story.
- `.planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-CONTEXT.md` - verification philosophy and explicit note that executable docs/guards are a valid follow-on hardening layer after canonical proof exists.

### Current public adoption surface
- `README.md` - current runtime-first public story and verification guidance.
- `docs/phoenix_runtime_example.md` - canonical controller-triggered Phoenix adoption flow.
- `docs/operator_verification.md` - default Phoenix verification lane and operator evidence walkthrough.
- `lib/scoria.ex` - top-level happy-path public facade.
- `lib/scoria/identity.ex` - canonical identity normalization surface with pure example potential.
- `lib/scoria/runtime.ex` - public runtime lifecycle layer behind the facade.
- `lib/mix/tasks/scoria.install.ex` - install output and next-step messaging that the adoption guards should keep honest.

### Existing executable proof seams
- `test/scoria/adoption_surface_test.exs` - current semantic docs/public-surface assertions.
- `test/scoria/runtime_integration_test.exs` - strongest existing runtime/example/operator proof seam.
- `test/mix/tasks/scoria.install_test.exs` - installer mutation and idempotence seam.
- `test/mix/tasks/scoria.install_route_smoke_test.exs` - mounted `/scoria` route viability seam.
- `.github/workflows/ci.yml` - current CI lane shape showing adoption-focused checks ahead of the broader suite.
- `lib/mix/tasks/scoria.test.knowledge.ex` - explicit heavier lane precedent that adoption guards should mirror conceptually without becoming optional.

### Product and ecosystem guidance
- `prompts/scoria-gsd-kickoff.md` - batteries-included Phoenix AI ops vision and operator-grade posture.
- `prompts/sztheory-elixir-dna.md` - batteries-included but composable defaults, embedded LiveView dashboards, and zero-config onboarding.
- `prompts/phoenix-ai-lib-deep-research.md` - ecosystem analysis and lessons from Phoenix-native and adjacent AI/runtime libraries.
- `prompts/scoria-brand-book-deep-research.md` - public docs voice, copy-pasteable examples, and anti-hype/product-boundary constraints.
- `.planning/seeds/SEED-001-agentcore-lessons.md` - avoid managed-runtime drift and keep runtime truth explicit and boundary-driven.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `test/scoria/runtime_integration_test.exs` already proves the exact semantics the docs teach: public-facade starts, exact `run_id` resume, same-session fresh runs, and `/scoria/workflows/:run_id` operator alignment.
- `test/scoria/adoption_surface_test.exs` already provides the lightweight semantic docs-guard seam that Phase 18 can tighten rather than replace.
- Installer and route smoke tests already encode the boring Phoenix install path and should remain the fast baseline guard.
- `Scoria` and `Scoria.Identity` moduledocs are already narrow enough that selected pure examples could be promoted into doctested public snippets without distorting the product shape.

### Established Patterns
- The repo already distinguishes the default core lane from the optional knowledge lane. Phase 18 should preserve that lane discipline.
- Scoria already treats the public facade as the happy path and uses Phoenix-native test seams to prove mounted UI behavior.
- CI already recognizes an adoption-focused subset before the broader suite, which makes a named adoption lane a natural extension rather than a new philosophy.

### Integration Points
- Introduce shared example helpers/modules that can be exercised by runtime integration tests and referenced by docs.
- Tighten `test/scoria/adoption_surface_test.exs` around public contract semantics while leaving prose freedom intact.
- Potentially add doctest coverage for pure public facade and identity examples.
- Add a named adoption-focused test lane that reuses normal ExUnit files and current CI posture.

</code_context>

<deferred>
## Deferred Ideas

- A long-lived fixture Phoenix host app as the canonical adoption proof source.
- Browser E2E or JS-heavy acceptance infrastructure for the default operator verification lane.
- README-wide snapshots or whole-guide execution as the default public-surface enforcement mechanism.
- Broader docs IA restructuring or product-story rewrites beyond what is needed to keep the current adoption lane executable and trustworthy.

</deferred>

---

*Phase: 18-add-executable-adoption-flow-guards*
*Context gathered: 2026-05-16*
