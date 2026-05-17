# Phase 18: Add Executable Adoption Flow Guards - Research

**Researched:** 2026-05-16 [VERIFIED: system date]
**Domain:** Elixir/Phoenix adoption-surface guardrails for docs, runtime examples, and operator verification [VERIFIED: phase context]
**Confidence:** HIGH [VERIFIED: repo grep, targeted mix test, official docs]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
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

### Deferred Ideas (OUT OF SCOPE)
- A long-lived fixture Phoenix host app as the canonical adoption proof source.
- Browser E2E or JS-heavy acceptance infrastructure for the default operator verification lane.
- README-wide snapshots or whole-guide execution as the default public-surface enforcement mechanism.
- Broader docs IA restructuring or product-story rewrites beyond what is needed to keep the current adoption lane executable and trustworthy.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADOP-01 | README and install guidance reflect shipped public runtime entrypoints. [VERIFIED: `.planning/REQUIREMENTS.md`] | Keep semantic README assertions, add pure snippet doctests, and keep install/route smoke in the default lane. [VERIFIED: repo grep, official docs] |
| ADOP-02 | One end-to-end Phoenix flow shows request/session context mapped into Scoria identity and runtime APIs. [VERIFIED: `.planning/REQUIREMENTS.md`] | Reuse `test/scoria/runtime_integration_test.exs` as the truth source and extract stable checked example fragments instead of building a fixture app. [VERIFIED: repo grep, targeted mix test] |
| ADOP-03 | Default verification guidance proves the core lane without requiring the knowledge lane. [VERIFIED: `.planning/REQUIREMENTS.md`] | Keep adoption guards in `mix test`, add one named focused adoption lane, and keep `mix test.knowledge` separate. [VERIFIED: repo grep, official docs] |
</phase_requirements>

## Summary

Scoria already has the right executable seams for this phase: semantic docs assertions in [`test/scoria/adoption_surface_test.exs`](/Users/jon/projects/scoria/test/scoria/adoption_surface_test.exs), stateful public-runtime and operator alignment in [`test/scoria/runtime_integration_test.exs`](/Users/jon/projects/scoria/test/scoria/runtime_integration_test.exs), and install/router proof in [`test/mix/tasks/scoria.install_test.exs`](/Users/jon/projects/scoria/test/mix/tasks/scoria.install_test.exs) plus [`test/mix/tasks/scoria.install_route_smoke_test.exs`](/Users/jon/projects/scoria/test/mix/tasks/scoria.install_route_smoke_test.exs). Those targeted seams passed locally with `SCORIA_DB_PORT=55432 MIX_ENV=test`, which matches the pinned CI/test DB shape already encoded in [`.github/workflows/ci.yml`](/Users/jon/projects/scoria/.github/workflows/ci.yml). [VERIFIED: targeted mix test, repo grep]

The phase should harden those seams, not replace them. Official ExUnit docs support `doctest/1` for module docs and `doctest_file/2` for markdown examples, but also explicitly warn that doctests are a poor fit for side-effectful or sandbox-sensitive examples. Official LiveView docs recommend testing routable LiveViews with `live/2`, `element/3`, `render_*`, and `render/1` instead of browser automation. Those two constraints line up exactly with the phase context: pure README/public API snippets can become executable, while the Phoenix controller/session/operator flow should stay in integration tests. [CITED: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]

