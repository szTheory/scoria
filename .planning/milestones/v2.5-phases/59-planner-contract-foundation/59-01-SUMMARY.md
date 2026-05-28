---
phase: 59-planner-contract-foundation
plan: 01
subsystem: installer
tags: [mix-task, installer, dry-run, planner, deterministic]
requires:
  - phase: 58-warning-lane-foundation
    provides: canonical verification lane command constants
provides:
  - deterministic pure planner artifact for installer preview surfaces
  - planner-only dry-run/check routing with validated CLI options
  - no-write dry-run contract tests and stable planner ordering assertions
affects: [59-02-check-exit-semantics, 60-drift-classification-and-safe-apply]
tech-stack:
  added: []
  patterns: [planner-first installer preview contract, pure per-surface analyzers]
key-files:
  created:
    - lib/scoria/install/planner.ex
    - lib/scoria/install/surface/router.ex
    - lib/scoria/install/surface/tailwind.ex
    - lib/scoria/install/surface/migrations.ex
    - lib/scoria/install/surface/runtime_config.ex
    - test/scoria/install/planner_test.exs
  modified:
    - lib/mix/tasks/scoria.install.ex
    - test/mix/tasks/scoria.install_test.exs
key-decisions:
  - "Use one pure planner artifact as the shared dry-run/check source of truth before apply-path rewrites."
  - "Classify every managed surface conservatively and fall back to manual_review when discovery is ambiguous."
patterns-established:
  - "Deterministic planner entries are emitted in explicit surface order with stable ids derived from surface+target."
  - "Dry-run tests snapshot host files before/after execution to prove no-write behavior."
requirements-completed: [INST-03, INST-05]
duration: 5 min
completed: 2026-05-27
---

# Phase 59 Plan 01: Planner Contract Foundation Summary

**`mix scoria.install --dry-run` now uses a deterministic pure planner contract that classifies router, tailwind, migrations, and runtime config without mutating host files.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-27T12:29:00Z
- **Completed:** 2026-05-27T12:34:46Z
- **Tasks:** 2/2
- **Files modified:** 8

## Accomplishments
- Added `Scoria.Install.Planner.build/4` with schema version, mode, deterministic surface ordering, stable entry ids, and classification summary counts.
- Introduced pure per-surface analyzers for router, tailwind, migrations, and runtime config with explicit `create|update|no_op|manual_review` contract outputs.
- Routed `mix scoria.install --dry-run` and `--check` through planner-only rendering with argument validation and human/json output modes.
- Added dry-run contract tests proving no host writes, deterministic output, and per-surface classification/rationale visibility.

## Task Commits

Each task was committed atomically:

1. **Task 1: Task 59-01-01: Build deterministic pure planner artifact and wire dry-run mode** - `9d32a7e` (feat)
2. **Task 2: Task 59-01-02: Add no-write dry-run, deterministic ordering, and rationale contract tests** - `eaa1174` (test)

## Files Created/Modified
- `lib/scoria/install/planner.ex` - canonical planner artifact builder and deterministic ordering/summary logic.
- `lib/scoria/install/surface/router.ex` - pure router classification analyzer using root browser scope probes.
- `lib/scoria/install/surface/tailwind.ex` - pure tailwind analyzer for optional/no-op/update/manual-review outcomes.
- `lib/scoria/install/surface/migrations.ex` - pure migration inventory analyzer producing create/no-op/manual-review classifications.
- `lib/scoria/install/surface/runtime_config.ex` - pure runtime config analyzer with conservative conflict fallback.
- `lib/mix/tasks/scoria.install.ex` - planner routing for `--dry-run`/`--check`, option validation, and planner rendering.
- `test/scoria/install/planner_test.exs` - planner schema contract, deterministic order, and stable id assertions.
- `test/mix/tasks/scoria.install_test.exs` - no-write dry-run and deterministic output contract tests.

## Decisions Made
- Preserve existing apply-path mutators for non-preview installs while moving preview/check to planner-only code paths.
- Keep classification conservative by returning `manual_review` for unresolved paths or unsupported structure anchors.

## Deviations from Plan

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed (none)
**Impact on plan:** None.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Planner contract foundation is complete and test-backed for `INST-03` and `INST-05`.
- Ready for `59-02` to add check exit-code semantics and CI-oriented machine result behavior on top of the same planner artifact.

---
*Phase: 59-planner-contract-foundation*
*Completed: 2026-05-27*
