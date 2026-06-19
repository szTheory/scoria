---
phase: 35-maintenance-release-0-1-2-publish-post-publish-smoke
plan: 02
subsystem: release
tags: [hex, release-please, ci, docs]

requires:
  - phase: 35-01
    provides: README and registry-lineage contract fixes were on main before release refresh.
provides:
  - Local release preflight passed with docs, release preview, focused release tests, and stale-port guard.
  - Release Please PR #3 was refreshed from main and kept a release-file-only diff.
  - PR #3 merged only after latest-head `CI / ci-gate` success.
  - Phase 34 post-publish smoke port guard was re-verified before merge.
affects: [release, ci, docs, post-publish-smoke]

tech-stack:
  added: []
  patterns:
    - Latest-SHA remote CI evidence is the merge authority for release PRs.
    - Release PR refresh remains Release Please-owned; no hand edits to the release branch.

key-files:
  created:
    - .planning/phases/35-maintenance-release-0-1-2-publish-post-publish-smoke/35-02-SUMMARY.md
  modified:
    - CHANGELOG.md
    - dev/dev_endpoint.ex
    - dev/mix_tasks/scoria_dev_db.ex
    - docs/MAINTAINERS.md
    - docs/support_copilot_gallery.md
    - lib/mix/tasks/scoria.ui.shots.ex
    - lib/scoria/knowledge/source.ex
    - .dockerignore
    - .env.example
    - Makefile
    - compose.yml
    - config/dev.exs
    - config/test.exs
    - dev/pgvector-compose.yml
    - docker/dev-entrypoint.sh
    - .github/workflows/ci.yml
    - lib/scoria/support_journey.ex
    - test/scoria/ci_policy_contract_test.exs

key-decisions:
  - "Docs warnings, release CI policy surfaces, and release-branch e2e mismatches were fixed on main before refreshing PR #3."
  - "PR #3 merge authority was latest release PR head d0eecbb66c19f85d25a77cbae9ce2fd91ca50f11 with `ci-gate` success."

patterns-established:
  - "Release preflight failures are fixed on main, then Release Please refreshes the PR; the release branch stays generated."

requirements-completed: [REL-01, REL-03]

duration: 30 min
completed: 2026-06-19
status: complete
---

# Phase 35 Plan 02: Release Preflight and PR Merge Summary

**The 0.1.2 Release Please PR was refreshed, proved release-file-only, and merged after latest-SHA CI passed.**

## Performance

- **Started:** 2026-06-19T14:24:00Z
- **Completed:** 2026-06-19T14:53:30Z
- **Tasks:** 3 completed
- **Files modified:** 18 source/config/docs files plus the generated release PR files

## Accomplishments

- Cleared the local docs warnings-as-errors gate by removing hidden module/function autolinks from release-facing docs/comments and adding the missing `Scoria.Knowledge.Source.t/0` type.
- Included the Docker DX policy surfaces that release CI expected, so the Phase 34 stale-port and policy guards ran against the committed files.
- Fixed the release-branch e2e gate by aligning the CI e2e base URL with the Phoenix port it boots, and updated the support journey docs contract string.
- Refreshed PR #3 through Release Please run `27832260523`: `https://github.com/szTheory/scoria/actions/runs/27832260523`.
- Verified PR #3 file list stayed exactly `.release-please-manifest.json`, `CHANGELOG.md`, and `mix.exs`.
- Merged PR #3 through release-pr-automerge run `27832822239`: `https://github.com/szTheory/scoria/actions/runs/27832822239`.
- Release PR merge commit: `26eb9a5e686fe4957196dfa5c6654121bda65c03`.

## Task Commits

1. `532cc4c` - `fix(35-02): clear release docs warning gate`
2. `1b74283` - `fix(35-02): include Docker DX policy surfaces for release CI`
3. `4099118` - `fix(35-02): align release branch e2e gate`
4. `26eb9a5` - `chore(main): release 0.1.2 (#3)` from PR #3

## Remote Evidence

- PR #3: `https://github.com/szTheory/scoria/pull/3`
- Latest release PR head before merge: `d0eecbb66c19f85d25a77cbae9ce2fd91ca50f11`
- Latest PR CI run: `https://github.com/szTheory/scoria/actions/runs/27832387789`
- Latest PR `ci-gate` details URL: `https://github.com/szTheory/scoria/actions/runs/27832387789/job/82373525431`
- Release PR Auto-Merge run: `https://github.com/szTheory/scoria/actions/runs/27832822239`
- PR merged at `2026-06-19T14:53:24Z`.

## Verification

- `MIX_ENV=dev mix docs --warnings-as-errors` - passed after docs warning fix.
- `MIX_ENV=dev mix scoria.release_preview` - passed.
- Focused release test set including package surface, Hex consumer contract, CI policy contract, release preview, and support journey source tests - 80 tests, 0 failures.
- `SCORIA_LANE_CONTRACT_ONLY=true MIX_ENV=test mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/docker_dx_doc_contract_test.exs test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs` - 83 tests, 0 failures.
- `rg -n "55432" .github/workflows/post-publish-smoke.yml` - no matches.
- `gh pr view 3 --json files --jq '[.files[].path] | sort == [".release-please-manifest.json","CHANGELOG.md","mix.exs"]'` - true.
- GitHub `CI / ci-gate` on PR head `d0eecbb...` - success.

## Deviations from Plan

- Local docs preflight failed initially on ExDoc warning strictness; fixed on main and reran clean.
- Release CI exposed missing Docker DX policy-surface commits from the working tree; committed the required surfaces rather than changing CI.
- Release CI exposed an e2e base URL mismatch; fixed CI to test the same port it boots and added a policy contract.

**Total deviations:** 3 auto-fixed.
**Impact on plan:** Release branch still stayed generated-only and merge still happened after latest-SHA CI success.

## Issues Encountered

No release PR merge blockers remained after the three fixes above.

## User Setup Required

None.

## Next Phase Readiness

Ready for Plan 35-03: observe the publish path, verify Hex visibility, classify any publish/smoke recovery, and prove post-publish registry smoke for `0.1.2`.

## Self-Check: PASSED

- PR #3 merged with release-file-only diff.
- Latest release PR `ci-gate` was green before merge.
- Phase 34 stale-port guard had zero `55432` hits.

---
*Phase: 35-maintenance-release-0-1-2-publish-post-publish-smoke*
*Completed: 2026-06-19*