**Primary recommendation:** Implement Phase 18 as a three-part hardening pass over the existing repo seams: narrow doctests for pure public examples, shared checked fragments/helpers for the Phoenix guide, and one named `mix test.adoption` lane that runs the same ExUnit files already included in the default suite. [VERIFIED: repo grep] [CITED: https://hexdocs.pm/mix/Mix.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| README/public API snippet guard | Library compile/test tier | Docs surface | Pure `Scoria` and `Scoria.Identity` examples are stable compile-time/test-time contracts, not browser behavior. [VERIFIED: repo grep] [CITED: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html] |
| Phoenix example flow guard | API/backend runtime | Docs surface | The contract is durable run/session behavior through `Scoria.start_run/2`, `resume_run/2`, and `get_run/1`, which the repo already proves through runtime integration tests. [VERIFIED: repo grep, targeted mix test] |
| Operator verification harness | Phoenix server/LiveView tier | API/backend runtime | `/scoria/workflows/:run_id` is a server-rendered operator surface backed by durable runtime state, so Phoenix-native route and LiveView tests are the correct proof layer. [VERIFIED: repo grep, targeted mix test] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] [CITED: https://hexdocs.pm/phoenix/1.7.10/Phoenix.Router.html] |

## Current State

- The README, Phoenix example, and operator verification guide are already guarded semantically by string assertions in [`test/scoria/adoption_surface_test.exs`](/Users/jon/projects/scoria/test/scoria/adoption_surface_test.exs). [VERIFIED: repo grep]
- The runtime integration suite already proves the critical adoption semantics: same-session fresh runs, exact-`run_id` resume, and `/scoria/workflows/:run_id` alignment with durable runtime state. [VERIFIED: repo grep, targeted mix test]
- The installer tests already prove router injection, tailwind injection, baseline runtime config insertion, and mounted `/scoria` route resolution through `Phoenix.Router.route_info/4`. [VERIFIED: repo grep, targeted mix test] [CITED: https://hexdocs.pm/phoenix/1.7.10/Phoenix.Router.html]
- CI already runs an adoption-focused subset before the full suite: runtime integration, adoption surface, installer, route smoke, and migration-lane compatibility. [VERIFIED: repo grep]
- The current repo has no dedicated adoption alias/task yet in `mix.exs`; the focused lane exists only as an explicit CI command today. [VERIFIED: repo grep]
- Local test execution is sensitive to the pinned DB port. Running targeted tests without `SCORIA_DB_PORT=55432` hit a compile-env validation mismatch; running with that env passed. [VERIFIED: targeted mix test]

## Relevant Repo Seams

| Seam | What it already proves | Recommended reuse |
|------|------------------------|-------------------|
| `test/scoria/adoption_surface_test.exs` | Semantic contract presence across README/docs plus moduledoc presence. [VERIFIED: repo grep] | Keep it for curated-surface assertions and tighten it around canonical fragments or doctested snippet locations, not whole-file snapshots. [VERIFIED: phase context] |
| `test/scoria/runtime_integration_test.exs` | Public runtime truth and LiveView operator alignment. [VERIFIED: repo grep, targeted mix test] | Treat it as the behavioral source of truth for `docs/phoenix_runtime_example.md` and `docs/operator_verification.md`. [VERIFIED: phase context] |
| `test/mix/tasks/scoria.install_test.exs` | Installer mutations and idempotence. [VERIFIED: repo grep, targeted mix test] | Keep in both `mix test` and the focused adoption lane. [VERIFIED: repo grep] |
| `test/mix/tasks/scoria.install_route_smoke_test.exs` | Mounted `/scoria` and `/scoria/workflows/:id` route viability. [VERIFIED: repo grep, targeted mix test] | Keep as the fast route-level guard; do not replace with browser E2E. [VERIFIED: phase context] |
| `.github/workflows/ci.yml` | Existing adoption subset command and full-suite ordering. [VERIFIED: repo grep] | Replace the inline subset command with one named Mix alias/task so local and CI invocation stay identical. [VERIFIED: repo grep] [CITED: https://hexdocs.pm/mix/Mix.html] |

## Standard Stack

### Core

| Library | Version in repo | Purpose | Why standard here |
|---------|-----------------|---------|-------------------|
| Elixir / ExUnit | `~> 1.19` in `mix.exs` [VERIFIED: repo grep] | doctests, tags, focused lane plumbing | `ExUnit.DocTest` supports both `doctest/1` and `doctest_file/2`, and tags are first-class for focused filtering. [CITED: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html] [CITED: https://hexdocs.pm/ex_unit/ExUnit.Case.html] |
| Phoenix | `~> 1.7` in `mix.exs` [VERIFIED: repo grep] | router/conn testing | `Phoenix.Router.route_info/4` and `Phoenix.ConnTest` cover route and server response assertions without a browser. [CITED: https://hexdocs.pm/phoenix/1.7.10/Phoenix.Router.html] [CITED: https://hexdocs.pm/phoenix/Phoenix.ConnTest.html] |
| Phoenix LiveView | `~> 1.0` in `mix.exs` [VERIFIED: repo grep] | operator page acceptance | `Phoenix.LiveViewTest` is the idiomatic way to mount and inspect routable LiveViews. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |

### Recommendation

Use the existing stack only; Phase 18 does not need a new fixture app, browser E2E framework, or docs-snapshot dependency. [VERIFIED: repo grep] [VERIFIED: phase context]

## Recommended Approach By Plan

### 18-01: Add README and Public Surface Guardrails

**Recommendation:** Keep [`test/scoria/adoption_surface_test.exs`](/Users/jon/projects/scoria/test/scoria/adoption_surface_test.exs) as the curated-surface guard, but split enforcement into two layers: semantic markdown assertions for README/story structure, plus executable doctests for narrow pure examples in `Scoria` and `Scoria.Identity` moduledocs or small markdown fragments. [VERIFIED: repo grep] [CITED: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html]

**Implementation options**

| Option | Tradeoff | Recommendation |
|--------|----------|----------------|
| Add `doctest Scoria` and `doctest Scoria.Identity` only | Lowest maintenance; keeps examples closest to the public API, but does not directly exercise README code fences. [CITED: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html] | Good baseline. |
| Add `doctest_file "README.md"` for 1-2 stable `iex>` blocks only | Gives README-backed execution, but requires carefully curated pure blocks and can become brittle if overused. [CITED: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html] | Use only for tiny pure snippets, not the whole README. |
| Snapshot the README or assert whole sections verbatim | Highest drift/noise risk; conflicts with curated-doc constraint. [VERIFIED: phase context] | Reject. |

**Decomposition**

1. Add pure doctest-ready examples to `Scoria` and `Scoria.Identity` that cover identity normalization and top-level facade semantics. [VERIFIED: repo grep]
2. Add one doctest case module for those pure examples; optionally add one tiny `README.md` doctest block if the block can stay side-effect free. [CITED: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html]
3. Tighten `adoption_surface_test.exs` to assert semantic anchors plus the presence/location of the executable snippet source, not prose wording. [VERIFIED: phase context]

### 18-02: Add Phoenix Example Verification Lane

**Recommendation:** Keep [`test/scoria/runtime_integration_test.exs`](/Users/jon/projects/scoria/test/scoria/runtime_integration_test.exs) as the truth source and extract stable example builders/fragments from that seam instead of inventing a fixture host app. [VERIFIED: repo grep, targeted mix test]

**Implementation options**

| Option | Tradeoff | Recommendation |
|--------|----------|----------------|
| Extract checked helper functions or literal fragments used by both the docs guard and the integration test | Keeps one behavioral source of truth, but requires a small shared support module or fragment file. [VERIFIED: phase context] | Recommended. |
| Keep docs prose independent and only assert substrings | Lowest effort, but allows semantic drift in code shapes. [VERIFIED: current repo state] | Insufficient for this phase. |
| Build a sample Phoenix app and test it | Strong proof but high maintenance and explicitly out of scope. [VERIFIED: phase context] | Reject. |

**Decomposition**

1. Identify the stable Phoenix-guide fragments: identity map, `start_run`, `get_run`, `resume_run`, and same-session new-run semantics. [VERIFIED: docs + repo grep]
2. Move those fragments into a checked seam that tests can exercise directly: either a support module returning code/data shapes or fragment files that the docs assertions read. [ASSUMED]
3. Update `docs/phoenix_runtime_example.md` to mirror those checked fragments while leaving the surrounding teaching narrative curated. [VERIFIED: phase context]
4. Extend the adoption-surface guard to assert the guide uses the checked fragments/source markers. [ASSUMED]

### 18-03: Add Operator Verification Acceptance Harness

**Recommendation:** Reuse the existing install tests, route smoke test, and runtime LiveView test, then expose that subset behind one named adoption lane such as `mix test.adoption`. Keep those files in the default suite too. [VERIFIED: repo grep, targeted mix test] [CITED: https://hexdocs.pm/mix/Mix.html]

**Implementation options**

| Option | Tradeoff | Recommendation |
|--------|----------|----------------|
| Add a `mix.exs` alias `test.adoption` that runs the current focused file list | Smallest change; mirrors the CI subset and stays discoverable in `mix help`. [CITED: https://hexdocs.pm/mix/Mix.html] | Recommended. |
| Add a custom Mix task wrapper like `mix scoria.test.adoption` | More explicit namespace, but extra code for little gain unless env/bootstrap logic diverges later. [VERIFIED: repo grep] | Acceptable if the team wants symmetry with `mix scoria.test.knowledge`. |
| Hide adoption tests behind `@tag adoption` and exclude by default | Conflicts with the locked default-lane requirement. [VERIFIED: phase context] [CITED: https://hexdocs.pm/ex_unit/ExUnit.Case.html] | Reject. |

**Decomposition**

1. Define the canonical focused lane as the existing CI subset: adoption surface, runtime integration, installer, route smoke, and migration-lane compatibility. [VERIFIED: repo grep]
2. Wire CI to invoke the named lane instead of repeating the long file list inline. [VERIFIED: repo grep]
3. Document the lane in `README.md` or maintainer docs as a fast pre-push lane, while keeping `mix test` as the required default closeout lane. [VERIFIED: phase context]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Pure public-example execution | Custom markdown parser or snapshot engine | `ExUnit.DocTest.doctest/1` and, if needed, `doctest_file/2` | Official, lightweight, and already matches Elixir example syntax. [CITED: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html] |
| Operator UI verification | Browser E2E rig | `Phoenix.LiveViewTest.live/2`, `element/3`, `render/1` | Official LiveView tooling is designed for routable LiveView testing. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |
| Route viability proof | HTTP/browser smoke harness | `Phoenix.Router.route_info/4` plus `Phoenix.ConnTest` | Faster and already used successfully in the repo. [VERIFIED: repo grep, targeted mix test] [CITED: https://hexdocs.pm/phoenix/1.7.10/Phoenix.Router.html] |

## Risks And Anti-Patterns

- **Whole-README executability:** `doctest_file/2` exists, but official docs warn doctests are a poor fit for side-effectful examples and do not run in a sandbox. Using it broadly on Scoria’s README would create false brittleness. [CITED: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html]
- **Fixture-app drift:** A sample Phoenix host app would become a second maintained product boundary and is explicitly outside the phase scope. [VERIFIED: phase context]
- **Copy-assertion-heavy LiveView tests:** The current runtime integration seam already proves stable states like `waiting_for_approval`, `completed`, and durable `run_id`; keep new assertions anchored to those durable facts instead of presentation copy. [VERIFIED: repo grep, targeted mix test]
- **Focused lane divergence from default lane:** The named adoption lane should only be a subset alias/task over normal ExUnit files. Do not move the adoption guard files out of `mix test`. [VERIFIED: phase context] [CITED: https://hexdocs.pm/ex_unit/ExUnit.Case.html]
- **Local env false negatives:** Tests in this repo are sensitive to `SCORIA_DB_PORT=55432`; document that env in the focused lane guidance or ensure the alias/task preserves the expected env assumptions. [VERIFIED: targeted mix test]

## Validation Guidance

### Default Lane

- `SCORIA_DB_PORT=55432 MIX_ENV=test mix test` remains the first-class closeout lane. [VERIFIED: targeted mix test]

### Focused Adoption Lane

- Recommended command shape: `SCORIA_DB_PORT=55432 MIX_ENV=test mix test.adoption` if implemented as an alias, or the equivalent namespaced task if the team prefers a task. [ASSUMED]
- The focused lane should cover the same file set CI already treats as adoption closure: runtime integration, adoption surface, installer, route smoke, and migration-lane compatibility. [VERIFIED: repo grep]

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ADOP-01 | README/public surface stays aligned with shipped API | semantic + doctest | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/adoption_surface_test.exs` | ✅ [VERIFIED: repo grep, targeted mix test] |
| ADOP-02 | Phoenix example semantics match real runtime behavior | integration | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/runtime_integration_test.exs` | ✅ [VERIFIED: repo grep, targeted mix test] |
| ADOP-03 | Default install/operator lane stays knowledge-optional | install + route + integration | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.install_route_smoke_test.exs test/scoria/runtime_integration_test.exs` | ✅ [VERIFIED: repo grep, targeted mix test] |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | ExUnit/doctest lane | ✓ [VERIFIED: local command] | `1.19.5` [VERIFIED: local command] | — |
| Mix | alias/task lane | ✓ [VERIFIED: local command] | `1.19.5` [VERIFIED: local command] | — |
| Postgres on `55432` | runtime integration lane | ✓ [VERIFIED: `pg_isready`] | live service [VERIFIED: `pg_isready`] | none for runtime integration |
| Node/npm | Context7 CLI/doc lookup only | ✓ [VERIFIED: local command] | `v22.14.0` / `11.1.0` [VERIFIED: local command] | web docs |
| Docker | CI parity / local DB bootstrap if needed | ✓ [VERIFIED: local command] | `29.4.1` [VERIFIED: local command] | existing local Postgres |

## Final Recommendation

Plan Phase 18 as three small slices, each anchored to an existing seam: `18-01` adds pure executable guards without over-executing the README, `18-02` derives the Phoenix guide from checked runtime-example fragments/helpers, and `18-03` packages the already-existing adoption subset behind one named Mix lane while preserving `mix test` as the authoritative default. That gives Scoria stronger adoption drift protection without introducing a shadow sample app, browser harness, or snapshot burden. [VERIFIED: repo grep, targeted mix test] [CITED: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]

## Sources

### Primary

- Repo files listed in the prompt, especially `README.md`, `docs/phoenix_runtime_example.md`, `docs/operator_verification.md`, `test/scoria/adoption_surface_test.exs`, `test/scoria/runtime_integration_test.exs`, `test/mix/tasks/scoria.install_test.exs`, `test/mix/tasks/scoria.install_route_smoke_test.exs`, `.github/workflows/ci.yml`. [VERIFIED: repo grep]
- Targeted local verification:
  - `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.install_route_smoke_test.exs` [VERIFIED: targeted mix test]
  - `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/runtime_integration_test.exs` [VERIFIED: targeted mix test]
- ExUnit doctest docs: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html [CITED: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html]
- ExUnit tags/docs: https://hexdocs.pm/ex_unit/ExUnit.Case.html [CITED: https://hexdocs.pm/ex_unit/ExUnit.Case.html]
- Phoenix LiveView testing docs: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]
- Phoenix router docs: https://hexdocs.pm/phoenix/1.7.10/Phoenix.Router.html [CITED: https://hexdocs.pm/phoenix/1.7.10/Phoenix.Router.html]
- Phoenix conn testing docs: https://hexdocs.pm/phoenix/Phoenix.ConnTest.html [CITED: https://hexdocs.pm/phoenix/Phoenix.ConnTest.html]
- Mix aliases/docs: https://hexdocs.pm/mix/Mix.html [CITED: https://hexdocs.pm/mix/Mix.html]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The best shared-source mechanism for Phoenix-guide fragments will likely be a support module or fragment files rather than a different structure. | 18-02 | Low; the planner can swap the storage shape without changing the behavioral strategy. |
| A2 | The focused lane should be named `mix test.adoption` unless the team prefers a namespaced task for symmetry with `mix scoria.test.knowledge`. | Validation Guidance | Low; naming choice does not affect coverage strategy. |

## Metadata

- Standard stack: HIGH - all recommendations stay on built-in ExUnit plus existing Phoenix/LiveView tooling and were verified against official docs. [VERIFIED: repo grep] [CITED: official docs above]
- Architecture: HIGH - the recommended decomposition maps directly onto existing repo seams and passing targeted tests. [VERIFIED: targeted mix test]
- Pitfalls: HIGH - the key failure modes are either explicit in phase context or directly called out in official doctest/LiveView docs. [VERIFIED: phase context] [CITED: official docs above]

## RESEARCH COMPLETE
