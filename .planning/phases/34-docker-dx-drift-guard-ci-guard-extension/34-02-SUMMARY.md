---
phase: 34-docker-dx-drift-guard-ci-guard-extension
plan: 02
subsystem: testing
tags: [docker-dx, ci-policy, github-actions, exunit, flake-guard]

requires:
  - phase: 34-docker-dx-drift-guard-ci-guard-extension
    provides: Plan 01 dedicated Docker DX documentation contract
provides:
  - Post-publish smoke workflow Postgres bind moved below Linux ephemeral range
  - FLAKE-01 scanner coverage for .github/workflows/post-publish-smoke.yml
  - Narrowed ci_policy_contract_test.exs ownership for Docker DX doc tokens
affects: [phase-34-plan-03, phase-35-release, ci-policy-lane, post-publish-smoke]

tech-stack:
  added: []
  patterns:
    - Existing job_blocks/1 workflow scanner extended with file-prefixed job keys
    - TDD RED/GREEN contract update for policy-lane drift guard

key-files:
  created:
    - .planning/phases/34-docker-dx-drift-guard-ci-guard-extension/34-02-SUMMARY.md
  modified:
    - .github/workflows/post-publish-smoke.yml
    - test/scoria/ci_policy_contract_test.exs

key-decisions:
  - "Kept the post-publish workflow fix to the planned two-line 5432:5432 and SCORIA_DB_PORT: 5432 change."
  - "Extended the existing FLAKE-01 regex scanner instead of adding a YAML parser, allowlist, random-port plumbing, or new CI job."
  - "Moved broad Docker DX doc-token ownership out of ci_policy_contract_test.exs, leaving only the .env.example instance example guard there."

patterns-established:
  - "Policy scanner coverage uses exact file-prefixed keys such as post-publish-smoke.yml:smoke so count-only checks cannot hide missing workflow coverage."
  - "Doc-token ownership stays in Scoria.DockerDxDocContractTest; ci_policy_contract_test.exs stays focused on CI policy and structural Docker DX surfaces."

requirements-completed: [DOCS-03]

duration: 4 min
completed: 2026-06-18
status: complete
---

# Phase 34 Plan 02: Post-Publish FLAKE-01 Guard Summary

**Post-publish smoke now uses the low fixed Postgres host port and the FLAKE-01 policy scanner proves that workflow is covered.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-18T20:11:44Z
- **Completed:** 2026-06-18T20:15:16Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Changed `.github/workflows/post-publish-smoke.yml` from `55432:5432` / `SCORIA_DB_PORT: 55432` to `5432:5432` / `SCORIA_DB_PORT: 5432`.
- Extended the existing FLAKE-01 policy test to read `.github/workflows/post-publish-smoke.yml`, prefix its Postgres job as `post-publish-smoke.yml:smoke`, and assert that exact key exists.
- Raised the scanner breadth guard to `>= 6` jobs across `ci.yml`, `ci-verify.yml`, and `post-publish-smoke.yml`.
- Replaced the old broad Docker DX guide assertion in `ci_policy_contract_test.exs` with a narrow `.env.example` instance example guard, leaving Plan 01's dedicated doc contract as the owner of canonical Docker DX doc tokens.

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix post-publish Postgres host-port bind** - `8675672` (fix)
2. **Task 2 RED: Add failing post-publish scanner contract** - `959eefc` (test)
3. **Task 2 GREEN: Extend FLAKE-01 scanner and narrow old doc ownership** - `5ebaae2` (feat)

## Files Created/Modified

- `.github/workflows/post-publish-smoke.yml` - Post-publish registry attest service bind and `SCORIA_DB_PORT` now use `5432`.
- `test/scoria/ci_policy_contract_test.exs` - Existing FLAKE-01 scanner now covers `post-publish-smoke.yml`; old broad Docker DX doc-token ownership is narrowed to `.env.example`.
- `.planning/phases/34-docker-dx-drift-guard-ci-guard-extension/34-02-SUMMARY.md` - Plan execution summary.

## Verification

- `SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs` - PASS, 56 tests / 0 failures.
- `SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/docker_dx_doc_contract_test.exs test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs` - PASS, 83 tests / 0 failures.
- `if rg -n "55432" .github/workflows/post-publish-smoke.yml; then exit 1; else exit 0; fi` - PASS, zero matches.
- `if rg -n "@docker_dx_docs|Docker DX guide documents the collision-resistant workflow|http://localhost:4000/scoria" test/scoria/ci_policy_contract_test.exs; then exit 1; else exit 0; fi` - PASS, zero matches.

## Decisions Made

- Kept `post-publish-smoke.yml` behavior, workflow shape, triggers, job name, and release wiring unchanged except for the planned port value.
- Reused the current `job_blocks/1` plus fixed host-port regex scanner instead of introducing YAML parsing or package dependencies.
- Used an exact `Map.has_key?(postgres_blocks, "post-publish-smoke.yml:smoke")` assertion so the post-publish workflow cannot disappear behind a count threshold.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The pre-existing dirty `test/scoria/ci_policy_contract_test.exs` already contained Dockerfile, Compose, Makefile, and secrets-structure policy assertions. They matched this plan's required ownership boundary, so they were preserved while applying the scanner and doc-ownership changes.
- Task 2's RED phase intentionally failed with the missing `post-publish-smoke.yml:smoke` assertion before the scanner was wired.

## TDD Gate Compliance

- RED commit present: `959eefc` (`test(34-02): add failing post-publish scanner contract`), with the focused policy test failing for the intended missing post-publish scanner key.
- GREEN commit present after RED: `5ebaae2` (`feat(34-02): extend post-publish port scanner`), with the focused policy test passing.
- No refactor commit was needed.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 03 can wire the dedicated `docker_dx_doc_contract_test.exs` into the existing policy-lane command. Phase 35 can treat the REL-03 post-publish port-fix portion as pre-satisfied and re-verify it with the zero-`55432` static check plus the extended policy test.

## Self-Check: PASSED

- Found `.planning/phases/34-docker-dx-drift-guard-ci-guard-extension/34-02-SUMMARY.md`.
- Found `.github/workflows/post-publish-smoke.yml`.
- Found `test/scoria/ci_policy_contract_test.exs`.
- Found task commits `8675672`, `959eefc`, and `5ebaae2` in git history.

---
*Phase: 34-docker-dx-drift-guard-ci-guard-extension*
*Completed: 2026-06-18*
