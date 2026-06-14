---
phase: 15-high-traffic-screens-evidence-adapters
plan: "04"
subsystem: ui
tags: [phoenix-liveview, approvals, connectors, design-system, ds06]

requires:
  - phase: 15-high-traffic-screens-evidence-adapters
    plan: "01"
    provides: Shared evidence primitives and UI gateway components
provides:
  - Approvals inbox rendered as a shared table, parent-owned drawer, and final confirmation modal
  - Connector runtime presence and connector fleet rendered as dense shared tables
  - Runtime and connector detail components converted to thin content adapters
  - Reduced DS-06 baseline rows for Approvals and Connectors files
affects:
  - phase-15-high-traffic-screens
  - approvals
  - connectors
  - runtime-presence
  - evidence-adapters

tech-stack:
  added: []
  patterns:
    - Approvals use table -> drawer -> final modal while preserving workflow-owned approve/reject events
    - Connectors own shared drawer shells in the parent LiveView and delegate only drawer body content to detail components
    - Runtime and connector rows expose visible text badges instead of color-only dots

key-files:
  created:
    - .planning/phases/15-high-traffic-screens-evidence-adapters/15-04-SUMMARY.md
  modified:
    - lib/scoria_web/live/approvals_live/index.ex
    - lib/scoria_web/components/approval_inbox_component.ex
    - lib/scoria_web/live/connectors_live/index.ex
    - lib/scoria_web/components/runtime_detail_drawer_component.ex
    - lib/scoria_web/components/connector_detail_drawer_component.ex
    - lib/scoria_web/operator_surface.ex
    - test/scoria_web/live/approvals_live_test.exs
    - test/scoria_web/live/approvals_live_integration_test.exs
    - test/scoria_web/live/connectors_live_test.exs
    - test/scoria_web/components/runtime_detail_drawer_component_test.exs
    - test/support/ds06_baseline.txt

key-decisions:
  - "Approvals keep direct `approve` and `reject` events for compatibility, but visible drawer actions now open a shared final confirmation modal."
  - "Rejection remains a durable workflow decision that keeps the run paused; only approval attempts `Resume.resume_run/1`."
  - "Connectors remain an observational surface only; no setup wizard, Tool Registry, MCP Gateway, detail route, or lifecycle controls were added."
  - "SCREEN-03 and SCREEN-04 remain pending for phase-level closeout rather than being marked complete mid-phase."

patterns-established:
  - "Use `<.table>` scan surfaces for operator queues where row action opens a parent-owned shared drawer."
  - "Use content-only drawer adapter components for runtime/connector detail sections; outer overlay shells stay in the LiveView."
  - "Use DS-06 source contracts plus drift guard before reducing raw palette baseline rows."

requirements-completed: []

duration: 13 min
completed: 2026-06-13
---

# Phase 15 Plan 04: Approvals and Connectors Summary

**Approvals and Connectors now use shared scan/detail shells while preserving durable approval decisions and real OperatorSurface data.**

## Performance

- **Duration:** 13 min
- **Started:** 2026-06-13T01:19:40Z
- **Completed:** 2026-06-13T01:32:00Z
- **Tasks:** 2 completed
- **Files modified:** 11

## Accomplishments

- Converted Approvals from a local fixed overlay/card list to a shared table, shared drawer, and shared final confirmation modal.
- Preserved workflow-owned approval semantics: `Workflows.approve/3` records decisions, approval resumes when possible, and rejection keeps the workflow paused with warn-tone copy.
- Converted Connectors to dense shared tables for runtime presence and connector fleet posture, with visible status/health/refresh badges.
- Moved runtime and connector details into parent-owned shared drawers while making the detail components content-only evidence adapters.
- Added runtime `last_seen_at` to the OperatorSurface runtime projection so the shared runtime table can show real recency data.
- Removed five stale DS-06 baseline rows after the drift guard confirmed the touched files now have zero raw palette matches.

