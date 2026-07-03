---
phase: 39-component-groups-and-operator-flows
plan: 05
subsystem: ui
tags: [phoenix, liveview, heex, page_header, empty_state, stream, review-copy, connector-copy, design-system]

# Dependency graph
requires:
  - phase: 39-component-groups-and-operator-flows
    provides: "page_header/1 (Plan 01), ConnectorCopy/ReviewCopy operator-label modules (Plan 02)"
provides:
  - "dataset_live/index, connectors_live/index, review_queue_live, and incidents_live/index each render their single page-outline <h1> through page_header/1"
  - "dataset_live drops the semantically-redundant panel <:title>Datasets</:title> region title (D-04)"
  - "review_queue's filter facets (review_status/severity/promotion_state) moved from socket assigns to the URL via push_patch + handle_params, validated against a closed enum allow-list (D-09/D-11)"
  - "incidents' <ul> streams via phx-update=\"stream\" with a per-<li> id, zero table/1 change (D-10)"
  - "connectors runtime.status/health_state/last_refresh_status badges route through ConnectorCopy/status_label instead of raw strings; run_id/session_id demoted to <.id> evidence; review row status routes through ReviewCopy.status_label/1; dataset version renders as a plain label instead of misusing <.id> (D-23)"
  - "dataset_live, connectors_live, and review_queue_live each distinguish a genuine data-load failure (inline scoria-flash--fail + retry) from a legitimately empty result (empty_state/1), per D-08"
affects: [39-08]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "page_header/1 attr :title (not slot) as the single page-outline <h1> source of truth, with :actions for at most one header action"
    - "D-08 load-error split: a private load_* helper returns {:ok, data} | :error (try/rescue around the query), the LiveView keeps a :load_error boolean assign, and render/1 branches between the normal data region and an inline scoria-flash--fail + retry region — never collapsing a real query failure into an empty-state string"
    - "D-09 URL-held filter facets: handle_params validates each facet against a closed compile-time enum list (Enum.member?, not a guard) and falls back to a safe default on any unrecognized value, so a tampered query string can't reach the context-layer query unvalidated"
    - "D-10 stream target selection: only mount-only, non-PubSub-reloaded lists are safe stream/3 targets; PubSub-reload-driven or Enum.find-lookup-based collections (documented in CONTEXT.md) are excluded on purpose"

key-files:
  created: []
  modified:
    - lib/scoria_web/live/dataset_live/index.ex
    - lib/scoria_web/live/connectors_live/index.ex
    - lib/scoria_web/live/review_queue_live.ex
    - lib/scoria_web/live/incidents_live/index.ex
    - test/scoria_web/live/review_queue_live_test.exs

key-decisions:
  - "Widened the connectors status-badge fix beyond the single line 78 offender the PATTERNS.md audit named: connector.health_state and connector.last_refresh_status badges had the identical raw-atom-as-badge-label pattern (T-39-05-I disposes 'connectors/review columns' plural as mitigate), so both now route through ConnectorCopy.health_label/1 / status_label/1 alongside the named runtime.status fix."
  - "Did not add a D-08 error/retry split to incidents_live. OperatorSurface.list_tenant_incidents/1 already rescues internally to [] (outside this plan's files_modified scope), so a LiveView-level try/rescue around it would be dead code — the exception never reaches the call site to be caught."
  - "Interpreted 'lead the run/session cells with status' (Task 1 read_first) as already satisfied by the existing table column order (Status precedes Active runs/Presence or Queue); the concrete fix implemented is demoting current_run_id/host_session_id into the <.id> copyable-evidence primitive with an explicit per-row id (avoids dom-id collisions if two runtimes ever share a run/session id)."
  - "review_queue's row selection (@selected_candidate_id) stays in socket assigns, not the URL — only the filter facets were in this plan's D-09 scope. Confirmed via a scoped test assertion that the detail rail legitimately keeps showing a previously-selected candidate across a filter change (ephemeral state, unaffected by URL-held filters)."

requirements-completed: [FLOW-01, FLOW-02, COPY-01]

