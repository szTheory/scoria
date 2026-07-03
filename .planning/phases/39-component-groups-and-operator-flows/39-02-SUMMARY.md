---
phase: 39-component-groups-and-operator-flows
plan: 02
subsystem: ui
tags: [phoenix-liveview, copy, microcopy, elixir]

# Dependency graph
requires:
  - phase: 39-component-groups-and-operator-flows
    provides: "Plan 01's additively-upgraded ScoriaWeb.UI.status_label/1 (D-25 vocabulary, kept as the render-path fallback-safe labeler)"
provides:
  - "ScoriaWeb.Copy — strings-only D-25 action-verb set, status-label vocabulary, and empty/error/loading copy getters"
  - "ScoriaWeb.IncidentCopy, DatasetCopy, ReviewCopy, ConnectorCopy — per-domain copy modules templated on ApprovalCopy"
  - "ConnectorCopy.runtime_status_label/1 (online->Connected, offline->Disconnected) — the fix target for connectors_live's raw runtime.status offender"
  - "ReviewCopy.status_label/1 — operator label for the OnlineScoreCandidate row status atom, the fix target for review_queue_live's raw status offender"
affects: ["39-04", "39-05"]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Strings-only copy module discipline (zero ~H, Copy = data / UI = render, D-24b)"
    - "Per-domain copy module templated on ApprovalCopy: field/2 safe accessor + case/cond dispatch with mandatory _ -> fallback branch"

key-files:
  created:
    - lib/scoria_web/copy.ex
    - lib/scoria_web/incident_copy.ex
    - lib/scoria_web/dataset_copy.ex
    - lib/scoria_web/review_copy.ex
    - lib/scoria_web/connector_copy.ex
    - test/scoria_web/copy_test.exs
  modified: []

key-decisions:
  - "ScoriaWeb.Copy.status_label/1 is an independent D-25 vocabulary lookup (not a delegate to ScoriaWeb.UI.status_label/1) — Copy stays a leaf pure module per D-24b's 'Copy = data' framing, and this plan's file scope (copy.ex only) does not touch ui.ex; the two functions intentionally carry the same 13-status curated vocabulary."
  - "Per-domain modules expose both a raw-value operator-label function (e.g. ConnectorCopy.runtime_status_label/1, ReviewCopy.status_label/1) and, where useful, a record-branching orientation/1 function — satisfying both the literal offender fix (raw status -> label) and the D-24c 'branches on record data' requirement in one module."
  - "Wiring these modules into the actual offending call sites (connectors_live:79, review_queue_live raw status) is explicitly deferred to Plans 04/05 per this plan's objective; this plan only builds and unit-tests the copy layer."

patterns-established:
  - "Copy module template: field/2 (public, safe map accessor for atom/string keys) + private status_value/1 normalizer (atom/binary/nil -> binary or nil) + private humanize/1 fallback, mirroring ApprovalCopy's field/1, present?/1, compact_join/1 helper family."

requirements-completed: [COPY-01]

coverage:
  - id: D1
    description: "ScoriaWeb.Copy — strings-only module owning the D-25 action-verb set, status-label vocabulary, and empty_title/1, empty_cta/1, error_line/1, loading_label/1; zero ~H sigils; no banned words"
    requirement: "COPY-01"
    verification:
      - kind: unit
        ref: "test/scoria_web/copy_test.exs#ScoriaWeb.CopyTest"
        status: pass
    human_judgment: false
  - id: D2
    description: "IncidentCopy, DatasetCopy, ReviewCopy, ConnectorCopy — four per-domain copy modules, each branching on record data (severity/status/state), templated on ApprovalCopy, strings-only with safe fallback branches"
    requirement: "COPY-01"
    verification:
      - kind: unit
        ref: "test/scoria_web/copy_test.exs#ScoriaWeb.IncidentCopyTest, DatasetCopyTest, ReviewCopyTest, ConnectorCopyTest"
        status: pass
    human_judgment: false

duration: 15min
completed: 2026-07-03
status: complete
---

# Phase 39 Plan 02: Strings-only Copy Layer Summary

**Five new copy modules (`ScoriaWeb.Copy` + `IncidentCopy`/`DatasetCopy`/`ReviewCopy`/`ConnectorCopy`) delivering the D-25 canonical vocabulary and record-branching operator labels, zero `~H`, all templated on the existing `ApprovalCopy` discipline.**

## Performance

- **Duration:** ~15 min
- **Tasks:** 2 completed
- **Files modified:** 6 (5 new lib modules + 1 test file)

