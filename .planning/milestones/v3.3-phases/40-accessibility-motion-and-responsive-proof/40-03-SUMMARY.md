---
phase: 40-accessibility-motion-and-responsive-proof
plan: 03
subsystem: ui
tags: [phoenix-liveview, focus-management, accessibility, playwright, focus_wrap, a11y]

# Dependency graph
requires:
  - phase: 40-01
    provides: "priv/dev/e2e/lib/boxes_intersect.mjs shared geometry primitive; @axe-core/playwright pinned devDependency"
provides:
  - "ui.ex modal/1 and drawer/1: Phoenix.Component.focus_wrap/1 trap + JS.focus_first()/push_focus()/pop_focus() restore wiring — zero new attrs/slots"
  - "Every enumerated drawer/modal opener call site composes JS.push_focus() (approval_inbox_component.ex, approvals_live/index.ex, connectors_live/index.ex, release_workbench_live.ex, workflow_detail_panel_component.ex)"
  - "priv/dev/e2e/drawer_focus.spec.mjs — tab-in/trap/Esc-restore/SC 2.4.11 (throwing) + D-13 live-patch survival (non-throwing collector)"
  - "priv/dev/e2e/modal_focus.spec.mjs — tab-in/trap/Esc-restore against the release-workbench reject modal (throwing)"
  - "SCORIA_E2E_PROMPT_RELEASE_ID demo-env resolution in lib/mix/tasks/scoria.ui.e2e.ex (mirrors SCORIA_E2E_REPLAY_RUN_ID)"
  - "Bumped mix scoria.ui.e2e's pending-approval fixture floor 5 -> 10"
affects: [40-04-axe-scan-and-responsive-scan, 40-05-consistency-sweep, 41-hardening]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "D-10 focus fix idiom: focus_wrap/1 nested INSIDE the existing role=dialog element at a distinct #{id}-focus id (never reusing the shell's own id — avoids a real DOM-id collision); phx-mounted={JS.focus_first()} on the wrap moves focus in on open; phx-remove={JS.pop_focus()} on the OUTER :if={@show} shell restores focus once the element leaves the DOM, regardless of which of the three dismiss paths (close button/scrim/Escape) triggered it — one central spot, no per-dismiss-path wiring needed."
    - "Opener wiring: every phx-click that shows a drawer/modal composes JS.push_focus() |> JS.push(event_name), keeping any existing phx-value-* attributes untouched (LiveView reads phx-value-* from the DOM element regardless of whether phx-click is a plain string or a JS command)."
    - "e2e focusable-element scanning must scope EVERY comma-clause of a multi-selector string to its container (`${container} ${clause}` per clause, joined by ', ') — string-concatenating a container prefix onto only the first clause of a selector list silently unscopes the rest, matching unrelated elements elsewhere on the page."
    - "e2e trap assertions poll the post-keypress activeElement (expect.poll, not a single-shot read) — the FocusWrap client hook's wrap-around redirect is synchronous but can lose a race to a bare synchronous check under heavy parallel Playwright worker CPU contention (confirmed as a suite-wide characteristic, not a Task 1 bug, by an untouched command_palette.spec.mjs test showing the identical symptom in the same run)."
    - "Deterministic e2e deep-links to seeded objects go through lib/mix/tasks/scoria.ui.e2e.ex's resolve_demo_env, querying dev_seed.exs's STABLE sentinel ids (entity_id \"00000000-...0001\"/version 1 for the demo prompt release) rather than hardcoding a UUID that changes per fresh seed run."

key-files:
  created:
    - priv/dev/e2e/drawer_focus.spec.mjs
    - priv/dev/e2e/modal_focus.spec.mjs
    - .planning/phases/40-accessibility-motion-and-responsive-proof/deferred-items.md
  modified:
    - lib/scoria_web/ui.ex
    - lib/scoria_web/components/approval_inbox_component.ex
    - lib/scoria_web/components/workflow_detail_panel_component.ex
    - lib/scoria_web/live/approvals_live/index.ex
    - lib/scoria_web/live/connectors_live/index.ex
    - lib/scoria_web/live/prompt_live/release_workbench_live.ex
    - lib/mix/tasks/scoria.ui.e2e.ex
    - test/scoria_web/live/approvals_live_integration_test.exs
    - test/scoria_web/live/approvals_live_test.exs
    - test/scoria_web/live/connectors_live_test.exs
    - test/scoria_web/live/workflow_live_test.exs
    - priv/dev/e2e/ia_orientation.spec.mjs
    - priv/dev/e2e/uat.spec.mjs

