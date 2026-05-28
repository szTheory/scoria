# Phase 54: Executable proof and closeout truth - Research

**Researched:** 2026-05-27  
**Status:** Ready for planning  
**Scope anchor:** `DOCS-02`, `PROOF-01`, `PROOF-02`

## What You Need To Know To Plan This Phase Well

Phase 54 is a command-contract phase plus proof-lane implementation phase. The repo already has the architecture you need (named Mix lanes, docs drift tests, source-fragment pinning, closeout ledger style). The planning risk is not missing primitives; it is accidentally creating command ambiguity or leaking optional-lane prerequisites into the runtime-to-handoff proof lane.

The planning center of gravity is:

1. add one canonical runtime-to-handoff proof lane command (`mix test.runtime_to_handoff`) with a namespaced implementation task (`mix scoria.test.runtime_to_handoff`),  
2. align all adopter-facing support surfaces to that exact command string, and  
3. update closeout truth to include the new lane while preserving default-lane-first adoption.

## Requirement-Centered Implementation Guidance

### `PROOF-01` - bounded executable proof lane

Implement a new lane using the same pattern already used by adoption and semantic lanes:

- task pattern reference: `lib/mix/tasks/test.adoption.ex`, `lib/mix/tasks/scoria.test.semantic_fast_path.ex`
- discoverability tests pattern: `test/mix/tasks/test.adoption_test.exs`, `test/mix/tasks/test.semantic_fast_path_test.exs`
- env registration pattern: `mix.exs` `cli.preferred_envs`

Concrete guidance:

- Add `lib/mix/tasks/scoria.test.runtime_to_handoff.ex` with:
  - `Mix.Tasks.Scoria.Test.RuntimeToHandoff` as canonical lane task
  - explicit bounded file list (not broad `mix test`)
  - `Mix.Task.run("loadpaths")`, `Mix.Task.reenable("test")`, then `Mix.Task.run("test", args ++ files)`
- Add `lib/mix/tasks/test.runtime_to_handoff.ex` compatibility wrapper:
  - `Mix.Tasks.Test.RuntimeToHandoff`
  - delegates directly to namespaced task
- Update `mix.exs` `preferred_envs` with:
  - `"scoria.test.runtime_to_handoff": :test`
  - `"test.runtime_to_handoff": :test`

Recommended initial bounded file set for lane stability and intent:

- `test/scoria/runtime_test.exs` (runtime-to-handoff behavior + projected-context safety)
- `test/scoria/runtime_integration_test.exs` (public-runtime lifecycle + operator route evidence)
- `test/scoria/adoption_surface_test.exs` (docs/support command truth and lane boundaries)
- `test/scoria/phoenix_example_source_test.exs` and `test/scoria/handoff_example_source_test.exs` (docs/source alignment)
- `test/mix/tasks/test.runtime_to_handoff_test.exs` (new lane discoverability contract)

Keep this bounded and purpose-built; do not fold into `mix test.adoption` (Phase 54 decision boundary in `54-CONTEXT.md`).

### `PROOF-02` - prove optional lanes are not hidden prerequisites

This requirement is best handled as **negative contract proof**, not narrative claims.

Existing repo patterns to reuse:

- optional knowledge toggling via `SCORIA_TEST_INCLUDE_KNOWLEDGE` in `test/test_helper.exs`
- knowledge-lane isolation in `lib/mix/tasks/scoria.test.knowledge.ex`
- migration-lane compatibility assertions in `test/scoria/bootstrap/migration_lane_compatibility_test.exs`
- projected-context rejection tests already proving bounded safety in `test/scoria/runtime_test.exs`

Concrete guidance:

- Keep runtime-to-handoff lane free of:
  - `Mix.Tasks.Scoria.Pgvector.Bootstrap`
  - `Migrations.migrate_knowledge!/0`
  - semantic-lane specific setup
- Add explicit tests/assertions that canonical runtime-to-handoff lane does not require:
  - semantic fast-path lane setup
  - knowledge lane setup (pgvector/tables/bootstrap)
  - hosted onboarding/generator flow as a prerequisite
- Update docs assertions to include explicit “you do not need ...” language for this new lane command (same style as current default-lane truth in README/operator guide)

### `DOCS-02` - support surfaces name one canonical runtime-to-handoff verification command

You already have robust drift infrastructure:

- broad docs invariants: `test/scoria/adoption_surface_test.exs`
- source-fragment pinning: `test/support/scoria/adoption_example.ex`
- source tests: `test/scoria/phoenix_example_source_test.exs`, `test/scoria/handoff_example_source_test.exs`

Concrete guidance:

- Update all required surfaces to use the same literal command string:
  - `README.md`
  - `docs/operator_verification.md`
  - `docs/adoption_lanes.md`
  - `docs/phoenix_runtime_example.md`
  - `docs/bounded_handoffs.md`
