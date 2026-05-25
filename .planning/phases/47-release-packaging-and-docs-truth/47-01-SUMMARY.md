---
phase: 47-release-packaging-and-docs-truth
plan: 01
subsystem: packaging
tags: [mix, ex_doc, docs, readme, testing]
requires: []
provides:
  - local ExDoc-backed `mix docs` proof
  - source-of-truth package/docs metadata test coverage
affects: [phase-47, phase-48, release-preview]
tech-stack:
  added: [ex_doc]
  patterns: [mix-project metadata assertions, publish-surface source-of-truth tests]
key-files:
  created: [test/scoria/package_surface_test.exs]
  modified: [mix.exs]
key-decisions:
  - "Bound docs metadata to the package version with `source_ref: \"v#{version}\"`."
  - "Assert publish-surface metadata through `Mix.Project.config/0` instead of parsing `mix.exs` text."
patterns-established:
  - "Publish-facing metadata changes should ship with narrow source-of-truth tests."
requirements-completed: [ADPT-03]
duration: 4min
completed: 2026-05-25
---

# Phase 47: Release Packaging And Docs Truth Summary

**ExDoc-backed local docs proof with versioned source links and locked package-surface metadata assertions**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-25T16:27:17Z
- **Completed:** 2026-05-25T16:31:33Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Added the real `:ex_doc` dependency so `mix docs` is executable from repo state.
- Bound docs metadata to the package version and locked source/homepage/docs/package expectations in one test.
- Kept README install wording aligned with the pre-publish tagged GitHub story.

## Task Commits

No task commits were created in this run. The repository already contained unrelated in-progress changes in overlapping files, so execution stayed uncommitted to avoid bundling unrelated work into forced atomic commits.

## Files Created/Modified
- `mix.exs` - Adds ExDoc, version-aware docs metadata, and explicit publish-surface configuration.
- `mix.lock` - Locks the new ExDoc dependency graph.
- `test/scoria/package_surface_test.exs` - Asserts source/homepage/docs/package truth and README package messaging.
- `README.md` - Carries the tagged GitHub install wording used by the new source-of-truth test.

## Decisions Made

Followed the plan. The only execution-specific decision was to keep the existing README package wording and assert it rather than rewriting the install story further.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `mix test` and `mix docs` needed the repo's expected database env (`SCORIA_DB_PORT=55432`, `SCORIA_DB_PASSWORD=postgres`) so compile-time and runtime repo config matched during verification.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 47-02 can build on the same `package_surface_test.exs` seam to verify unpacked Hex artifacts against explicit package inventory.

---
*Phase: 47-release-packaging-and-docs-truth*
*Completed: 2026-05-25*