coverage:
  - id: D1
    description: "dataset_live routes its <h1> through page_header/1, drops the redundant panel <:title>Datasets</:title>, and renders the dataset version as a plain label instead of misusing <.id>"
    requirement: "FLOW-02"
    verification:
      - kind: unit
        ref: "test/scoria_web/live/dataset_live/index_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "connectors_live routes its <h1> through page_header/1; runtime.status/health_state/last_refresh_status badges route through ConnectorCopy/status_label instead of raw strings; current_run_id/host_session_id demoted to <.id> evidence"
    requirement: "COPY-01"
    verification:
      - kind: unit
        ref: "test/scoria_web/live/connectors_live_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "review_queue routes its <h1> + Back-to-dashboard action through page_header/1; filter facets move from socket assigns to URL params via push_patch/handle_params with enum validation; the Sample column's raw status atom routes through ReviewCopy.status_label/1"
    requirement: "FLOW-02"
    verification:
      - kind: unit
        ref: "test/scoria_web/live/review_queue_live_test.exs"
        status: pass
    human_judgment: false
  - id: D4
    description: "incidents_live routes its <h1> through page_header/1 and streams the incident <ul> via phx-update=\"stream\" with per-<li> ids, keeping the list (not table) idiom with a rationale comment"
    requirement: "FLOW-02"
    verification:
      - kind: unit
        ref: "test/scoria_web/live/incidents_live_test.exs"
        status: pass
    human_judgment: false
  - id: D5
    description: "dataset_live, connectors_live, and review_queue_live each render the canonical D-08 empty/error data-region convention (empty_state/1 with a next action vs. inline scoria-flash--fail + retry)"
    requirement: "FLOW-02"
    verification:
      - kind: unit
        ref: "test/scoria_web/live/dataset_live/index_test.exs, test/scoria_web/live/connectors_live_test.exs, test/scoria_web/live/review_queue_live_test.exs"
        status: pass
    human_judgment: false

duration: 30min
completed: 2026-07-03
status: complete
---

# Phase 39 Plan 05: Component Groups And Operator Flows — Scan Page Normalization Summary

**Migrated dataset/connectors/review_queue/incidents off hand-rolled page headers onto `page_header/1`, moved review_queue's filter to URL-held state with enum validation, streamed the incidents list, fixed the connectors/review/dataset D-23 microcopy offenders, and added a real D-08 load-error/empty split to the three pages whose data queries were previously unrescued or silently collapsed errors into "no rows".**

## Performance

- **Duration:** ~30 min
- **Started:** 2026-07-03T09:25:00Z
- **Completed:** 2026-07-03T09:35:00Z
- **Tasks:** 3
- **Files modified:** 5 (4 LiveViews + 1 test file)

## Accomplishments
- `dataset_live/index` and `connectors_live/index` now render their single page-outline `<h1>` via `page_header/1`; `dataset_live` drops the semantically-redundant panel `<:title>Datasets</:title>` region title and renders the dataset version as a plain label instead of misusing the `<.id>` copyable-ID primitive.
- `connectors_live`'s runtime status badge routes through `ConnectorCopy.runtime_status_label/1` instead of the raw `runtime.status` string; the connector health and refresh-state badges (same offender class, T-39-05-I) route through `ConnectorCopy.health_label/1` / `status_label/1`; `current_run_id`/`host_session_id` are demoted to `<.id>` evidence with explicit per-row ids.
- `review_queue_live` migrates its header (including the "Back to dashboard" ghost action) to `page_header/1`, moves the review-status/severity/promotion-state filter from socket-only assigns to the URL via `push_patch` + `handle_params`, and validates every facet against a closed enum allow-list so a tampered query param falls back to the default rather than reaching the context-layer query unvalidated (T-39-05-T). The Sample column's raw `row.status` fallback now routes through `ReviewCopy.status_label/1`.
- `incidents_live/index` routes its header through `page_header/1` and converts the incident `<ul>` to `stream(:incidents, ...)` with `phx-update="stream"` and a per-`<li>` DOM id — zero `table/1` change. The list (not table) idiom is kept with an inline rationale comment (D-07).
- `dataset_live`, `connectors_live`, and `review_queue_live` now distinguish a genuine data-load failure (inline `scoria-flash--fail` + retry button) from a legitimately empty result (`empty_state/1`), per D-08 — previously `dataset_rows/0` silently rescued exceptions into `[]`, misrepresenting real query failures as "no datasets".
- Grep-confirmed: zero raw `<h1>` literals remain in any of the four files (all page-outline headers now live inside `page_header/1`); zero raw `label={runtime.status}`; every `row.status` render routes through a label fn; `phx-update="stream"` present on the incidents `<ul>`; `review_queue_live` defines `handle_params/3`.