- Replace Phase 53 placeholder refutes with Phase 54 truth:
  - current refutes in `test/scoria/adoption_surface_test.exs` block runtime-to-handoff command mentions
  - convert to assert canonical string + refute non-canonical synonyms (e.g., `mix test.handoff`, `mix scoria.test.handoff`)
- Extend shared fragment helper (`test/support/scoria/adoption_example.ex`) with command-fragment literals so docs tests stay centralized

## Existing Patterns You Should Reuse (Do Not Reinvent)

### 1) Named lane task pattern

- Canonical task + wrapper pattern is established by:
  - `Mix.Tasks.Scoria.Test.Adoption` + `Mix.Tasks.Test.Adoption`
  - `Mix.Tasks.Scoria.Test.Knowledge` + `Mix.Tasks.Test.Knowledge`
  - `Mix.Tasks.Scoria.Test.SemanticFastPath` + `Mix.Tasks.Test.SemanticFastPath`

### 2) Drift-test pattern for docs truth

- Use string-level assert/refute style in `test/scoria/adoption_surface_test.exs`  
- Keep lightweight and explicit; avoid snapshot/rendered-doc frameworks

### 3) Source-fragment alignment pattern

- Maintain literal fragments in `test/support/scoria/adoption_example.ex`
- Assert those fragments in docs via existing source tests

### 4) CI lane sequencing pattern

- Current CI (`.github/workflows/ci.yml`) already runs:
  1. `MIX_ENV=dev mix scoria.release_preview`
  2. DB prep
  3. `mix test.adoption`
  4. broad `mix test`
  5. `mix test.knowledge`

Phase 54 should insert runtime-to-handoff proof without collapsing lane boundaries.

## Recommended Plan Split Candidates

These align directly with roadmap success criteria and requirement ownership.

### Candidate A - `54-01-PLAN.md` (PROOF-01 + PROOF-02 core mechanics)

Goal: create the executable runtime-to-handoff lane and prove prerequisite independence.

Suggested deliverables:

- new tasks:
  - `lib/mix/tasks/scoria.test.runtime_to_handoff.ex`
  - `lib/mix/tasks/test.runtime_to_handoff.ex`
- `mix.exs` env registration
- new lane discoverability test:
  - `test/mix/tasks/test.runtime_to_handoff_test.exs`
- bounded lane test list tuned for runtime-to-handoff contract
- first-pass negative prerequisite assertions

Exit criteria:

- `mix test.runtime_to_handoff` passes locally in test env
- lane does not invoke optional-lane setup code
- discoverability tests pass

### Candidate B - `54-02-PLAN.md` (DOCS-02 + command consistency guards)

Goal: align all support surfaces to one canonical runtime-to-handoff proof command.

Suggested deliverables:

- docs updates across required surfaces (`README.md`, `docs/*.md` listed above)
- drift test updates in `test/scoria/adoption_surface_test.exs`:
  - assert canonical runtime-to-handoff command appears where required
  - refute non-canonical synonyms and ambiguous aliases
- shared-fragment updates in `test/support/scoria/adoption_example.ex`
- source test pass confirmation

Exit criteria:

- all docs/tests point to the same canonical command string
- no contradictory lane wording
- default-lane-first contract remains intact (`mix test.adoption` still canonical for default lane)

### Candidate C - `54-03-PLAN.md` (closeout truth + ledger evidence)

Goal: encode and execute milestone closeout truth with auditable evidence.

Suggested deliverables:

- update closeout guidance to chain:
  1. `MIX_ENV=dev mix scoria.release_preview`
  2. `MIX_ENV=test mix test.adoption`
  3. `MIX_ENV=test mix test.runtime_to_handoff`
- CI updates to run the new lane in canonical sequence
- verification ledger artifact (`54-VERIFICATION.md`) with:
  - command outputs
  - any exception protocol fields (blocked command, owner, expiry, compensating checks, rerun plan)

Exit criteria:

- full closeout chain run and recorded
- CI lane updated and green
- no untracked command-contract drift

## Command Contract Guidance (Canonical Runtime-To-Handoff Proof Command)

Use this contract language in planning and implementation:

- canonical adopter-facing command: `mix test.runtime_to_handoff`
- canonical implementation task: `mix scoria.test.runtime_to_handoff`
- support docs should prefer the canonical adopter command string (`mix test.runtime_to_handoff`) unless discussing internals
- avoid aliases/synonyms in support surfaces to prevent support ambiguity

Command contract guardrails:

- one lane = one job:
  - `mix test.adoption` => default-lane adoption proof
  - `mix test.runtime_to_handoff` => bounded runtime-to-handoff proof
  - `mix test.semantic_fast_path` => semantic troubleshooting lane
  - `mix test.knowledge` => optional knowledge lane
- closeout chain includes all required lanes in explicit order
- CI env wrappers (`MIX_ENV=...`) are execution context, not user-facing command synonym replacements

