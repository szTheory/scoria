---
phase: 28-dx-mix-ci-alias-velocity-closeout
plan: "01"
subsystem: infra
tags: [mix, elixir, ci, dx, verification-lanes, merge-gate]

# Dependency graph
requires:
  - phase: 27-ci-determinism-flake-elimination
    provides: Postgres port fix, no-retry policy, ci_policy_contract_test guards (45 tests green)
  - phase: 23-cache-correctness-build-once-job
    provides: Scoria.VerificationLanes SSOT with closeout_order/0, command/1, exclusions/1
provides:
  - "Mix.Tasks.Scoria.Ci: SSOT-driven run-all-aggregate merge-gate Mix task"
  - "ci: [\"scoria.ci\"] alias in mix.exs (single-element delegating list, not chained)"
  - "docs/MAINTAINERS.md: ### Local merge gate: mix ci section with local-vs-CI asymmetry documentation"
  - "docs/operator_verification.md: mix ci one-liner mention"
  - "README.md: mix ci mention near For maintainers section"
affects: [dx, ci-policy-contract, verification-lanes, maintainer-docs]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Mix.Task with run-all-aggregate exit semantics (collect {label, status} for every step, print summary, System.halt(1) on any failure)"
    - "pgvector preflight probe via System.cmd(sh -c mix scoria.pgvector.bootstrap --check) before lane execution"
    - "OptionParser strict: @switches + invalid guard pattern (from scoria.test.ci_trust.ex)"
    - "Lane set derived from VerificationLanes.closeout_order() ++ explicit ids, filtered by exclusions string"

key-files:
  created:
    - lib/mix/tasks/scoria.ci.ex
  modified:
    - mix.exs
    - docs/MAINTAINERS.md
    - docs/operator_verification.md
    - README.md

key-decisions:
  - "Implement as Mix.Task (not a chained alias list) to avoid elixir-lang/elixir#4318 false-green footgun where only the last sub-command's exit code surfaces"
  - "Run-all-aggregate semantics: collect every step result before printing summary and halting, mirroring CI verify-summary fan-in"
  - "Exclude :support_copilot_gallery via exclusions string filter rather than hardcoding the atom — self-documenting, SSOT-aligned"
  - "Local-vs-CI asymmetry documented explicitly: mix ci is a strict superset (format + deps-lock preamble locally only); CI policy job symmetry deferred"
  - "Place ### Local merge gate: mix ci sub-heading BEFORE ### Flake policy in MAINTAINERS.md so it becomes the section_after split point, keeping its content outside the ci_policy_contract_test gate-map slice"

patterns-established:
  - "Run-all-aggregate pattern: always collect all step results before printing verdict; never fail-fast in a merge-gate mirror task"
  - "Preflight hard-fail with Next step: microcopy block on missing infra (matches pgvector.bootstrap idiom)"
  - "PARTIAL stamp pattern: --skip-optional must unconditionally exit non-zero with RESULT: PARTIAL ... NOT a merge-gate pass"

requirements-completed: [DX-01]

# Metrics
duration: 25min
completed: 2026-06-17
---

# Phase 28 Plan 01: DX mix ci merge-gate task + docs Summary

**SSOT-driven `Mix.Tasks.Scoria.Ci` task that runs the full merge gate locally with run-all-aggregate semantics, pgvector preflight, and actionable PARTIAL opt-out — driven off `Scoria.VerificationLanes` so command strings never drift**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-06-17T00:00:00Z
- **Completed:** 2026-06-17
- **Tasks:** 2 completed
- **Files modified:** 5

## Accomplishments