## Task Commits

Each task was committed atomically:

1. **Task 1: dataset + connectors — header, redundant-title, and microcopy** - `e2479c3` (feat)
2. **Task 2: review_queue — header, filter socket→URL, raw status fix** - `eba95a0` (feat)
3. **Task 3: incidents — page_header + stream the list (D-10)** - `6c01997` (feat)

**Plan metadata:** (this commit)

## Files Created/Modified
- `lib/scoria_web/live/dataset_live/index.ex` - Header migrated to `page_header/1`; dropped redundant panel title; version cell now a plain label; added `load_datasets/1` D-08 error/empty split + `retry_load` event
- `lib/scoria_web/live/connectors_live/index.ex` - Header migrated to `page_header/1`; status/health/refresh badges route through `ConnectorCopy`/`status_label`; run_id/session_id demoted to `<.id>`; added `load_fleet/1` D-08 error/empty split + `retry_load` event
- `lib/scoria_web/live/review_queue_live.ex` - Header + actions migrated to `page_header/1`; filter facets moved to URL via `push_patch`/`handle_params` with enum validation; Sample column routes through `ReviewCopy.status_label/1`; added `refresh_queue/1` D-08 error/empty split + `retry_load` event
- `lib/scoria_web/live/incidents_live/index.ex` - Header migrated to `page_header/1`; `@incidents` converted to `stream(:incidents, ...)`; `<ul>` gets `phx-update="stream"` + per-`<li>` id + D-07 rationale comment
- `test/scoria_web/live/review_queue_live_test.exs` - Added filter push_patch round-trip test (scoped to the `#review-queue` table, since the detail rail legitimately retains the prior selection across a filter change) and an unrecognized-`review_status`-falls-back-to-default enum validation test

