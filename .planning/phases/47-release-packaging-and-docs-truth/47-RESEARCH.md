# Phase 47: Release packaging and docs truth - Research

**Researched:** 2026-05-25
**Domain:** Hex package surface, ExDoc-backed publish docs, and bounded release-preview verification for Scoria. [VERIFIED: mix.exs] [VERIFIED: README.md] [VERIFIED: .github/workflows/ci.yml]
**Confidence:** HIGH

<user_constraints>
## User Constraints

### Locked From Roadmap And Requirements
- **D-01:** Phase 47 must make `mix docs` a real local proof command, not aspirational metadata. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md]
- **D-02:** Publish-facing docs configuration must match the public package story Scoria is actually shipping: README plus the lane and verification guides already referenced in the repo. [VERIFIED: mix.exs] [VERIFIED: README.md]
- **D-03:** Maintainers need a local package preview that proves required runtime code, migrations, README, and adoption guides are included before first Hex publish. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: mix hex.build --unpack --output /tmp/scoria-hex-preview]
- **D-04:** Release preview should stay bounded and fail fast on docs-build drift or package-inventory drift, instead of relying on the broad suite or maintainer memory. [VERIFIED: .planning/ROADMAP.md]

### No Phase Context Present
- **D-05:** No `47-CONTEXT.md` exists, so this phase is planned from roadmap, requirements, and codebase evidence only. Preserve the roadmap’s three-plan shape and avoid inventing product-surface work beyond release packaging, docs truth, and bounded verification. [VERIFIED: gsd-sdk query init.plan-phase 47]

### the Agent's Discretion
- Exact test module names for package/docs verification.
- Exact helper function names for release-preview inventory checks.
- Exact placement of maintainer-facing release-preview documentation, as long as the command is discoverable from repo state.

### Deferred Ideas (OUT OF SCOPE)
- First public Hex publish itself.
- Splitting Scoria into multiple packages.
- Rewriting adopter-facing guides beyond the minimum needed to keep docs extras and release-preview truth aligned.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADPT-03 | Maintainer can build Scoria's publish-facing docs locally through `mix docs`, with Hex metadata, source links, and docs extras aligned to the real public package surface. [VERIFIED: .planning/REQUIREMENTS.md] | Add the real docs dependency, harden `docs/0` metadata in `mix.exs`, and add a bounded test that locks the docs extras and source-link story to the shipped README/docs set. [VERIFIED: mix.exs] [VERIFIED: README.md] |
| ADPT-04 | Maintainer can preview the package artifact before first Hex publish and confirm the shipped file inventory includes required runtime code, migrations, README, and adoption guides. [VERIFIED: .planning/REQUIREMENTS.md] | Declare explicit `package[:files]`, then prove it with an unpacked local Hex build plus a dedicated release-preview task that checks required paths. [VERIFIED: mix help hex.build] [VERIFIED: mix hex.build --unpack --output /tmp/scoria-hex-preview] |
</phase_requirements>

## Summary

Scoria already advertises publish-facing metadata in `mix.exs` through `docs: docs()`, `package: package()`, `source_url`, and `homepage_url`, but the local docs-build proof is still broken because the repo does not include a dependency that provides the `mix docs` task. Running `mix docs` currently exits with `The task "docs" could not be found`. [VERIFIED: mix.exs] [VERIFIED: SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres mix docs]

The package preview gap is also concrete, not hypothetical. `mix hex.build --unpack` succeeds today, but the unpacked artifact only contains the default package surface: `lib/`, `priv/`, `mix.exs`, `README.md`, and `LICENSE`. None of the maintainer guides under `docs/` are present, even though `mix.exs` claims them as docs extras and README points adopters at those guides. [VERIFIED: mix.exs] [VERIFIED: README.md] [VERIFIED: find /tmp/scoria-hex-preview -maxdepth 3 -type f]

CI currently proves adoption, full suite, and knowledge lanes, but nothing runs `mix docs` or a package preview guard. That means publish-surface regressions can merge even if runtime tests stay green. [VERIFIED: .github/workflows/ci.yml]

**Primary recommendation:** sequence the phase in three steps: first make ExDoc and docs metadata truthful, second make package inventory explicit and executable, then add one bounded `mix scoria.release_preview` lane and wire it into CI so publish truth fails fast. [INFERENCE from verified codebase state]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Docs-build availability | Mix project config | Maintainer docs/tests | `mix docs` exists only if the project carries the right dependency and docs config. [VERIFIED: mix.exs] |
| Docs/source/package truth | Mix project config | Source-assertion tests | `docs/0`, `package/0`, `source_url`, and `homepage_url` are all declared in `mix.exs`. [VERIFIED: mix.exs] |
| Package inventory proof | Mix/Hex build task | ExUnit inventory test | `mix hex.build --unpack` already gives a deterministic local artifact to inspect. [VERIFIED: mix help hex.build] |
| Release-preview regression gate | Mix task | CI workflow | The repo already uses named Mix tasks as bounded verification lanes; release preview should follow that pattern. [VERIFIED: lib/mix/tasks/test.adoption.ex] [VERIFIED: lib/mix/tasks/scoria.test.semantic_fast_path.ex] |