## Task Commits

1. **Task 1/2 RED: Add approvals/connectors shared-surface contracts** - `7f30433` (test)
2. **Task 1/2 GREEN: Convert approvals and connectors shared surfaces** - `288960a` (feat)

**Plan metadata:** pending in this summary commit.

## Files Created/Modified

- `lib/scoria_web/live/approvals_live/index.ex` - Owns selected approval drawer state, final decision modal state, and durable approve/reject handling.
- `lib/scoria_web/components/approval_inbox_component.ex` - Renders the approvals queue as a shared table with consequence copy and inspect row actions.
- `lib/scoria_web/live/connectors_live/index.ex` - Renders runtime presence and connector fleet tables plus parent-owned runtime/connector drawers.
- `lib/scoria_web/components/runtime_detail_drawer_component.ex` - Renders runtime identity, offline reason, active workflow, and semantic summary as evidence sections.
- `lib/scoria_web/components/connector_detail_drawer_component.ex` - Renders connector detail as evidence rows without an outer drawer shell.
- `lib/scoria_web/operator_surface.ex` - Adds `last_seen_at` to runtime DTOs.
- `test/scoria_web/live/approvals_live_test.exs` - Pins table, drawer, modal, toast, and raw-palette contracts.
- `test/scoria_web/live/approvals_live_integration_test.exs` - Pins producer-path approval/rejection behavior and modal confirmation flow.
- `test/scoria_web/live/connectors_live_test.exs` - Pins runtime/connector table and drawer behavior.
- `test/scoria_web/components/runtime_detail_drawer_component_test.exs` - Pins content-adapter runtime detail output.
- `test/support/ds06_baseline.txt` - Removes Approvals/Connectors rows that now scan to zero.

## Decisions Made

- Kept the direct `approve` and `reject` LiveView events so existing callers and tests can still confirm decisions without route or backend churn.
- Used parent-owned shared drawers for both runtime and connector details rather than leaving shell ownership inside detail components.
- Kept connector posture read-only; this plan did not add setup flows or lifecycle actions.

## Deviations from Plan

None - implementation followed the planned shared table/drawer/modal conversion.

## Issues Encountered

- The RED reject integration contract asserted final modal copy before opening the modal. It was corrected in the GREEN commit to click the drawer's `Reject approval` action first, matching the planned drawer-action -> modal-confirm flow.
- The first GREEN test run surfaced stale DS-06 baseline rows and a missing runtime ID row in the content adapter; both were fixed before commit.

## Verification

- `mix test test/scoria_web/live/approvals_live_test.exs test/scoria_web/live/approvals_live_integration_test.exs test/scoria_web/live/connectors_live_test.exs test/scoria_web/components/runtime_detail_drawer_component_test.exs test/scoria_web/ds06_drift_guard_test.exs` - passed, 29 tests, 0 failures.
- Source assertions confirmed no forbidden raw palette strings remain in the five touched source files.
- Source assertions confirmed `approvals_live/index.ex` contains `<.drawer`, `<.modal`, `Approve workflow`, `Reject approval`, `Keep reviewing`, `Workflows.approve`, and `Resume.resume_run`.
- Source assertions confirmed `connectors_live/index.ex` contains `<.table`, `Inspect runtime`, `Inspect connector`, and parent-owned `<.drawer` usage.
- Source assertions confirmed runtime and connector detail adapters do not render local `scoria-drawer`, `<aside>`, or forbidden raw palette classes.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 15-05 can finish the remaining evidence adapter sweep with Approvals and Connectors already converted to the shared-shell contract.

## Self-Check: PASSED

- [x] All planned tasks executed.
- [x] Task work committed.
- [x] SUMMARY.md created.
- [x] Focused verification passed.
- [x] DS-06 baseline reductions verified by drift guard.

---
*Phase: 15-high-traffic-screens-evidence-adapters*
*Completed: 2026-06-13*
