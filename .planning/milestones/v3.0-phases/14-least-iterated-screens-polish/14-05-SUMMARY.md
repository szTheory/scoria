---
phase: 14-least-iterated-screens-polish
plan: "05"
subsystem: ui
tags: [phoenix-liveview, eval-workbench, design-system, tdd]
requires:
  - phase: 12-design-system-component-layer
    provides: Shared table, panel, badge, field, and form_section components
  - phase: 13-orientation-spine-ia
    provides: Eval-to-prompt-release and regressed-run quality-loop links
provides:
  - Eval Workbench list and result surfaces rendered through shared panels, tables, and badges
  - Eval Workbench edit form rendered through shared form_section and field wrappers
  - Invalid rubric JSON rejected with visible field error text
affects: [eval-workbench, prompt-release-quality-loop, ds06-raw-palette]
tech-stack:
  added: []
  patterns:
    - LiveView tests scope prohibited UI terms to the screen subtree, not the shared dashboard shell
    - Invalid JSON form input returns a changeset with field error text before mutation
key-files:
  created:
    - .planning/phases/14-least-iterated-screens-polish/14-05-SUMMARY.md
  modified:
    - lib/scoria_web/live/eval_spec_live/index.ex
    - test/scoria_web/live/eval_spec_live/index_test.exs
key-decisions:
  - "Eval Workbench keeps separate rubric and result panels rather than merging with Prompt Registry or adding experiment controls."
  - "Malformed rubric JSON is rejected in the LiveView before Eval.update_eval_spec/2 so invalid text cannot create a new eval spec version."
patterns-established:
  - "Use <.table> only for populated Eval Workbench tables; render <.empty_state> directly for no-run/no-rubric copy to avoid inert empty table chrome."
  - "Scope text-prohibition assertions to the target screen subtree because shared navigation may legitimately contain reserved capability names."
requirements-completed: [SCREEN-01]
duration: 12 min
completed: 2026-06-12
---

# Phase 14 Plan 05: Eval Workbench Shared-Component Conversion Summary

**Eval Workbench now uses shared panels, tables, badges, form sections, and fields while preserving backed eval behavior and quality-loop links**

## Performance

- **Duration:** 12 min
- **Started:** 2026-06-12T17:30:00Z
- **Completed:** 2026-06-12T17:41:54Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Converted Eval Workbench rubric and result regions to `<.panel>`, `<.table>`, and text-labeled `<.badge>` components.
- Added the exact empty eval-run copy: `No eval runs yet` plus the UI-SPEC body.
- Preserved `Open prompt release`, `Open regressed runs`, and encoded `from=eval:<eval-run-id>` links.
- Converted the edit form to `<.form_section>` and `<.field>` wrappers.
- Fixed malformed rubric JSON so it renders a visible `is invalid` field error instead of saving a new version.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Eval Workbench shared-surface tests** - `a08c75f` (test)
2. **Task 1 GREEN: Eval Workbench list/results conversion** - `957c382` (feat)
3. **Task 2 RED: Eval Workbench shared form tests** - `ce8b792` (test)
4. **Task 2 GREEN: Eval Workbench edit form conversion** - `6d106eb` (feat)

## Files Created/Modified

- `lib/scoria_web/live/eval_spec_live/index.ex` - Shared-component Eval Workbench panels, tables, badges, form fields, and invalid rubric validation.
- `test/scoria_web/live/eval_spec_live/index_test.exs` - Empty-state, shared-component, quality-loop link, edit/cancel/save, and invalid-rubric coverage.
- `.planning/phases/14-least-iterated-screens-polish/14-05-SUMMARY.md` - Plan close-out artifact.

## Decisions Made

- Kept the Eval Workbench as one focused Improve surface with rubric and result panels, matching D-13 and D-14.
- Rejected malformed rubric JSON before mutation because the existing Ecto path accepted the string and created a new version.
- Scoped prohibited-copy assertions to `.eval-spec-index`; the shared nav can legitimately include reserved names such as Replay Playground.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fresh worktree dependencies were not fetched**
- **Found during:** Task 1 RED verification
- **Issue:** `mix test` could not run because locked dependencies were unavailable in this worktree.
- **Fix:** Ran `mix deps.get` against the existing lockfile. No package names or dependency versions were changed.
- **Files modified:** None tracked.
- **Verification:** Focused test command ran after dependencies were fetched.
- **Committed in:** Not applicable, no tracked changes.

