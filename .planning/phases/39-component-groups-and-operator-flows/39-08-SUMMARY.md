---
phase: 39-component-groups-and-operator-flows
plan: 08
subsystem: ui
tags: [phoenix, liveview, playwright, drift-guard, source-scan, ex_unit]

# Dependency graph
requires:
  - phase: 39-component-groups-and-operator-flows (Plans 04-07)
    provides: page-header migrations, review_queue URL-encoded filter, D-23 microcopy fixes, and the D-09 Pending|Decided/decided-receipt/deep-link surface this plan's guards and e2e specs assert against
provides:
  - D-05 single-header source-scan drift guard (test/scoria_web/single_header_guard_test.exs)
  - D-11 scan-convention source-scan drift guard (test/scoria_web/scan_convention_guard_test.exs)
  - D-26 copy source-scan drift guard (test/scoria_web/copy_guard_test.exs)
  - Automated FLOW-01/03/04 e2e proof extending priv/dev/e2e/ia_orientation.spec.mjs (replaces a manual UAT checkpoint)
  - Fix for a real D-26 offender the new copy guard caught (incidents severity raw-status-atom leak)
affects: [41-hardening-and-dom-proof]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Phase-38 source-scan drift guard idiom (File.read! + Path.wildcard + Regex, offender-collection list, assert offenders == []) reused for D-05/D-11/D-26"
    - "Source-scan function-clause splitting via `String.split(source, ~r/\\n  (?=def |defp )/)` to check handle_event/handle_params bodies for push_patch without a full Elixir parser"
    - "Playwright destructive-decision top-up pattern (serial, retries: 0) reused from uat.spec.mjs for the FLOW-04 decided-receipt spec"

key-files:
  created:
    - test/scoria_web/single_header_guard_test.exs
    - test/scoria_web/scan_convention_guard_test.exs
    - test/scoria_web/copy_guard_test.exs
    - .planning/phases/39-component-groups-and-operator-flows/deferred-items.md
  modified:
    - priv/dev/e2e/ia_orientation.spec.mjs
    - lib/scoria_web/live/incidents_live/index.ex
    - lib/scoria_web/live/incidents_live/show.ex
    - test/scoria_web/live/incidents_live_test.exs

key-decisions:
  - "single_header_guard_test.exs excludes dataset_live/promote_component.ex (rendered exclusively inside dataset_live/index.ex's <.drawer id=\"dataset-promote-drawer\">) alongside ui.ex, since the plan's named dialog-scoped filename fragments (drawer/modal/palette/notebook) don't literally match this file's name"
  - "scan_convention_guard_test.exs scopes D-11 to the plan action's literal instruction (filter/scope-not-socket-only + sort exemption) rather than the broader CONTEXT.md D-11 restatement (section-order/primitives), since the task's <action>/<acceptance_criteria> only specify the former"
  - "copy_guard_test.exs's raw-status-label check trusts ANY function call in label={} (detects only the bare dotted-field-access anti-pattern, e.g. label={runtime.status}) rather than enumerating every approved *Copy function name, so legitimate wrapper helpers like ApprovalInboxComponent's mobile_status_label/2 are never false-flagged"
  - "Fixed incidents_live/index.ex + show.ex to route incident.severity through IncidentCopy.severity_label/1 instead of a raw atom (Rule 1 auto-fix, required for the new copy guard to be green on arrival) and updated the one incidents_live_test.exs assertion that had encoded the old raw-atom text as expected"
  - "Fixed a stale ia_orientation.spec.mjs selector (button[phx-click=\"select_incident\"]) to match the current routed <a href> incident-selection markup (D-07/D-10), discovered while verifying the full e2e suite for this plan's Task 3"

requirements-completed: [FLOW-01, FLOW-02, COPY-01]