## Accomplishments
- `ScoriaWeb.Copy` — pure strings-only module owning the D-25 canonical action-verb set (17 verbs), the D-25 status-label vocabulary (13 statuses, deliberately excluding approval-domain "Denied" per D-24d), and `empty_title/1`/`empty_cta/1`/`error_line/1`/`loading_label/1` domain-keyed getters. Zero `~H` sigils.
- Four per-domain copy modules — `IncidentCopy`, `DatasetCopy`, `ReviewCopy`, `ConnectorCopy` — each templated on `ApprovalCopy`'s `case field(x, :key) do ... _ -> default end` dispatch pattern, each with a safe fallback branch so an unseen status/severity/state never raises inside `render/1` (the DoS mitigation from this plan's threat register).
- `ConnectorCopy.runtime_status_label/1` (online → "Connected", offline → "Disconnected") is the ready-to-wire fix for `connectors_live/index.ex:79`'s raw `runtime.status` badge.
- `ReviewCopy.status_label/1` covers the full `OnlineScoreCandidate` status set (`queued`/`scored`/`needs_review`/`promotion_candidate`/`approval_requested`/`reviewing`/`promoted`/`dismissed`/`superseded`) — the ready-to-wire fix for the review queue's raw status atom.
- 25 unit tests across `test/scoria_web/copy_test.exs`, including a banned-word scan across every public getter's output and a source-scan assertion that `copy.ex` contains zero `~H` sigils.

## Task Commits

Each task followed RED → GREEN TDD gates:

1. **Task 1: Add strings-only ScoriaWeb.Copy**
   - `ee63d90` test(39-02): add failing test for ScoriaWeb.Copy (RED)
   - `bf19553` feat(39-02): add strings-only ScoriaWeb.Copy (GREEN)
2. **Task 2: Add per-domain copy modules (Incident/Dataset/Review/Connector)**
   - `d9fb3b3` test(39-02): add failing tests for per-domain copy modules (RED)
   - `517d275` feat(39-02): add per-domain copy modules (Incident/Dataset/Review/Connector) (GREEN)

**Plan metadata:** committed separately below.

## Files Created/Modified
- `lib/scoria_web/copy.ex` - Strings-only D-25 action-verb + status-label vocabulary, empty/error/loading getters
- `lib/scoria_web/incident_copy.ex` - Incident severity/status labels + `orientation/1` (branches on severity)
- `lib/scoria_web/dataset_copy.ex` - Dataset state (`:open`/`:sealed`) labels, `version_label/1`, `orientation/1`
- `lib/scoria_web/review_copy.ex` - Review-candidate `status_label/1`, `review_status_label/1`, `severity_label/1`
- `lib/scoria_web/connector_copy.ex` - `runtime_status_label/1`, connector fleet `status_label/1`, `health_label/1`
- `test/scoria_web/copy_test.exs` - 25 unit tests across all five modules

## Decisions Made
- `Copy.status_label/1` independently curates the D-25 vocabulary rather than delegating to `ScoriaWeb.UI.status_label/1` (already curated in Plan 01) — keeps `Copy` a dependency-free leaf module and stays within this plan's file scope (`copy.ex` only, no `ui.ex` edit).
- Each per-domain module pairs a raw-value operator-label function (the literal offender fix) with a record-branching `orientation/1` or `severity_label/1` function (the D-24c "branches on record data" requirement), rather than treating these as two separate deliverables.
- Wiring into the actual LiveView offenders (`connectors_live:79`, review queue raw status column, dataset `.id`-for-version) is explicitly out of scope here — that's Plans 04/05 per this plan's stated objective ("Creating the modules is foundation; wiring them into pages is Plans 04/05").

## Deviations from Plan

None - plan executed exactly as written. All acceptance criteria met without needing Rule 1-4 fixes.

## Issues Encountered
- Initial `Copy.status_label/1` implementation matched `nil` via the `is_atom/1` guard (Elixir treats `nil` as an atom), producing `"Nil"` instead of `"Unknown"`. Caught immediately by the RED→GREEN test cycle; fixed by adding an explicit `status_label(nil)` clause ahead of the atom clause. No separate deviation entry needed — this was resolved within the same TDD GREEN step before commit.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- All five copy modules are unit-tested, zero-`~H`, and ready for Plans 04/05 to wire into `page_header/1`, scan columns, and the specific microcopy-offender fixes (`connectors_live:79`, review queue, dataset builder, incidents, prompts, eval specs).
- No blockers. `ScoriaWeb.ApprovalCopy` itself (extensions: `status_line/1`, `eyebrow/1`, `decision_outcome/1`, `impact_lead/1`, decided-receipt helpers, raw-status-row deletion) remains untouched here per this plan's zero-overlap boundary with other Wave 1 plans — that work belongs to whichever plan owns `approval_copy.ex`.

---
*Phase: 39-component-groups-and-operator-flows*
*Completed: 2026-07-03*

## Self-Check: PASSED

All 5 created lib files, the test file, and this SUMMARY.md verified present on disk. All 4 task commits (`ee63d90`, `bf19553`, `d9fb3b3`, `517d275`) verified in git log.
