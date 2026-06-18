---
phase: 34-docker-dx-drift-guard-ci-guard-extension
plan: 01
subsystem: testing
tags: [docker-dx, docs-contract, exunit, policy-lane]

requires:
  - phase: 33-doc-restructure-verification-copy-correction
    provides: Corrected Docker/native dev-DX documentation truth in docs/docker_dev_dx.md
provides:
  - Scoria.DockerDxDocContractTest file-read-only DOCS-03 contract
  - Positive Docker/native dev loop, secrets, and cache-table token guards
  - Context-aware stale fixed-port browser-start guard for localhost/loopback 4000
affects: [docs/docker_dev_dx.md, ci-policy-lane, phase-34-plan-02, phase-34-plan-03]

tech-stack:
  added: []
  patterns:
    - File-read-only async ExUnit documentation contract
    - Context-aware doc drift classifier with explicit allowed Docker-internal qualifiers

key-files:
  created:
    - test/scoria/docker_dx_doc_contract_test.exs
  modified: []

key-decisions:
  - "Created a dedicated DOCS-03 ExUnit contract that reads only docs/docker_dev_dx.md via File.read!(@doc_path)."
  - "Used a two-layer stale URL guard: direct fixed localhost/loopback 4000 rejection plus context-aware 4000 line classification."

patterns-established:
  - "Reader-facing docs contract: assert load-bearing command, URL, secret, and cache-table fragments without enforcing prose structure."
  - "Qualified 4000 semantics: stale browser-start guidance is rejected while Docker-internal, Traefik, service-target, and ephemeral fallback mechanics remain allowed."

requirements-completed: [DOCS-03]

duration: 3 min
completed: 2026-06-18
status: complete
---

# Phase 34 Plan 01: Docker DX Doc Contract Summary

**File-read-only ExUnit contract for Docker DX documentation tokens and stale fixed-port browser-start drift.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-06-18T20:02:26Z
- **Completed:** 2026-06-18T20:06:16Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Added `Scoria.DockerDxDocContractTest` with `use ExUnit.Case, async: true`.
- Pinned the DOCS-03 reader-facing Docker/native tokens: `make up`, `make dev`, `make nuke`, `ANTHROPIC_API_KEY`, native `4799`, and `direnv`/`1Password`.
- Pinned cache-table strings: `mix deps.get`, `mix deps.compile`, and `app compile only`.
- Added stale browser-start guards that reject fixed `localhost:4000` / `127.0.0.1:4000` guidance while allowing qualified Docker-internal `4000` mechanics.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create positive Docker DX doc-token contract** - `cb6be15` (test)
2. **Task 2: Add context-aware stale browser-start guard** - `d2cca24` (test)

## Files Created/Modified

- `test/scoria/docker_dx_doc_contract_test.exs` - Dedicated DOCS-03 file-read-only docs contract.

## Verification

- `SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/docker_dx_doc_contract_test.exs` - PASS, 6 tests / 0 failures.
- `if rg -n "localhost:4000|127\\.0\\.0\\.1:4000" docs/docker_dev_dx.md; then exit 1; else exit 0; fi` - PASS, zero matches.

## Decisions Made

- Kept the implementation local to the new test file with private helpers only.
- Used line-level context scanning because the current allowed `4000` mechanics are already precise line-level statements.
- Left `test/scoria/ci_policy_contract_test.exs` untouched because Plan 01 ownership is limited to the new doc contract; sibling policy-lane cleanup belongs to later Phase 34 plans.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The pre-creation focused test command failed because `test/scoria/docker_dx_doc_contract_test.exs` did not exist yet. That was the expected baseline for creating the new contract.
- The task-level `tdd="true"` flags produced test-only commits because the only owned implementation artifact was the contract test file and Phase 33 had already supplied the docs truth being guarded.

## TDD Gate Compliance

Plan frontmatter is `type: execute`, not `type: tdd`. Both tasks were contract-test tasks and were committed as `test(34-01)` commits. No production `feat(34-01)` GREEN commit was applicable under the plan's explicit file ownership.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 02 can extend the existing CI policy scanner and post-publish workflow guard without needing additional Docker DX doc-contract work.

## Self-Check: PASSED

- Found `test/scoria/docker_dx_doc_contract_test.exs`.
- Found `.planning/phases/34-docker-dx-drift-guard-ci-guard-extension/34-01-SUMMARY.md`.
- Found task commits `cb6be15` and `d2cca24` in git history.

---
*Phase: 34-docker-dx-drift-guard-ci-guard-extension*
*Completed: 2026-06-18*