key-decisions:
  - "Used phx-remove={JS.pop_focus()} on the outer :if={@show} shell instead of wrapping on_dismiss in a JS command chain — this keeps every existing phx-click={@on_dismiss}/phx-window-keydown={@on_dismiss} attribute byte-identical (all pre-existing ui_component_test.exs assertions on literal on_dismiss strings stay green untouched) while still firing pop_focus() on every dismiss path, since all three (close button, scrim click, Escape) ultimately flip @show to false and remove the same DOM node."
  - "Removed modal/1's old bare `autofocus` attribute on the close button, replacing it with phx-mounted={JS.focus_first()} on the focus_wrap — one canonical tab-in mechanism for both modal/1 and drawer/1 instead of two racing ones (native autofocus firing on DOM insertion vs. the LiveView hook's async focus_first)."
  - "dataset_live/index.ex's promote drawer is opened purely via a URL query param from cross-page navigation (review_queue_live.ex/workflow_live/show.ex link into it with ?promote=...) — there is no local phx-click opener in that file to attach JS.push_focus() to, and review_queue_live.ex is out of this plan's files_modified. The ui.ex focus_wrap fix still gives it trap/tab-in; restore-to-a-cross-page-trigger is out of scope (documented, not a stub — it degrades to no-op pop_focus, not a regression from the prior no-trap-at-all state)."
  - "Added JS.push_focus() at workflow_detail_panel_component.ex's 'Promote Trace to Draft Dataset' button — the real click site for workflow_live/show.ex's promote-modal — even though that file is not in the plan's files_modified list. Without it, restore for that modal would land on <body>, defeating D-10's purpose. (Rule 2/3 deviation, documented below.)"
  - "SC 2.4.11 in drawer_focus.spec.mjs targets the raw-evidence copy control (opened via its <summary> first, since it defaults collapsed) rather than the Approve/Reject buttons themselves — those buttons ARE the sticky footer's own content, so a boxesIntersect(button, footer) check would trivially always be true (child-inside-parent) and prove nothing. The copy control sits after the sticky footer in scroll order, so scrolling it into view exercises the real SC 2.4.11 occlusion risk D-11/D-17 assign to this spec."
  - "D-13's live-patch simulation drives a REAL cross-tab decision on a DIFFERENT pending approval (not a mocked/synthetic patch) since no in-app action can synthesize a PubSub broadcast without either creating or deciding a real approval, and creating one isn't reachable via the dashboard UI. Bumped the shared pending-approval fixture floor 5->10 (Rule 3) since this adds one more destructive consumer to an already-tight shared pool used by 2 other pre-existing spec files."

requirements-completed: [A11Y-01]

