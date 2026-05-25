---
phase: 47-release-packaging-and-docs-truth
plan: 03
subsystem: infra
tags: [mix-task, ci, docs, release-preview, testing]
requires:
  - phase: 47-01
    provides: docs build truth and metadata assertions
  - phase: 47-02
    provides: explicit package inventory and required-path contract
provides:
  - canonical `mix scoria.release_preview` verification lane
  - CI gate for publish-surface drift
  - maintainer-facing release-preview documentation
affects: [phase-47, phase-48, ci, operator-docs]
tech-stack:
  added: []
  patterns: [bounded verification mix tasks, CI fail-fast release surface gate]
key-files:
  created: [lib/mix/tasks/scoria.release_preview.ex, test/mix/tasks/scoria.release_preview_test.exs]
  modified: [.github/workflows/ci.yml, docs/operator_verification.md]
key-decisions:
  - "Expose `required_package_paths/0` and `release_preview_output_dir/0` as a stable task contract."
  - "Run the Hex preview via `System.cmd/3` inside the task because `Mix.Task.run(\"hex.build\")` was not available in-task."
patterns-established:
  - "Named maintainer proof lanes should have a fast task-contract test plus one heavier end-to-end command."
requirements-completed: [ADPT-03, ADPT-04]
duration: 4min
completed: 2026-05-25
---

# Phase 47: Release Packaging And Docs Truth Summary

**Canonical release-preview task and CI gate that prove docs build and packaged file inventory together**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-25T16:27:17Z
- **Completed:** 2026-05-25T16:31:33Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments
- Added `mix scoria.release_preview` to run `mix docs` and validate the unpacked Hex preview.
- Added a fast contract test that keeps the release-preview task discoverable and its required-path inventory explicit.
- Wired the release-preview lane into CI before the broad suite and documented it as the canonical maintainer package/docs proof lane.

## Task Commits

No task commits were created in this run. The repository already contained unrelated in-progress changes in overlapping files, so execution stayed uncommitted to avoid bundling unrelated work into forced atomic commits.

## Files Created/Modified
- `lib/mix/tasks/scoria.release_preview.ex` - Implements the bounded release-preview command.
- `test/mix/tasks/scoria.release_preview_test.exs` - Guards task discoverability and its required package inventory contract.
- `.github/workflows/ci.yml` - Runs `mix scoria.release_preview` before the broad test suite.
- `docs/operator_verification.md` - Names the release-preview lane and keeps it distinct from adoption, semantic, and knowledge lanes.

## Decisions Made

- Kept the task contract small and explicit so CI and tests agree on one authoritative required-path list.
- Accepted existing `mix docs` warnings outside this phase scope because they do not block docs generation or the release-preview proof.

## Deviations from Plan

### Auto-fixed Issues

**1. [Execution Integration] Switched Hex preview invocation to `System.cmd/3`**
- **Found during:** Task 2 (`mix scoria.release_preview` implementation)
- **Issue:** `Mix.Task.run("hex.build", ...)` failed because the Hex task was not available from inside the Mix task execution context.
- **Fix:** Invoked `mix hex.build --unpack --output ...` through `System.cmd/3` and raised on non-zero exit.
- **Files modified:** `lib/mix/tasks/scoria.release_preview.ex`
- **Verification:** `mix scoria.release_preview`

---

**Total deviations:** 1 auto-fixed
**Impact on plan:** No scope creep. The task still proves the exact release-preview behavior the plan required.

## Issues Encountered

- The first full-suite pass had one transient failure; `mix test --failed` passed and the second full-suite pass finished green (`386 tests, 0 failures`).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 48 can now assume package metadata, docs buildability, release-preview CI coverage, and package inventory proof are already boring and green.

---
*Phase: 47-release-packaging-and-docs-truth*
*Completed: 2026-05-25*