- Implemented `Mix.Tasks.Scoria.Ci` (`lib/mix/tasks/scoria.ci.ex`) with preamble (deps-lock + format + compile WAE), pgvector preflight, SSOT-derived lane set, run-all-aggregate execution, and `--skip-optional` PARTIAL path
- Added `ci: ["scoria.ci"]` single-element delegating alias to `mix.exs` (avoids elixir-lang/elixir#4318 false-green)
- Documented `mix ci` and the deliberate local-vs-CI asymmetry in a new `### Local merge gate: mix ci` sub-heading in `docs/MAINTAINERS.md` placed outside the `section_after("## CI gate map")` slice; appended one-line mentions to `docs/operator_verification.md` and `README.md`
- All 51 contract guard tests (`verification_lanes_test.exs` + `ci_policy_contract_test.exs`) stay green; module compiles WAE-clean

## Task Commits

1. **Task 1: Implement Mix.Tasks.Scoria.Ci + ci alias** - `f9826b3` (feat)
2. **Task 2: Document mix ci in MAINTAINERS / operator_verification / README** - `687ac6e` (docs)

## Files Created/Modified

- `lib/mix/tasks/scoria.ci.ex` - Mix.Tasks.Scoria.Ci: preamble steps, pgvector preflight, lane set from VerificationLanes SSOT, run-all-aggregate, --skip-optional PARTIAL path, strict OptionParser guard
- `mix.exs` - Added `ci: ["scoria.ci"]` to aliases/0 (single-element delegating list)
- `docs/MAINTAINERS.md` - Added `### Local merge gate: mix ci` sub-heading outside the CI gate map section; documents preamble, lane set, --skip-optional, local-vs-CI asymmetry
- `docs/operator_verification.md` - Appended one-line `mix ci` mention to Maintainers section
- `README.md` - Appended `mix ci` mention paragraph to For maintainers section

## Decisions Made

- **SSOT-only lane derivation:** `VerificationLanes.closeout_order() ++ [:semantic_fast_path, :knowledge, :connector]`, filtered by `"merge-blocking closeout" in exclusions(id)`. Never duplicates command strings — duplication would drift from the byte-order contract tests.
- **System.halt over Mix.raise for final verdict:** ensures aggregation and summary printing complete before exit (matches `scoria.install.ex` pattern).
- **Placement in MAINTAINERS.md:** inserted before `### Flake policy` so it becomes the first `\n### ` split point that `section_after("## CI gate map")` cuts at — keeping all new content outside the sliced section and out of reach of the line-573 refute string.
- **Literal port 55432 in preflight microcopy:** matches `@default_port` in `scoria.pgvector.bootstrap.ex`; no magic number introduced.

## Deviations from Plan

None — plan executed exactly as written. The worktree lacked its own `_build` and `deps`, so verification commands required `MIX_DEPS_PATH` and `MIX_BUILD_PATH` env vars pointing to the main repo's compiled artifacts. This is expected worktree behavior, not a deviation.

## Issues Encountered

Worktree environment discovery: `mix compile` from inside the worktree fails without `_build` and `deps`. Used `MIX_DEPS_PATH=/path/to/main/deps MIX_BUILD_PATH=/path/to/main/_build mix ...` for all verification commands. The worktree's source files (in `lib/`) are what matter for compilation; the build artifacts are shared from the main repo.

## User Setup Required

None — no external service configuration required. `mix ci` requires a running pgvector Postgres on port 55432 for a full gate pass; use `mix ci --skip-optional` when that is unavailable.

## Next Phase Readiness

- DX-01 satisfied: `mix ci` is the single local command that mirrors the merge gate, hard-fails on missing infra, and documents the deliberate asymmetry
- Plan 01 is the only plan in the wave; orchestrator will update STATE.md and ROADMAP.md post-merge

---
*Phase: 28-dx-mix-ci-alias-velocity-closeout*
*Completed: 2026-06-17*

## Self-Check

### Files exist

- `lib/mix/tasks/scoria.ci.ex`: EXISTS
- `mix.exs` (ci alias): EXISTS
- `docs/MAINTAINERS.md` (mix ci section): EXISTS
- `docs/operator_verification.md` (mix ci mention): EXISTS
- `README.md` (mix ci mention): EXISTS

### Commits exist

- `f9826b3`: feat(28-01): implement Mix.Tasks.Scoria.Ci merge-gate task + ci alias — EXISTS
- `687ac6e`: docs(28-01): document mix ci + local-vs-CI asymmetry — EXISTS

## Self-Check: PASSED