coverage:
  - id: D1
    description: "modal/1 and drawer/1 gain real focus trap (focus_wrap at a distinct #{id}-focus id, nested inside role=dialog) + tab-in (phx-mounted={JS.focus_first()}) + restore-on-close (phx-remove={JS.pop_focus()} on the outer shell) with zero new attrs/slots and zero new Hex deps"
    requirement: "A11Y-01"
    verification:
      - kind: unit
        ref: "mix test test/scoria_web/a11y_structural_guard_test.exs test/scoria_web/ui_component_test.exs (134 tests, 0 failures)"
        status: pass
      - kind: unit
        ref: "mix compile --warnings-as-errors (clean)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every enumerated drawer/modal opener call site (approval row select x2, decision-modal approve/reject x2, runtime/connector drawer opens x3, promote-modal open x1, release approve/reject x2) composes JS.push_focus() so the trigger is captured before the overlay mounts"
    requirement: "A11Y-01"
    verification:
      - kind: unit
        ref: "grep -rn 'push_focus' lib/scoria_web/ — 10 call sites across 6 files, cross-checked against grep -rn '<\\.drawer\\b|<\\.modal\\b' (7 overlay instances; dataset_live's is documented as intentionally unwired — no local opener exists)"
        status: pass
      - kind: integration
        ref: "test/scoria_web/live/{approvals_live,approvals_live_integration,connectors_live,workflow_live}_test.exs — 98 tests, 0 failures (4 selectors updated to match on phx-value-* instead of the now-JS-command phx-click value)"
        status: pass
    human_judgment: false
  - id: D3
    description: "drawer_focus.spec.mjs proves tab-in, bidirectional trap-wrap, Esc-closes-and-restores-to-opener, and SC 2.4.11 rect non-overlap against the real approval decision drawer — all throwing assertions, fix-and-assert atomic with Task 1"
    requirement: "A11Y-01"
    verification:
      - kind: e2e
        ref: "npx playwright test drawer_focus.spec.mjs (scoped per-task run against a running dev server) — 5/5 passed, repeated 3x clean"
        status: pass
      - kind: e2e
        ref: "mix scoria.ui.e2e (full lane, 6-worker parallel) — drawer_focus.spec.mjs green across 2 consecutive clean runs after the expect.poll hardening"
        status: pass
    human_judgment: false
  - id: D4
    description: "D-13 live-patch focus-survival check on the drawer is a WARNING-GRADE non-throwing collector (console.warn + testInfo.attach), never expect()/test.fail()/expect.soft, per D-04"
    requirement: "A11Y-01"
    verification:
      - kind: e2e
        ref: "priv/dev/e2e/drawer_focus.spec.mjs — 'D-13 (warning-grade collector)' test body contains zero throwing assertions on the live-patch outcome (grep confirms no test.fail()/expect.soft usage anywhere in the file)"
        status: pass
    human_judgment: false
  - id: D5
    description: "modal_focus.spec.mjs proves tab-in, bidirectional trap-wrap, and Esc-closes-and-restores-to-opener against the release-workbench reject-release modal — all throwing, no warning-grade collector (D-13's live-patch risk is drawer-specific)"
    requirement: "A11Y-01"
    verification:
      - kind: e2e
        ref: "npx playwright test modal_focus.spec.mjs (scoped per-task run) — 3/3 passed, repeated 3x clean"
        status: pass
      - kind: e2e
        ref: "mix scoria.ui.e2e (full lane) — modal_focus.spec.mjs green across 2 consecutive clean runs"
        status: pass
    human_judgment: false

duration: 50min
completed: 2026-07-03
status: complete
---

# Phase 40 Plan 03: Drawer + Modal Focus Trap and Restore Summary

**`focus_wrap`/`push_focus`/`pop_focus` wiring closes the verified A11Y-01 keyboard-operability gap on `drawer/1` and `modal/1` — the $10k-refund approval decision drawer now traps and restores focus like the command palette already did, proven by two new fix-and-assert-atomic Playwright specs plus a non-throwing D-13 live-patch collector.**

## Performance

- **Duration:** ~50 min
- **Tasks:** 3 completed
- **Files created:** 3 (`drawer_focus.spec.mjs`, `modal_focus.spec.mjs`, `deferred-items.md`)
- **Files modified:** 13 (7 runtime/lib files, 6 test/e2e files)

## Accomplishments