coverage:
  - id: D1
    description: "D-05 single-header guard: every page LiveView renders exactly one sanctioned page-outline header (page_header/1, object_header/1, stub_page/1), excludes ui.ex + the dialog-scoped promote_component.ex, and guards against raw <h1> literals plus D-04 static-literal region-title restatement"
    requirement: FLOW-01
    verification:
      - kind: unit
        ref: "test/scoria_web/single_header_guard_test.exs (3 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "D-11 scan-convention guard: review_queue_live and approvals_live/index.ex filter/scope state is sourced from handle_params (URL), never mutated by a bare handle_event assign without push_patch; sort stays exempt per D-09 option (B) and dataset_live is confirmed not red-flagged"
    requirement: FLOW-02
    verification:
      - kind: unit
        ref: "test/scoria_web/scan_convention_guard_test.exs (3 tests)"
        status: pass
    human_judgment: false
  - id: D3
    description: "D-26 copy guard: no schema/module name in a static-literal heading, no opaque ID interpolated bare into a heading slot, and status/severity/state renders only via an approved label function — caught and required fixing a real incidents severity raw-atom offender"
    requirement: COPY-01
    verification:
      - kind: unit
        ref: "test/scoria_web/copy_guard_test.exs (3 tests)"
        status: pass
      - kind: unit
        ref: "test/scoria_web/live/incidents_live_test.exs#incident severity and status badges include visible text"
        status: pass
    human_judgment: false
  - id: D4
    description: "Automated flow proof (FLOW-01/03/04) against the running dashboard replacing a manual UAT checkpoint: one page-outline header per primary page ×9, decision-first approval drawer with no warn banner, Pending|Decided URL scope, decided read-only receipt with no decision buttons, and the ?approval=<id> deep-link"
    requirement: FLOW-01
    verification:
      - kind: e2e
        ref: "priv/dev/e2e/ia_orientation.spec.mjs (12 new Phase-39 tests, run via mix scoria.ui.e2e against localhost:4799/scoria)"
        status: pass
    human_judgment: false

duration: 48min
completed: 2026-07-03
status: complete
---

# Phase 39 Plan 8: Warning-Grade Drift Guards + Automated Flow Proof Summary

**Three Phase-38-idiom source-scan drift guards (D-05 single-header, D-11 scan-convention, D-26 copy) plus 12 new Playwright specs proving FLOW-01/03/04 against the running dashboard — the copy guard caught and required fixing a real, previously-undetected raw-status-atom leak in the incidents severity badges.**

## Performance

- **Duration:** 48 min
- **Started:** 2026-07-03T10:29:35Z (STATE.md last session mark)
- **Completed:** 2026-07-03T11:17:50Z
- **Tasks:** 3
- **Files modified:** 8 (3 new guard test files, 1 e2e spec, 2 incidents_live source files, 1 test file, 1 deferred-items log)

## Accomplishments
- `test/scoria_web/single_header_guard_test.exs` — D-05: every page LiveView renders exactly one sanctioned page-outline header, excludes `ui.ex` and the dialog-scoped `dataset_live/promote_component.ex`, guards against raw `<h1>` literals, and warns on static-literal D-04 region-title restatement.
- `test/scoria_web/scan_convention_guard_test.exs` — D-11: `review_queue_live.ex`'s `:filters` and `approvals_live/index.ex`'s `:scope` must be sourced from `handle_params` (URL), never mutated by a bare `handle_event` assign without `push_patch`; sort stays exempt per the D-09 option (B) lock from Plan 05, with `dataset_live` explicitly confirmed as not red-flagged.
- `test/scoria_web/copy_guard_test.exs` — D-26: no CamelCase schema/module name in a static-literal heading, no opaque ID (`entity_id`/`*_run_id`/`*_session_id`) interpolated bare into a heading slot (usage wrapped in `<.id>` is fine), and status/severity/state renders only via an approved label function.
- Discovered via the new copy guard that `incidents_live/index.ex` and `incidents_live/show.ex` passed the raw `incident.severity` atom straight to `<.badge label=>`, bypassing the existing `IncidentCopy.severity_label/1` — the same offender class as the connectors `runtime.status` fix from Plan 05, just never caught until this guard existed. Fixed both call sites.
- Extended `priv/dev/e2e/ia_orientation.spec.mjs` with 12 new tests covering FLOW-01 (one page-outline header per primary page, ×9 pages), FLOW-03 (decision-first approval drawer, no uppercase warn banner), and FLOW-04 (Pending|Decided URL scope, decided read-only receipt with no decision buttons, `?approval=<id>` deep-link) — an automated flow proof replacing a manual UAT checkpoint per the project's shift-left preference.
- Fixed a stale pre-existing e2e selector (`button[phx-click="select_incident"]`) discovered while verifying the full suite, updating it to the current routed `<a href>` incident-selection markup.