## Decisions Made
- **Widened the connectors status-badge fix beyond the single named offender.** The PATTERNS.md D-23 audit table names only `connectors_live/index.ex:78` (`runtime.status`), but `connector.health_state` and `connector.last_refresh_status` had the identical raw-atom-as-badge-label pattern in the same file, and the threat model's T-39-05-I disposition covers "connectors/review columns" (plural) as `mitigate`. Fixed all three in this task rather than leaving two known-identical offenders unaddressed.
- **No D-08 error/retry split for `incidents_live`.** `OperatorSurface.list_tenant_incidents/1` already rescues internally to `[]`, and that file (`operator_surface.ex`) is outside this plan's `files_modified` scope. A LiveView-level `try/rescue` around an already-rescued call would be dead code that can never trigger — so the plan's D-08 "distinguish empty from error" convention is satisfied here by the existing (correct, if imperfectly-honest) empty-state path rather than a duplicated no-op guard.
- **`<.id>` demotion, not a re-stated status label, for connectors' run/session cells.** Interpreted the Task 1 instruction "lead the run/session cells with status" as describing the table's existing column order (Status already precedes Active runs / Presence or Queue), not an instruction to inject a second status word into those specific cells. The concrete, verifiable fix is demoting `current_run_id`/`host_session_id` into the `<.id>` copyable-evidence primitive with an explicit per-row id (`run-id-#{runtime.id}` / `host-session-#{runtime.id}`) to avoid any DOM-id collision if two runtimes ever share a run/session id.
- **review_queue's row selection stays in assigns, not the URL.** Only the filter facets were in this plan's D-09 scope (Plan 08's D-11 guard targets the filter, not selection). Added a scoped test assertion (via Floki, limited to `#review-queue`) confirming the detail rail legitimately keeps showing the previously-selected candidate across a filter change — this is correct ephemeral-state behavior, not a bug.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added D-08 load-error/empty split to dataset_live, connectors_live, and review_queue_live**
- **Found during:** Task 1 (dataset + connectors) and Task 2 (review_queue)
- **Issue:** The plan's acceptance criteria explicitly requires each page's data region to render "error via inline scoria-flash--fail + retry" per D-08, but `dataset_rows/0` silently rescued any query exception into `[]` (masking a real failure as "no datasets match this view"), and `connectors_live`'s/`review_queue_live`'s queries were unrescued entirely (would crash the LiveView on a DB error instead of showing a recoverable state).
- **Fix:** Wrapped each page's data-fetch in a private `load_*`/`fetch_*` helper returning `{:ok, data} | :error`, added a `:load_error` boolean assign, a `retry_load` event, and a render-time branch between the normal data region and an inline `scoria-flash--fail` + retry button.
- **Files modified:** lib/scoria_web/live/dataset_live/index.ex, lib/scoria_web/live/connectors_live/index.ex, lib/scoria_web/live/review_queue_live.ex
- **Verification:** All existing empty-state tests still pass unchanged (the true-empty path is untouched); `mix compile --warnings-as-errors` clean.
- **Committed in:** e2479c3 (Task 1), eba95a0 (Task 2)

**2. [Rule 2 - Missing Critical] Fixed connector health_state/last_refresh_status raw-atom badges alongside the named runtime.status offender**
- **Found during:** Task 1
- **Issue:** T-39-05-I's threat mitigation ("Raw status atoms routed through status_label/1... never color/atom-only") disposes as `mitigate` for "connectors/review columns" broadly; `connector.health_state` and `connector.last_refresh_status` had the same raw-atom-as-badge-label pattern as the named `runtime.status` offender but weren't individually called out in the PATTERNS.md line-by-line audit.
- **Fix:** Routed both through `ConnectorCopy.health_label/1` (health_state) and `status_label/1` (last_refresh_status).
- **Files modified:** lib/scoria_web/live/connectors_live/index.ex
- **Verification:** `mix test test/scoria_web/live/connectors_live_test.exs --warnings-as-errors` passes; no test asserted the raw string, so no regression.
- **Committed in:** e2479c3

---

**Total deviations:** 2 auto-fixed (both Rule 2 - missing critical/security correctness per the plan's own D-08/threat-model text)
**Impact on plan:** Both auto-fixes implement requirements the plan's acceptance criteria and threat model explicitly stated but that weren't yet wired into the LiveViews' data-fetch paths. No scope creep — no new files, no architectural changes, no files outside the plan's `files_modified` list touched.

## Issues Encountered
- Elixir's `in` operator cannot use a runtime-bound list inside a guard clause (`when value in allowed`); rewrote `validate_facet/3` to use a plain `if value in allowed, do: ..., else: ...` body instead of a guard.
- The first draft of the filter round-trip test asserted the previously-selected ("pending") candidate's text was fully absent from the page after a filter change, but `review_queue_live`'s detail rail intentionally keeps the prior selection visible (ephemeral state, not URL-held) — the assertion was too broad. Scoped it to the `#review-queue` table via Floki instead of testing the full page HTML.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All four migrated pages are grep-confirmed to have zero raw `<h1>` literals (all live inside `page_header/1`), zero raw `label={runtime.status}`, and no `row.status` rendered without a label fn — Plan 08's D-05/D-26 source-scan guards should find these files green on arrival.
- `review_queue`'s filter is now URL-held and validated; Plan 08's D-11 guard must confirm it does NOT red-flag `dataset_live`'s sort (policy B, exempt) while it DOES confirm `review_queue`'s filter is no longer socket-only.
- `incidents_live`'s `<ul>` is now the one streamed collection on the page (per D-10); the pending-approvals inbox elsewhere in the codebase remains un-streamed, matching CONTEXT.md's explicit exclusion.
- No blockers.

---
*Phase: 39-component-groups-and-operator-flows*
*Completed: 2026-07-03*

## Self-Check: PASSED

All 4 modified LiveViews + the modified test file exist on disk; all 3 task commit hashes (e2479c3, eba95a0, 6c01997) exist in `git log --oneline --all`.
