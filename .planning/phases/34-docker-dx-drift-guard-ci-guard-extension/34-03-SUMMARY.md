---
phase: 34-docker-dx-drift-guard-ci-guard-extension
plan: 03
subsystem: ci
tags: [docker-dx, ci-policy, github-actions, exunit, docs-contract]

requires:
  - phase: 34-docker-dx-drift-guard-ci-guard-extension
    provides: Plan 01 Docker DX doc contract and Plan 02 post-publish FLAKE-01 guard
provides:
  - Existing policy lane runs Scoria.DockerDxDocContractTest under --no-start warnings-as-errors
  - Final Phase 34 combined policy-lane verification proof
  - Final static drift proof for post-publish 55432 and stale browser-start 4000 URLs
affects: [phase-35-release, ci-policy-lane, post-publish-smoke]

tech-stack:
  added: []
  patterns:
    - Existing policy-lane explicit file list extended without CI topology changes
    - Final phase guard set uses combined ExUnit policy command plus focused static rg checks

key-files:
  created:
    - .planning/phases/34-docker-dx-drift-guard-ci-guard-extension/34-03-SUMMARY.md
  modified:
    - .github/workflows/ci-verify.yml

key-decisions:
  - "Appended test/scoria/docker_dx_doc_contract_test.exs to the existing policy-lane mix test file list only."
  - "Left CI / ci-gate, ci.yml, workflow topology, job names, services, matrices, needs, and Scoria.VerificationLanes.closeout_order/0 unchanged."

patterns-established:
  - "Policy-lane contract expansion stays a file-list edit when the new contract is file-read-only and safe under mix test --no-start."

requirements-completed: [DOCS-03]

duration: 2 min
completed: 2026-06-18
status: complete
---

# Phase 34 Plan 03: Policy Lane Wiring Summary

**Existing CI policy lane now runs the Docker DX documentation contract with the final Phase 34 drift guards green.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-06-18T20:22:30Z
- **Completed:** 2026-06-18T20:24:50Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Added `test/scoria/docker_dx_doc_contract_test.exs` to the existing `ci-verify.yml` policy-lane `mix test --no-start --warnings-as-errors` file list.
- Preserved the existing policy job, step name, `SCORIA_LANE_CONTRACT_ONLY: "true"`, downstream jobs, `verify-summary`, and `CI / ci-gate` topology.
- Ran the final Phase 34 combined policy-lane command and both focused static drift checks successfully.

## Task Commits

Each task was committed atomically:

1. **Task 1: Append Docker DX doc contract to existing policy lane** - `f08cb14` (test)

## Files Created/Modified

- `.github/workflows/ci-verify.yml` - Existing policy-lane command now includes `test/scoria/docker_dx_doc_contract_test.exs`.
- `.planning/phases/34-docker-dx-drift-guard-ci-guard-extension/34-03-SUMMARY.md` - Plan execution summary.

## Verification

- `SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/docker_dx_doc_contract_test.exs test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs` - PASS, 83 tests / 0 failures.
- `if rg -n "55432" .github/workflows/post-publish-smoke.yml; then exit 1; else exit 0; fi` - PASS, zero matches.
- `if rg -n "localhost:4000|127\\.0\\.0\\.1:4000" docs/docker_dev_dx.md; then exit 1; else exit 0; fi` - PASS, zero matches.
- `git diff --check -- .github/workflows/ci-verify.yml` - PASS.

## Decisions Made

- Followed D-13 exactly: appended the new doc-contract file to the existing policy-lane file list.
- Kept Phase 35 release work out of scope: no `mix docs`, release PR merge, Hex query, publish, or live `mix scoria.post_publish_smoke` was run.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first `state.add-decision` SDK call accepted the full summary file as one decision entry in `STATE.md`. This was corrected before the metadata commit by replacing it with the two concise `key-decisions` bullets from this summary.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 34 is complete. Phase 35 can re-verify the post-publish port fix and proceed with the maintenance release without carrying the old post-publish `55432` blind spot or Docker DX doc-contract CI gap.

## Self-Check: PASSED

- Found `.planning/phases/34-docker-dx-drift-guard-ci-guard-extension/34-03-SUMMARY.md`.
- Found `.github/workflows/ci-verify.yml`.
- Found task commit `f08cb14` in git history.
- Confirmed the summary records the completed DOCS-03 requirement and final Phase 34 verification evidence.

---
*Phase: 34-docker-dx-drift-guard-ci-guard-extension*
*Completed: 2026-06-18*