## Risks And Mitigations

1. **Risk:** command drift across docs and tests  
   **Mitigation:** centralize command fragments in `test/support/scoria/adoption_example.ex` + assert/refute matrix in `test/scoria/adoption_surface_test.exs`.

2. **Risk:** accidentally turning runtime-to-handoff into a broad suite alias  
   **Mitigation:** hard-code bounded test file list in new task and cover with discoverability test (same style as `test.adoption_test.exs`).

3. **Risk:** optional knowledge/semantic setup leaks into canonical lane  
   **Mitigation:** prohibit knowledge bootstrap/migrations in task implementation; add negative assertions and run lane with default test-helper exclusion path (`SCORIA_TEST_INCLUDE_KNOWLEDGE` not set).

4. **Risk:** closeout chain inconsistency between docs and CI  
   **Mitigation:** update `docs/operator_verification.md` and `.github/workflows/ci.yml` in same plan wave; enforce with adoption surface assertions.

5. **Risk:** breaking Phase 53 tests that intentionally refuted unshipped runtime-to-handoff command  
   **Mitigation:** treat refute-to-assert migration as first-class work item in `54-02`; do not partially update docs without test contract update.

6. **Risk:** adopter confusion between default lane and runtime-to-handoff lane  
   **Mitigation:** preserve explicit lane hierarchy wording: default lane first, bounded handoff escalation only when needed, runtime-to-handoff lane as dedicated proof for that escalation path.

## Validation Architecture

Nyquist-style strategy: validate each requirement with at least two independent signals (artifact truth + executable truth), and ensure no single failing signal can be masked by narrative docs.

### Validation Principles

- **Dual-channel evidence per requirement:** one code/task/test signal + one docs/support contract signal.
- **Lane-specific verification first, closeout chain second:** avoid waiting until final closeout to discover contract drift.
- **Negative-contract checks are mandatory:** `PROOF-02` must include explicit evidence of non-prerequisites, not just passing happy-path tests.

### Requirement-To-Validation Map

| Requirement | Primary signal | Secondary signal | Gate |
|---|---|---|---|
| `PROOF-01` | `mix test.runtime_to_handoff` task passes bounded test set | task discoverability/contract test under `test/mix/tasks/` | must pass before docs alignment merges |
| `PROOF-02` | runtime-to-handoff lane passes without knowledge/semantic bootstrap | docs/test assertions explicitly state non-prerequisite boundaries | must pass before closeout |
| `DOCS-02` | docs drift tests assert one canonical command across required surfaces | source-fragment tests pin command in example docs | must pass before closeout |

### Suggested Validation Phases (Nyquist cadence)

1. **Wave 1 (task surface):** verify task registration, env mapping, file-list boundaries.
2. **Wave 2 (behavior + negative contracts):** verify runtime-to-handoff lane end-to-end and independence from optional setup.
3. **Wave 3 (support truth):** verify all docs/support surfaces and drift guards align to canonical command.
4. **Wave 4 (closeout truth):** run full milestone chain and record auditable ledger evidence.

This structure should flow directly into a follow-up `54-VALIDATION.md`.

## Verification Commands (Local And CI)

### Local (targeted during implementation)

```bash
MIX_ENV=test mix test test/mix/tasks/test.runtime_to_handoff_test.exs
MIX_ENV=test mix test.runtime_to_handoff
MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/phoenix_example_source_test.exs test/scoria/handoff_example_source_test.exs
```

### Local (phase-level confidence run)

```bash
MIX_ENV=dev mix scoria.release_preview
MIX_ENV=test mix test.adoption
MIX_ENV=test mix test.runtime_to_handoff
```

### CI (recommended canonical proof sequence update)

```bash
MIX_ENV=dev mix scoria.release_preview
mix ecto.create
mix ecto.migrate
mix test.adoption
mix test.runtime_to_handoff
mix test
mix test.knowledge
```

Notes:

- Keep `mix test.runtime_to_handoff` before broad `mix test` so command-contract regressions fail fast.
- Keep `mix test.knowledge` distinct to preserve optional-lane semantics.

## Open Planning Questions To Resolve Early

1. Exact bounded test-file list for runtime-to-handoff lane (minimal stable set vs slightly broader confidence set).
2. Whether to include generated host-app proof tests in runtime-to-handoff lane or keep them only in default adoption lane.
3. Exact wording placement for canonical command in each required doc section to minimize repeated prose while keeping discoverability high.
4. Whether CI should keep both lane-specific checks and broad `mix test` in same job or split jobs for clearer failure semantics.

## Bottom Line

Planning should treat Phase 54 as **contract hardening and proof-lane addition**, not feature invention. Reuse existing lane/task/testing patterns, migrate existing Phase 53 refutes to Phase 54 asserts, and keep one canonical runtime-to-handoff command string visible everywhere with executable evidence backing it.