**2. [Rule 1 - Bug] Prohibited-copy assertion matched shared navigation instead of Eval Workbench content**
- **Found during:** Task 1 GREEN verification
- **Issue:** The test searched the full rendered layout and matched the existing shared nav's reserved `Replay Playground` entry.
- **Fix:** Added `eval_workbench_html/1` helper and scoped prohibited-copy assertions to `.eval-spec-index`.
- **Files modified:** `test/scoria_web/live/eval_spec_live/index_test.exs`
- **Verification:** `mix test test/scoria_web/live/eval_spec_live/index_test.exs test/scoria_web/ds06_drift_guard_test.exs` passed.
- **Committed in:** `957c382`

**3. [Rule 2 - Missing Critical] Invalid rubric JSON created a new eval spec version**
- **Found during:** Task 2 RED verification
- **Issue:** Malformed rubric JSON fell through to `Eval.update_eval_spec/2` and saved instead of displaying validation feedback.
- **Fix:** Added `parse_eval_spec_params/2` to return a changeset error on invalid JSON before mutation.
- **Files modified:** `lib/scoria_web/live/eval_spec_live/index.ex`
- **Verification:** Invalid JSON test renders `scoria-field__error` and `is invalid`; focused tests pass.
- **Committed in:** `6d106eb`

---

**Total deviations:** 3 auto-fixed (1 blocking, 1 bug, 1 missing critical).
**Impact on plan:** All fixes were necessary for correct verification, test precision, or the plan's tampering mitigation. No product scope was added.

## Issues Encountered

- The first patch attempt targeted the main checkout because the patch tool has no working-directory parameter. The accidental main-checkout edit was removed immediately; the worktree changes were reapplied using absolute paths verified under the assigned worktree root.

## User Setup Required

None - no external service configuration required.

## TDD Gate Compliance

- RED commits present: `a08c75f`, `ce8b792`
- GREEN commits present after RED: `957c382`, `6d106eb`
- Refactor commit: not needed
- Status: passed

## Known Stubs

None - no placeholder/TODO/raw evidence stubs were introduced in the touched files.

## Verification

- RED Task 1: `mix test test/scoria_web/live/eval_spec_live/index_test.exs --max-failures 1` failed on missing shared `scoria-table` markup.
- RED Task 2: `mix test test/scoria_web/live/eval_spec_live/index_test.exs --max-failures 1` failed on missing visible invalid-rubric error.
- Final plan verification: `mix test test/scoria_web/live/eval_spec_live/index_test.exs test/scoria_web/ds06_drift_guard_test.exs` - 8 tests, 0 failures.
- Source acceptance: `lib/scoria_web/live/eval_spec_live/index.ex` contains `<.table>`, `<.panel>`, `<.badge>`, `<.form_section>`, and `<.field>`.
- DS-06: passed; Eval Workbench remains at zero raw-palette baseline.

## Self-Check: PASSED

- `lib/scoria_web/live/eval_spec_live/index.ex` exists and contains shared table/panel/badge/form components.
- `test/scoria_web/live/eval_spec_live/index_test.exs` exists and covers empty eval runs, quality-loop hrefs, edit/cancel/save, and invalid rubric errors.
- Commits `a08c75f`, `957c382`, `ce8b792`, and `6d106eb` exist in git log.
- No tracked file deletions were introduced.
- Manual worktree mode honored: `.planning/STATE.md` and `.planning/ROADMAP.md` were not updated.

## Next Phase Readiness

Eval Workbench is ready for Phase 14 follow-on Prompt Registry / Release Workbench conversion in plan 14-06.

---
*Phase: 14-least-iterated-screens-polish*
*Completed: 2026-06-12*