## Task Commits

Each task was committed atomically:

1. **Task 1: Single-header (D-05) + scan-convention (D-11) guards** - `cf8a5811` (test)
2. **Task 2: Copy guard (D-26)** - `1dd0b10f` (test) — includes the incidents severity Rule-1 fix
3. **Task 3: Automated flow proof + full-suite green** - `8eb24830` (test)

**Plan metadata:** (this commit)

## Files Created/Modified
- `test/scoria_web/single_header_guard_test.exs` - D-05 guard: header-count, raw-`<h1>`, D-04 static-literal region-title checks
- `test/scoria_web/scan_convention_guard_test.exs` - D-11 guard: URL-sourced filter/scope, socket-only-mutation regression, sort exemption
- `test/scoria_web/copy_guard_test.exs` - D-26 guard: module-name, opaque-ID, raw-status-label checks
- `lib/scoria_web/live/incidents_live/index.ex` - wired severity badge through `IncidentCopy.severity_label/1`
- `lib/scoria_web/live/incidents_live/show.ex` - same fix, detail-page queue rail
- `test/scoria_web/live/incidents_live_test.exs` - updated the badge-text assertion to expect the humanized label
- `priv/dev/e2e/ia_orientation.spec.mjs` - added FLOW-01/03/04 Phase-39 specs; fixed the stale incident-selector test
- `.planning/phases/39-component-groups-and-operator-flows/deferred-items.md` - logs pre-existing, out-of-scope e2e and full-suite failures

## Decisions Made
- Scoped D-11's scan-convention guard to the plan task's literal instruction (URL-sourced filter/scope + sort exemption), not the broader section-order/primitives restatement in `39-CONTEXT.md` — the task's `<action>`/`<acceptance_criteria>` only specify the former, and adding the latter would be unrequested scope expansion.
- Designed the D-26 raw-status-label check to trust any function call inside `label={}` (only the bare dotted-field-access shape like `label={runtime.status}` is flagged) rather than enumerating every approved `*Copy` function name — this correctly passes `ApprovalInboxComponent`'s `mobile_status_label/2` wrapper without needing to special-case it.
- Excluded `dataset_live/promote_component.ex` from both the single-header and copy guards' page-file scan, since it is rendered exclusively as a `<.live_component>` inside `dataset_live/index.ex`'s `<.drawer>` (dialog-scoped, D-03 exemption) even though its filename doesn't match the plan's illustrative `drawer/modal/palette/notebook` fragment list.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Incidents severity badges bypassed the approved-label-fn allow-list**
- **Found during:** Task 2 (writing the D-26 copy guard)
- **Issue:** `incidents_live/index.ex:118` and `incidents_live/show.ex:97` passed the raw `incident.severity` atom (e.g. `"critical"`) directly to `<.badge label=>`, the same offender class as the `connectors runtime.status` fix from Plan 05 — never caught because no guard existed for it until this plan.
- **Fix:** Aliased `ScoriaWeb.IncidentCopy` and routed both call sites through the existing `IncidentCopy.severity_label/1` (already built in Plan 02).
- **Files modified:** `lib/scoria_web/live/incidents_live/index.ex`, `lib/scoria_web/live/incidents_live/show.ex`
- **Verification:** Reverted the fix and re-ran `copy_guard_test.exs` to confirm it fails without the fix (offender list correctly non-empty), then restored the fix and confirmed green.
- **Committed in:** `1dd0b10f` (Task 2 commit)

