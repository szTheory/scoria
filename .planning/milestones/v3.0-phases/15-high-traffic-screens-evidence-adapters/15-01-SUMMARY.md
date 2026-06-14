---
phase: 15-high-traffic-screens-evidence-adapters
plan: "01"
subsystem: ui
tags: [phoenix-liveview, design-system, evidence, css, ds06]

requires:
  - phase: 12-design-system-component-layer
    provides: ScoriaWeb.UI shared component gateway and DS-06 raw-palette ratchet
provides:
  - Shared evidence section, rows, action row, and empty-state primitives
  - Token-bound `.scoria-evidence-*` CSS classes in the component stylesheet
  - Component tests for row ordering, slot rendering, unsafe value escaping, and CSS source invariants
affects:
  - phase-15-evidence-adapters
  - workflow-show
  - connectors
  - approvals

tech-stack:
  added: []
  patterns:
    - Thin evidence adapters project data into ScoriaWeb.UI primitives
    - Evidence row values render through HEEx escaping, not raw HTML

key-files:
  created: []
  modified:
    - lib/scoria_web/ui.ex
    - assets/css/04-components.css
    - test/scoria_web/ui_component_test.exs

key-decisions:
  - "Evidence primitives stay intentionally small: adapters own projection/copy/events, while ScoriaWeb.UI owns repeated evidence chrome."
  - "Evidence row values normalize common tuple/map inputs and render through HEEx so unsafe strings are escaped."

patterns-established:
  - "Evidence sections use `.scoria-evidence-section` with optional badge/action slots for notebook-internal content."
  - "Evidence row lists use `<dl>`/`<dt>`/`<dd>` semantics for compact key-value evidence."
  - "Evidence CSS lives in `assets/css/04-components.css` and uses only existing semantic tokens."

requirements-completed:
  - SCREEN-04

duration: 3 min
completed: 2026-06-12
---

# Phase 15 Plan 01: Evidence Primitive Layer Summary

**Shared evidence primitives for notebook adapters with token-bound section, row, action, and empty-state chrome.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-06-12T22:03:20Z
- **Completed:** 2026-06-12T22:05:41Z
- **Tasks:** 2 completed
- **Files modified:** 3

## Accomplishments

- Added `evidence_section/1`, `evidence_rows/1`, `evidence_action_row/1`, and `evidence_empty/1` to `ScoriaWeb.UI`.
- Added token-bound `.scoria-evidence-*` CSS classes without changing `assets/css/02-tokens.css`.
- Added component tests for section slots, row ordering, unsafe value escaping, action rows, empty copy, and CSS source invariants.

## Task Commits

1. **Task 1 RED: Add shared evidence primitive tests** - `1289133` (test)
2. **Task 1/2 GREEN: Add shared evidence primitives and CSS** - `1f15b7f` (feat)

**Plan metadata:** pending in this summary commit.

## Files Created/Modified

- `lib/scoria_web/ui.ex` - Adds the shared evidence primitive function components and row normalization helpers.
- `assets/css/04-components.css` - Adds token-bound evidence section, rows, action row, and empty-state styles.
- `test/scoria_web/ui_component_test.exs` - Verifies rendered component behavior, escaping, action slot rendering, and CSS source constraints.

## Decisions Made

- Kept the primitive API deliberately narrow instead of adding a descriptor renderer, registry, behaviour, or schema language.
- Used semantic `<dl>` rows for evidence key-value data so later adapters can stay dense and accessible.
- Kept rich action/link content as caller-provided slots; adapters continue to own destination/event semantics.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The RED test initially used plain string slot content for action links, which LiveView correctly escaped. The test helper was adjusted to model real HEEx action slots with safe slot content.

## Verification

- `mix test test/scoria_web/ui_component_test.exs test/scoria_web/ds06_drift_guard_test.exs` - passed, 64 tests, 0 failures.
- Source assertions confirmed all four functions exist in `lib/scoria_web/ui.ex`.
- Source assertions confirmed no `raw(` call or raw palette class appears in `lib/scoria_web/ui.ex`.
- Source assertions confirmed `.scoria-evidence-section`, `.scoria-evidence-rows`, `.scoria-evidence-action-row`, and `.scoria-evidence-empty` exist in `assets/css/04-components.css`.
- `assets/css/02-tokens.css` has no diff.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 15-02 can now convert Home / Live Ops and Runs using shared primitives where evidence or compact scan rows are needed.

## Self-Check: PASSED

- [x] All planned tasks executed.
- [x] Task work committed.
- [x] SUMMARY.md created.
- [x] Focused verification passed.
- [x] No shared token file changed.

---
*Phase: 15-high-traffic-screens-evidence-adapters*
*Completed: 2026-06-12*