## Current Repo Evidence

### Docs Build Drift
- `mix.exs` defines `docs: docs()` and a docs extras list, but `deps/0` does not include `:ex_doc`. [VERIFIED: mix.exs]
- `mix docs` currently fails with `The task "docs" could not be found. Did you mean "do"?` [VERIFIED: SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres mix docs]

### Package Inventory Drift
- `package/0` currently declares only `licenses` and `links`; it does not declare `files`. [VERIFIED: mix.exs]
- The unpacked package preview omits `docs/adoption_lanes.md`, `docs/phoenix_runtime_example.md`, `docs/bounded_handoffs.md`, `docs/semantic_fast_path.md`, and `docs/operator_verification.md`. [VERIFIED: mix hex.build --unpack --output /tmp/scoria-hex-preview] [VERIFIED: find /tmp/scoria-hex-preview -maxdepth 3 -type f]

### Existing Verification Seams
- The repo already favors named bounded lanes implemented as Mix tasks plus dedicated task tests. [VERIFIED: lib/mix/tasks/test.adoption.ex] [VERIFIED: lib/mix/tasks/scoria.test.semantic_fast_path.ex] [VERIFIED: test/mix/tasks/test.adoption_test.exs] [VERIFIED: test/mix/tasks/test.semantic_fast_path_test.exs]
- `test/scoria/adoption_surface_test.exs` already asserts README and guide truth, making it a natural seam for docs/package surface assertions or a sibling source-of-truth test. [VERIFIED: test/scoria/adoption_surface_test.exs]

## Recommended Project Structure

```text
mix.exs
lib/
└── mix/tasks/
    └── scoria.release_preview.ex
test/
├── mix/tasks/
│   └── scoria.release_preview_test.exs
└── scoria/
    └── package_surface_test.exs
docs/
├── adoption_lanes.md
├── phoenix_runtime_example.md
├── bounded_handoffs.md
├── semantic_fast_path.md
└── operator_verification.md
```

This keeps release-preview logic in the same named-task seam the repo already uses, while package/docs truth stays asserted in deterministic source/inventory tests. [INFERENCE from existing task/test patterns]

## Plan Shape Recommendation

### Plan 47-01: Real docs-build dependency and docs metadata truth
- Add `:ex_doc` as the real docs-build dependency.
- Harden `docs/0` with explicit publish-facing metadata such as `source_ref` and a locked extras list.
- Add or extend a source-truth test so docs extras, source URL, homepage URL, and README package messaging stay aligned.

### Plan 47-02: Package inventory truth
- Declare an explicit `package[:files]` list that includes `lib`, `priv`, `README.md`, `LICENSE`, `mix.exs`, `.formatter.exs`, and the maintainer/adoption guides under `docs/`.
- Add an ExUnit package-surface proof that runs `mix hex.build --unpack` into a temp directory and asserts required paths exist in the unpacked artifact.

### Plan 47-03: Bounded release-preview lane
- Add `mix scoria.release_preview` as the single maintainer command that runs `mix docs`, performs a local Hex unpack preview, and fails if required files are absent.
- Add a dedicated task test and a CI step that runs the release-preview lane before or alongside the broad suite.

## Risks And Pitfalls

- If `:ex_doc` is added without `only: :dev` and `runtime: false`, Scoria will widen consumer dependency load unnecessarily. [INFERENCE from standard Mix dependency usage]
- If package inventory relies on Hex defaults, docs guides can silently disappear from the tarball again. Current local evidence already shows that failure mode. [VERIFIED: mix help hex.build] [VERIFIED: find /tmp/scoria-hex-preview -maxdepth 3 -type f]
- If the release-preview lane shells out without asserting specific required paths, the lane will only prove “Hex built something,” not that Scoria shipped the right maintainer surface. [INFERENCE from current artifact preview]

## Verification Commands

```bash
mix docs
mix hex.build --unpack --output /tmp/scoria-hex-preview
find /tmp/scoria-hex-preview -maxdepth 3 -type f | sort
```

## Recommendation

Plan Phase 47 as three sequential plans: docs truth, package inventory truth, then the bounded release-preview lane. That ordering matches the concrete repo failures, minimizes cross-plan ambiguity in `mix.exs`, and gives Phase 48 a publishable package surface to build on.
