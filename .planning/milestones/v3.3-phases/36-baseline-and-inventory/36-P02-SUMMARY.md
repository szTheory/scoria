---
phase: 36-baseline-and-inventory
plan: P02
subsystem: planning
tags: [inventory, design-system, baseline, risks, source-scan]

requires:
  - phase: 36-baseline-and-inventory
    provides: P01 baseline artifact contract and starter risk register
provides:
  - Complete source-reconciled design-system inventory JSON
  - Maintainer-readable inventory summary and Phase 37+ gate
  - Multi-source coverage audit for BASE-01, INV-01, INV-02, and D-01 through D-28
affects: [phase-37, phase-38, phase-39, phase-40, phase-41, design-system]

tech-stack:
  added: []
  patterns:
    - JSON remains canonical for row IDs, statuses, owner paths, evidence, exclusions, relationships, and risk refs
    - Markdown summarizes inventory counts, risk register, validation commands, and later-phase gate

key-files:
  created:
    - .planning/phases/36-baseline-and-inventory/36-P02-SUMMARY.md
  modified:
    - .planning/phases/36-baseline-and-inventory/36-INVENTORY.md
    - .planning/phases/36-baseline-and-inventory/36-inventory.json

key-decisions:
  - "Source-scan reconciliation is encoded directly in 36-inventory.json rows and documented_exclusions."
  - "Generated/vendor/report-heavy inputs are excluded only with explicit source, reason, and reviewed_by_phase fields."
  - "Phase 37+ is gated on both inventory artifacts parsing and containing required risk IDs plus complete layer/status coverage."

patterns-established:
  - "Grouped fixture/proof evidence rows can cover many repository-relative inputs while preserving exact source-scan matches."
  - "One-off keyword hits that are safe documentation prose are tracked as documented exclusions instead of false design-system risks."

requirements-completed: [INV-01, INV-02]

duration: 9min
completed: 2026-06-20
status: complete
---

# Phase 36 Plan P02: Baseline And Inventory Summary

**Source-reconciled design-system inventory with 86 canonical JSON rows, 236 documented exclusions, required risks, and a Phase 37+ implementation gate.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-06-20T16:20:40Z
- **Completed:** 2026-06-20T16:29:53Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Expanded `36-inventory.json` from starter rows into a complete source-reconciled index across all required layers and statuses.
- Finalized `36-INVENTORY.md` with Baseline Truth, Known Risk Register, Phase 37+ Gate, Validation, and Multi-Source Coverage Audit sections.
- Verified no runtime/source files were modified.

## Task Commits

Each task was committed atomically:

1. **Task 1: Complete Inventory Rows Across Required Layers** - `968bd3e` (docs)
2. **Task 2: Finalize Markdown Inventory And Phase Gate** - `5533573` (docs)

**Plan metadata:** pending final docs commit

## Files Created/Modified

- `.planning/phases/36-baseline-and-inventory/36-inventory.json` - Canonical inventory with 86 rows, 5 risks, complete layer/status coverage, source evidence, and documented exclusions.
- `.planning/phases/36-baseline-and-inventory/36-INVENTORY.md` - Maintainer-readable companion with gate, validation, risk summary, and coverage audit.
- `.planning/phases/36-baseline-and-inventory/36-P02-SUMMARY.md` - This execution summary.

## Decisions Made

- Kept source reconciliation in JSON rather than adding runtime scan code or tests.
- Used grouped evidence rows for broad fixture/proof surfaces so exact paths remain machine-checkable without creating noisy per-file prose.
- Classified generated/vendor/report-heavy paths through `documented_exclusions` only when they were not current Scoria design-system owners.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Folded multi-clause UI functions into stable primitive rows**
- **Found during:** Task 1
- **Issue:** `ScoriaWeb.UI.tone/1` and `status_label/1` have multiple function heads; naive source extraction produced duplicate row IDs.
- **Fix:** Deduplicated exported function names before writing primitive rows.
- **Files modified:** `.planning/phases/36-baseline-and-inventory/36-inventory.json`
- **Verification:** Required-key and duplicate-ID validators passed.
- **Committed in:** `968bd3e`

**2. [Rule 3 - Blocking] Classified safe keyword-scan prose hits**
- **Found during:** Task 1
- **Issue:** The one-off/missing keyword validator flagged documentation prose in `docs/MAINTAINERS.md`, `docs/docker_dev_dx.md`, and brandbook tooling metadata.
- **Fix:** Added explicit `documented_exclusions` entries with source, reason, and reviewed_by_phase instead of inventing false UI risk rows.
- **Files modified:** `.planning/phases/36-baseline-and-inventory/36-inventory.json`
- **Verification:** One-off/missing keyword validator passed.
- **Committed in:** `968bd3e`

---

**Total deviations:** 2 auto-fixed (Rule 3)
**Impact on plan:** No scope change. Both fixes were required for deterministic source-scan reconciliation.

## Issues Encountered

The plan's validation commands are shell-sensitive because they embed `find ... \( ... \)` inside Node strings. I reran the equivalent validator with `String.raw` command strings to preserve escaping and prove the same path coverage.

## Verification

- `node -e "JSON.parse(require('fs').readFileSync('.planning/phases/36-baseline-and-inventory/36-inventory.json','utf8'))"`
- Node validation for unique row IDs, required row keys, exact layer/status enums, nonempty evidence, and valid risk refs.
- Node validation for required ID families: `FOUND-`, `PRIM-`, `GROUP-`, `PAGE-`, `HOOK-`, `FIXTURE-`, `TEST-`, `DOC-`, `ONEOFF-`, `MISSING-`.
- Source-scan reconciliation validator for CSS, LiveView pages, component groups/layouts, ExUnit tests, Playwright specs, docs/brandbook files, recursive fixture/proof inputs, `ScoriaWeb.UI` defs, and JS hooks.
- One-off/missing keyword scan validator.
- Markdown validator for Baseline Truth, Known Risk Register, Phase 37+ Gate, Validation, Multi-Source Coverage Audit, D-01 through D-28, BASE-01, INV-01, INV-02, and required risk IDs.
- `git diff --name-only | grep -v '^#' | grep -Ev '^(\\.planning/phases/36-baseline-and-inventory/36-(INVENTORY\\.md|inventory\\.json|P01-PLAN\\.md|P02-PLAN\\.md|PATTERNS\\.md))$' | wc -l | tr -d ' ' | grep '^0$'`

## Known Stubs

None.

## Threat Flags

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 37 can consume `36-INVENTORY.md` and `36-inventory.json` as the source-reconciled inventory contract. Later phases must respect the Phase 37+ gate and either mitigate, prove unchanged, or explicitly defer any touched row risks.

## Self-Check: PASSED

- Created files exist: `36-P02-SUMMARY.md`.
- Modified files exist: `36-INVENTORY.md`, `36-inventory.json`.
- Task commits exist: `968bd3e`, `5533573`.
- JSON parses and contains all required risks, all 9 layers, all 5 statuses, unique row IDs, required row fields, and valid risk refs.
- Markdown contains Baseline Truth, Known Risk Register, Phase 37+ Gate, Validation, Multi-Source Coverage Audit, D-01 through D-28, BASE-01, INV-01, INV-02, and required risks.
- No runtime/source files were modified.

---
*Phase: 36-baseline-and-inventory*
*Completed: 2026-06-20*