**2. [Rule 1 - Bug] Companion test asserted the old raw-atom badge text**
- **Found during:** Task 3 (`mix test --warnings-as-errors` verification)
- **Issue:** `test/scoria_web/live/incidents_live_test.exs`'s "incident severity and status badges include visible text" test asserted `"critical" in badge_text` — the exact pre-fix (offending) rendering. Deviation 1's fix correctly changed the rendered text to `"Critical"`, breaking this test.
- **Fix:** Updated the assertion to `"Critical" in badge_text`, matching `IncidentCopy.severity_label/1`'s intended humanized output.
- **Files modified:** `test/scoria_web/live/incidents_live_test.exs`
- **Verification:** `mix test test/scoria_web/live/incidents_live_test.exs --warnings-as-errors` — 12 tests, 0 failures.
- **Committed in:** `8eb24830` (Task 3 commit)

**3. [Rule 3 - Blocking] Stale e2e selector blocked the full e2e-suite-passes verification**
- **Found during:** Task 3 (running the full `mix scoria.ui.e2e` suite to verify the new flow-proof specs)
- **Issue:** The pre-existing (Phase 13) "Incident ingress → Open run → return chip + run egress verbs" test used `button[phx-click="select_incident"]`, but `incidents_live/index.ex` now routes incident selection through a real `<a href>` link to `/incidents/:id` (D-07/D-10 routed navigation from an earlier Phase 39 plan) — the selector never matched, and the plan's own `<verification>` requires the e2e suite to pass.
- **Fix:** Updated the locator to `a.scoria-selectable-card` filtered by summary text, and added the `waitForReady` call the new full-page navigation needs (the old inline-panel flow never navigated, so the original test never waited for one).
- **Files modified:** `priv/dev/e2e/ia_orientation.spec.mjs`
- **Verification:** `npx playwright test --grep "Incident ingress"` passes; re-ran the full `mix scoria.ui.e2e` suite and confirmed no new failures introduced.
- **Committed in:** `8eb24830` (Task 3 commit)

---

**Total deviations:** 3 auto-fixed (2 Rule 1 bug fixes, 1 Rule 3 blocking fix)
**Impact on plan:** All three were necessary for correctness (the copy guard's actual purpose) or to satisfy the plan's own stated verification criteria. No architectural changes, no scope creep beyond the plan's declared guard/e2e/copy-fix surface.

## Issues Encountered
- Two early implementation bugs in the guard tests themselves (a `Regex.scan/3` argument-order inversion from piping the string as the first arg, and a `def `-prefix mismatch in a clause-name lookup) were caught immediately by running the new tests and fixed before committing — not deviations from the plan, just normal test-writing iteration.
- Discovered and confirmed as pre-existing/out-of-scope (logged in `deferred-items.md`, not fixed): 3 Phase-16 `phase16_parity.spec.mjs` theme-toggle e2e failures (mobile-toggle visibility at the config's default viewport), a `ci_policy_contract_test.exs` failure asserting `ROADMAP.md` still contains `"v2.15"` (stale after an earlier, unrelated `.planning/` docs cleanup), a flaky `warning_inventory/capture_parity_test.exs` test (passed on immediate re-run), and a `support_copilot_gallery_test.exs` DB-connection-ownership race in the nested satellite app's background reconciler task. None of these files were touched by any Phase 39 plan (confirmed via `git log`), and none regressed between runs before/after this plan's changes.

## User Setup Required

None - no external service configuration required. Verification required booting the local dev harness (`SCORIA_DB_PORT=55432 mix dev.setup` against the already-running `scoria-main-*-native-postgres-1` container, then `mix phx.server`), which was done locally for this plan's verification only and does not persist as a requirement for future work.

## Next Phase Readiness
- All 4 Phase-39 warning-grade drift guards now exist and are green on arrival (D-05, D-11, D-20 from Plan 03, D-26), locking the phase's conventions against regression.
- The automated flow proof closes out the phase's manual-UAT-avoidance goal — FLOW-01/02/03/04 all have executable coverage (source-scan guards + e2e specs) instead of a checkpoint requiring human verification.
- Phase 41 (hardening) can promote these warning-grade source-scan guards into true `LiveViewTest` DOM assertions per the `PROOF-03` deferrals noted throughout this plan's guard docstrings.
- No blockers.

---
*Phase: 39-component-groups-and-operator-flows*
*Completed: 2026-07-03*

## Self-Check: PASSED

All 6 created/modified files confirmed on disk; all 3 task commits (`cf8a5811`, `1dd0b10f`, `8eb24830`) confirmed in git history.
