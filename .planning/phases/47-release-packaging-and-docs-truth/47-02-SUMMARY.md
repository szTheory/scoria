---
phase: 47-release-packaging-and-docs-truth
plan: 02
subsystem: packaging
tags: [hex, package, mix, artifact, testing]
requires:
  - phase: 47-01
    provides: docs metadata truth and package-surface test seam
provides:
  - explicit Hex package files inventory
  - unpacked-artifact proof for required runtime, migration, and guide files
affects: [phase-47, phase-48, release-preview]
tech-stack:
  added: []
  patterns: [explicit package inventory, unpacked artifact verification]
key-files:
  created: []
  modified: [mix.exs, test/scoria/package_surface_test.exs]
key-decisions:
  - "Keep `package[:files]` narrow and enumerate the five publish-facing docs guides explicitly."
  - "Verify a real `mix hex.build --unpack` artifact instead of inferring package contents from Mix config alone."
patterns-established:
  - "Release-surface changes should prove the unpacked Hex artifact, not just metadata declarations."
requirements-completed: [ADPT-04]
duration: 4min
completed: 2026-05-25
---

# Phase 47: Release Packaging And Docs Truth Summary

**Explicit Hex package inventory with a deterministic unpacked-artifact proof for runtime files, migrations, and adopter guides**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-25T16:27:17Z
- **Completed:** 2026-05-25T16:31:33Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Declared the first-release `package[:files]` list explicitly in `mix.exs`.
- Extended the package-surface test to shell out to `mix hex.build --unpack` and assert required paths by name.
- Verified the local unpack preview at `tmp/scoria-hex-preview` contains the runtime, migration, README, LICENSE, and guide inventory the milestone requires.

## Task Commits

No task commits were created in this run. The repository already contained unrelated in-progress changes in overlapping files, so execution stayed uncommitted to avoid bundling unrelated work into forced atomic commits.

## Files Created/Modified
- `mix.exs` - Adds an explicit release package files list.
- `test/scoria/package_surface_test.exs` - Verifies unpacked Hex artifact contents against the required file inventory.

## Decisions Made

None - followed plan as specified.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The package inventory list and required-path assertions are now reusable by the bounded release-preview task and its contract test.

---
*Phase: 47-release-packaging-and-docs-truth*
*Completed: 2026-05-25*