- **`ui.ex` `modal/1` and `drawer/1` get real focus trap + restore.** Both wrap their panel body in `Phoenix.Component.focus_wrap/1` at a distinct `#{id}-focus` id nested inside the existing `role="dialog"` element (never reusing the shell's own id). `phx-mounted={JS.focus_first()}` on the wrap moves focus inside on open; `phx-remove={JS.pop_focus()}` on the outer `:if={@show}` shell restores focus to whichever opener called `JS.push_focus()`, firing centrally on any of the three dismiss paths (close button, scrim click, Escape) since all three ultimately remove that same DOM node. Zero new attrs, zero new slots, zero new Hex deps.
- **Every enumerated opener call site now issues `JS.push_focus()`** before pushing its open event: `approval_inbox_component.ex` (row select, desktop + mobile), `approvals_live/index.ex` (decision-modal approve/reject), `connectors_live/index.ex` (runtime drawer + connector drawer, desktop + mobile), `release_workbench_live.ex` (approve/reject release modals), and `workflow_detail_panel_component.ex` (the promote-modal's real click site — added even though that file wasn't in the plan's declared scope, since without it restore would land on `<body>`).
- **`drawer_focus.spec.mjs`** proves tab-in, bidirectional Tab-wrap (never landing on the background), Esc-close-and-restore-to-opener, and SC 2.4.11 (a focused control reachable after the sticky `.scoria-approval-actions` footer is not covered by it) — all throwing assertions against the real seeded approval drawer. Its D-13 live-patch survival check drives a real cross-tab decision on a *different* pending approval and only warns (never fails) if this drawer's focus doesn't survive the resulting re-render.
- **`modal_focus.spec.mjs`** proves the same tab-in/trap/Esc/restore contract against the release workbench's reject-release confirm modal, deep-linked deterministically via a new `SCORIA_E2E_PROMPT_RELEASE_ID` env var resolved from `dev_seed.exs`'s stable sentinel draft-template id (mirroring the existing `SCORIA_E2E_REPLAY_RUN_ID` idiom).
- Fixed 4 pre-existing e2e selectors (`uat.spec.mjs`, `ia_orientation.spec.mjs`) that matched the literal `phx-click` event-name string, now broken because `phx-click` on openers carries a JS-command payload after Task 1 — real regressions Task 1 caused that ExUnit/LiveViewTest cannot see (no JS engine).
- Hardened both new specs' trap assertions to poll the post-keypress `activeElement` (`expect.poll`) instead of a single synchronous read, after observing a transient race under the full 6-worker parallel suite — confirmed as a suite-wide CPU-contention characteristic (an untouched `command_palette.spec.mjs` test showed the identical symptom in the same run), not a Task 1 logic bug.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add focus trap + restore to drawer/1 and modal/1 (ui.ex + all opener call sites)** - `cbe12883` (feat)
2. **Task 2: drawer_focus.spec.mjs — tab-in / trap / Esc / restore / SC 2.4.11 + live-patch collector** - `93649b31` (test)
3. **Task 3: modal_focus.spec.mjs — tab-in / trap / Esc / restore** - `11b1e26a` (test)

**Plan metadata:** (this commit, see final_commit step)

## Files Created/Modified

- `lib/scoria_web/ui.ex` - `modal/1`/`drawer/1` focus_wrap + focus_first/pop_focus wiring
- `lib/scoria_web/components/approval_inbox_component.ex` - row-select opener push_focus (desktop + mobile)
- `lib/scoria_web/components/workflow_detail_panel_component.ex` - promote-modal opener push_focus (real click site, out-of-declared-scope fix)
- `lib/scoria_web/live/approvals_live/index.ex` - decision-modal approve/reject opener push_focus
- `lib/scoria_web/live/connectors_live/index.ex` - runtime/connector drawer opener push_focus (desktop + mobile)
- `lib/scoria_web/live/prompt_live/release_workbench_live.ex` - approve/reject release modal opener push_focus
- `lib/mix/tasks/scoria.ui.e2e.ex` - `SCORIA_E2E_PROMPT_RELEASE_ID` resolution; pending-approval floor 5→10
- `priv/dev/e2e/drawer_focus.spec.mjs` - new: drawer keyboard-driving proof + D-13 collector
- `priv/dev/e2e/modal_focus.spec.mjs` - new: release-workbench modal keyboard-driving proof
- `priv/dev/e2e/ia_orientation.spec.mjs` / `priv/dev/e2e/uat.spec.mjs` - fixed 4 selectors broken by Task 1's JS-command phx-click
- `test/scoria_web/live/{approvals_live,approvals_live_integration,connectors_live,workflow_live}_test.exs` - fixed 4 selectors, same cause
- `.planning/phases/40-accessibility-motion-and-responsive-proof/deferred-items.md` - new: two pre-existing, out-of-scope e2e flakes logged (not fixed)

## Decisions Made

See `key-decisions` in frontmatter for the full list. Summary of the most load-bearing ones:

- `phx-remove={JS.pop_focus()}` on the outer shell (not wrapping `on_dismiss`) keeps every pre-existing `on_dismiss` string attribute byte-identical, so `ui_component_test.exs`'s literal-string assertions needed zero changes.
- One canonical tab-in mechanism (`phx-mounted={JS.focus_first()}`) replaces the old bare `autofocus` on modal's close button, so drawer and modal share identical behavior instead of racing two mechanisms.
- SC 2.4.11 targets the raw-evidence copy control (after opening its `<summary>`), not the Approve/Reject buttons — the latter live *inside* the sticky footer, so a naive occlusion check against their own parent would be vacuously true.
- D-13's "simulated live patch" is a real cross-tab approval decision (no in-app action can synthesize a PubSub broadcast without a genuine backend state change), gated by a bumped fixture floor.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added `JS.push_focus()` at `workflow_detail_panel_component.ex`'s promote-modal opener**
- **Found during:** Task 1 (re-grepping the full opener enumeration per the plan's explicit instruction)
- **Issue:** `workflow_live/show.ex`'s promote-modal (`<.modal id="promote-modal">`) is opened by a button in `workflow_detail_panel_component.ex`, a file NOT in the plan's `files_modified` list. Without wiring `JS.push_focus()` at the actual click site, restore-on-close for this modal would land on `<body>` instead of the trigger — defeating D-10's stated purpose for this surface.
- **Fix:** Added `alias Phoenix.LiveView.JS` and composed `JS.push_focus() |> JS.push("open_promote_modal")` onto the existing `phx-click`.
- **Files modified:** `lib/scoria_web/components/workflow_detail_panel_component.ex`
- **Verification:** `mix compile --warnings-as-errors` clean; `mix test test/scoria_web/live/workflow_live_test.exs` green (after the companion selector fix below).
- **Committed in:** `cbe12883` (Task 1 commit)

**2. [Rule 1 - Bug] Fixed 4 e2e/ExUnit selectors broken by Task 1's JS-command `phx-click`**
- **Found during:** Task 1 verification (ExUnit) and Task 2 verification (live Playwright run)
- **Issue:** Several existing tests selected drawer/modal openers by their literal `phx-click="event_name"` string value (`test/scoria_web/live/{approvals_live,approvals_live_integration,connectors_live,workflow_live}_test.exs`, `priv/dev/e2e/{uat,ia_orientation}.spec.mjs`). Since Task 1 wraps those same `phx-click` attributes in `JS.push_focus() |> JS.push(...)`, the rendered attribute value became a JSON-encoded JS-command payload, so these literal-string selectors stopped matching.
- **Fix:** Updated each selector to match on a stable alternative (accessible name via `getByRole`, or the still-untouched `phx-value-*` attribute) instead of the literal `phx-click` string.
- **Files modified:** the 4 ExUnit test files above, plus `priv/dev/e2e/uat.spec.mjs` and `priv/dev/e2e/ia_orientation.spec.mjs`.
- **Verification:** ExUnit — `mix test` on the 4 files, 98 tests 0 failures. e2e — `mix scoria.ui.e2e` full lane, both files' relevant tests green.
- **Committed in:** `cbe12883` (ExUnit fixes) and `93649b31` (e2e spec fixes)

**3. [Rule 3 - Blocking] Bumped `mix scoria.ui.e2e`'s pending-approval fixture floor from 5 to 10**
- **Found during:** Task 2 full-suite verification
- **Issue:** `drawer_focus.spec.mjs`'s D-13 collector adds one more destructive approval decision to a shared tenant-scoped fixture pool already consumed by `uat.spec.mjs` (3 decisions) and `ia_orientation.spec.mjs` (1 decision) across concurrently-running Playwright workers, tightening an already-thin margin.
- **Fix:** Raised `@pending_approval_floor` in `lib/mix/tasks/scoria.ui.e2e.ex` from 5 to 10, with a comment explaining the accounting.
- **Files modified:** `lib/mix/tasks/scoria.ui.e2e.ex`
- **Verification:** `mix scoria.ui.e2e` full lane — fixture count confirmed at 10 pre-run; two consecutive clean full-suite runs.
- **Committed in:** `93649b31` (Task 2 commit)

**4. [Rule 1 - Bug] Fixed an unscoped CSS-selector-list bug in the new e2e specs' focusable-element scan**
- **Found during:** Task 2 (first live run of `drawer_focus.spec.mjs`'s trap test)
- **Issue:** `` `${containerSelector} ${FOCUSABLE_SELECTOR}` `` where `FOCUSABLE_SELECTOR` is a comma-separated selector list only scopes the FIRST clause to the container; the remaining comma-clauses become unscoped/global selectors, matching unrelated elements anywhere on the page (observed: the drawer's computed "first focusable" resolved to the page's `⌘K` command-palette button).
- **Fix:** Added `scopedFocusableSelector()`, which maps the container prefix onto every comma-clause individually before joining.
- **Files modified:** `priv/dev/e2e/drawer_focus.spec.mjs` (introduced), reused as-is in `priv/dev/e2e/modal_focus.spec.mjs`
- **Verification:** repeated clean Playwright runs (5/5 and 3/3) after the fix.
- **Committed in:** `93649b31` (Task 2 commit)

---

**Total deviations:** 4 auto-fixed (1 missing-critical opener wiring, 1 bug-class selector fix applied across 6 files, 1 blocking fixture-floor bump, 1 bug-class CSS-selector-scoping fix in new spec code).
**Impact on plan:** All four are necessary for the fix to actually work end-to-end and for the new specs to pass deterministically. No scope creep — each traces directly to making D-10/D-11 literally true, not new functionality.

## Issues Encountered

- **Pre-existing `phase16_parity.spec.mjs` MOTION-04 theme-toggle flake** (3 tests): unrelated selector-visibility bug (`.first()` on a DOM-order list instead of `.filter({ visible: true })`), present before this plan and untouched by it. Logged to `deferred-items.md`, not fixed (out of `files_modified` scope).
- **Cross-spec-file parallel-worker race over the shared pending-approval pool**: multiple spec files independently grab "first pending row" with no cross-file coordination; under the full suite's default 6-worker parallelism this occasionally raced (observed once on `uat.spec.mjs`'s "manual dismiss" test). Confirmed pre-existing (both colliding spec files predate this plan) via clean, deterministic `--workers=1` reruns. Partially mitigated (fixture-floor bump); full fix (per-worker-unique fixture assignment or a serial project split) is out of this plan's scope. Logged to `deferred-items.md`.
- **3 unrelated full-suite (`mix test`) failures** observed in a full local run: `Scoria.CiPolicyContractTest` (a stale `"v2.15"` roadmap-content assertion), `Scoria.WarningInventory.CaptureParityTest` (a warning-inventory injected-test check), and `Scoria.SupportCopilotGalleryTest`/`SupportCopilotWeb.OrchestratorProducerTest` (a stale `"Approval inbox"` copy-text assertion on `/scoria/approvals`, which now renders "Approvals"/"Approval actions" per Phase 38/39 copy work). None reference focus, `ui.ex`, drawer/modal, or any file this plan touched — confirmed pre-existing and out of scope. Not logged to `deferred-items.md` (not discovered via this plan's own verify commands, and unrelated to the phase's A11Y/MOTION/RESP scope), but noted here for visibility.

## User Setup Required

None — all changes are internal LiveView/e2e wiring; no new Hex dependency, no environment variable required for normal operation (the new `SCORIA_E2E_PROMPT_RELEASE_ID` is dev-e2e-only, resolved automatically by `mix scoria.ui.e2e`).

## Next Phase Readiness

- The single most load-bearing Phase 40 fix (D-10) is live and proven: the approval decision drawer and confirm modals trap and restore focus like the command palette already did.
- Plans 40-04 (axe scan + responsive scan) and 40-05 (consistency sweep) can proceed without blockers from this plan — no locked-vocabulary change, no new Hex dep, `ds06_drift_guard_test.exs`/`token_contrast_guard_test.exs` untouched.
- Two deferred items are logged in `deferred-items.md` for Phase 41 or a dedicated follow-up: the `phase16_parity.spec.mjs` theme-toggle selector bug, and the cross-spec-file parallel-worker fixture race. Neither blocks this plan's completion per its own verification tiering (scoped per-task Playwright run is the primary gate; full `mix scoria.ui.e2e` is the broader per-wave sampling tier).
- `dataset_live/index.ex`'s promote drawer has no local opener to wire `push_focus()` to (it opens via cross-page URL param navigation) — documented as an accepted, non-regressing scope boundary, not a stub.

---
*Phase: 40-accessibility-motion-and-responsive-proof*
*Completed: 2026-07-03*

## Self-Check: PASSED

All created/modified files verified present on disk (11/11 checked). All 3 task commit hashes
(`cbe12883`, `93649b31`, `11b1e26a`) verified present in `git log --all`.
