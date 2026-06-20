---
phase: 36-baseline-and-inventory
plan: P01
subsystem: planning
tags: [inventory, design-system, baseline, risks, json]

requires:
  - phase: 35-release-and-smoke
    provides: v3.2 shipped baseline before v3.3 planning
provides:
  - Phase 36 Markdown baseline and artifact contract
  - Strict JSON inventory schema shell with required enums and row fields
  - Required v3.3 risk register entries and starter rows
affects: [phase-37, phase-38, phase-39, phase-40, phase-41, design-system]

tech-stack:
  added: []
  patterns:
    - Repository-local Markdown plus JSON inventory artifacts
    - JSON owns canonical row and risk fields; Markdown summarizes rationale

key-files:
  created:
    - .planning/phases/36-baseline-and-inventory/36-INVENTORY.md
    - .planning/phases/36-baseline-and-inventory/36-inventory.json
  modified: []

key-decisions:
  - "Phase 36 inventory remains repository-local Markdown plus JSON; no runtime lab, packages, PhoenixStorybook, or source edits."
  - "36-inventory.json is canonical for row IDs, statuses, owners, evidence, and risk references."
  - "v3.0 proof gaps are tracked as RISK-V30-PROOF instead of treated as automatic regressions."

patterns-established:
  - "Baseline proof cites git provenance and existing proof surfaces only."
  - "Later phases touching rows with risk_refs must mitigate, prove unchanged, or explicitly defer with evidence."

requirements-completed: [BASE-01, INV-02]

duration: 5min
completed: 2026-06-20
status: complete
---

# Phase 36 Plan P01: Baseline And Inventory Contract Summary

**Repository-local baseline inventory artifacts now preserve v3.3 starting truth, strict schema metadata, required risks, and starter rows without runtime/source edits.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-06-20T16:13:00Z
- **Completed:** 2026-06-20T16:17:42Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Created `36-INVENTORY.md` with baseline truth, artifact contract, source scope, classification rules, risk register summary, exclusions, and the Phase 37+ gate.
- Created `36-inventory.json` with exact layer/status enums, required row fields, baseline provenance, five required risks, and eight starter rows.
- Preserved the Phase 36 boundary: no runtime UI, source, test, package, screenshot CI, or PhoenixStorybook changes.

## Task Commits

Each task was committed atomically:

1. **Task 1: Record Baseline Provenance And Artifact Contract** - `92e7295` (docs)
2. **Task 2: Seed Required Risks And Starter Inventory Rows** - `3f8407f` (docs)

## Files Created/Modified

- `.planning/phases/36-baseline-and-inventory/36-INVENTORY.md` - Human-readable baseline proof, artifact contract, classification rules, risk summary, exclusions, and Phase 37+ gate.
- `.planning/phases/36-baseline-and-inventory/36-inventory.json` - Machine-readable schema metadata, baseline proof fields, starter rows, and canonical risk register.
- `.planning/phases/36-baseline-and-inventory/36-P01-SUMMARY.md` - This execution summary.

## Decisions Made

- Kept JSON as the canonical source for row fields and risk fields; Markdown summarizes the contract and links future phase behavior to JSON.
- Folded the approval toast and approval decision history todos from their actual pending paths under `.planning/todos/pending/`.
- Treated existing `.planning/STATE.md` orchestration changes as closeout metadata, not task artifact content.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Resolved referenced todo path mismatch**
- **Found during:** Task 2
- **Issue:** The plan's `read_first` paths referenced `.planning/todos/2026-06-18-make-approval-toasts-legible.md` and `.planning/todos/2026-06-20-add-approval-decision-history.md`, but the repository stores them under `.planning/todos/pending/`.
- **Fix:** Read and cited the actual pending todo files while preserving the required risk IDs and owner phases.
- **Files modified:** `.planning/phases/36-baseline-and-inventory/36-INVENTORY.md`, `.planning/phases/36-baseline-and-inventory/36-inventory.json`
- **Verification:** Risk checks confirmed `RISK-TOAST-LEGIBILITY` owner phase 38 and `RISK-APPROVAL-HISTORY` owner phase 39.
- **Committed in:** `3f8407f`

---

**Total deviations:** 1 auto-fixed (Rule 3)
**Impact on plan:** No scope change. The fix used the actual repository-local todo paths required to seed the planned risk entries.

## Issues Encountered

- The exact Task 2 diff-scope command reported `.planning/STATE.md` because it was already modified by orchestration before task work began. A runtime/source scope check returned `0`, and task commits included only the two intended inventory artifacts.

## Verification

- `test -f .planning/phases/36-baseline-and-inventory/36-INVENTORY.md && test -f .planning/phases/36-baseline-and-inventory/36-inventory.json`
- `node -e "JSON.parse(require('fs').readFileSync('.planning/phases/36-baseline-and-inventory/36-inventory.json','utf8'))"`
- `node -e` enum and required-row-field validation for exact `layer_enum`, `status_enum`, and `required_row_fields`
- `git log --oneline -12 | grep -E '8540e04|f490cea'`
- `node -e` validation for five required risk IDs, required risk keys, required row keys, starter row IDs, and owner phases 38/39
- `grep -E 'RISK-(V30-PROOF|TOAST-LEGIBILITY|APPROVAL-HISTORY|RESPONSIVE-SCAN|OVERLAY-FOCUS)' .planning/phases/36-baseline-and-inventory/36-INVENTORY.md`
- `git diff --name-only HEAD | grep -Ev '^(\\.planning/STATE\\.md|\\.planning/phases/36-baseline-and-inventory/36-P01-SUMMARY\\.md)$' | wc -l | tr -d ' ' | grep '^0$'`

## Known Stubs

None.

## Threat Flags

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 37 can consume `36-INVENTORY.md` and `36-inventory.json` as the baseline contract for dev component lab planning. Plan P02 still needs to fill the full inventory row set for `INV-01` and complete `INV-02` across current UI surfaces.

## Self-Check: PASSED

- Created files exist: `36-INVENTORY.md`, `36-inventory.json`, `36-P01-SUMMARY.md`.
- Task commits exist: `92e7295`, `3f8407f`.
- JSON parses and contains required enums, row fields, risk IDs, risk fields, and starter rows.
- No runtime/source files were modified.

---
*Phase: 36-baseline-and-inventory*
*Completed: 2026-06-20*
