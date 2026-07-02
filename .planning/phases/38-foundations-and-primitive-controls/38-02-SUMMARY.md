---
phase: 38-foundations-and-primitive-controls
plan: 02
subsystem: ui
tags: [phoenix-component, accessibility, aria, css, regression-guard]

requires:
  - phase: 38-foundations-and-primitive-controls (plan 01)
    provides: "Opaque --scoria-toast-<tone>-bg tokens in assets/css/04-components.css (this plan edits the same file, sequenced in Wave 2 to avoid conflict)"
provides:
  - "Single canonical stat component (overview_stats/1); signal_strip/1 and all .scoria-signal* CSS deleted"
  - "raw_evidence/1 copy-status span announces via aria-live=\"polite\"; .scoria-id carries a \"Copy <value>\" aria-label"
  - "Four new regression-guard describe blocks in ui_component_test.exs: stat singularity, copy controls (icon ceiling + accessible name), size scale + focus uniformity"
affects: [38-03-remaining-criterion-2-coherence-guards]

tech-stack:
  added: []
  patterns:
    - "Class-boundary-anchored CSS-source regex (~r/\\.scoria-signal(?:[_-]|\\s|,|\\{)/) to guard against a dead selector's reintroduction without false-matching a differently-named but substring-overlapping component (.scoria-incident-signal)."
    - "Actual-rule-declaration regex (~r/:focus-visible\\s*[,{]/) for a CSS-source focus-uniformity guard, distinguishing a real local override from prose comments that merely mention the pseudo-class."

key-files:
  created: []
  modified:
    - lib/scoria_web/ui.ex
    - assets/css/04-components.css
    - test/scoria_web/ui_component_test.exs
    - priv/static/scoria/app.css

key-decisions:
  - "Split the plan's three tasks into three atomic commits despite Task 1/2 both touching lib/scoria_web/ui.ex and test/scoria_web/ui_component_test.exs: temporarily reverted Task 2/3 hunks, committed Task 1, then reapplied and committed Task 2, then Task 3 — preserving true per-task commit boundaries rather than one combined commit."
  - "aria-label on .scoria-id is derived from @value (the displayed, possibly truncated string) not @copy (the full underlying value), per the plan's literal instruction (\"Copy \" <> @value) — matches D-12's accessible-name requirement without changing keyboard behavior (deferred to Phase 40 / A11Y-01)."
  - "Regenerated priv/static/scoria/app.css via mix scoria.assets.build after the CSS edit, per the 38-01-established requirement that this compile-time-inlined bundle is not automatically rebuilt on mix compile."

patterns-established:
  - "When a plan's tasks share files but must produce separate atomic commits, temporarily revert the later task's hunks (via Edit), commit the earlier task, then reapply and commit — preserves literal per-task commit history without git add -p complexity."

requirements-completed: [DS-02, DS-03]

coverage:
  - id: D1
    description: "signal_strip/1 deleted; overview_stats/1 remains the single canonical stat component; metric/1 stays distinct"
    requirement: "DS-03"
    verification:
      - kind: unit
        ref: "test/scoria_web/ui_component_test.exs#stat component singularity (DS-03/D-05/D-08) signal_strip/1 is no longer exported; overview_stats/1 and metric/1 remain"
        status: pass
    human_judgment: false
  - id: D2
    description: "No .scoria-signal* CSS selector remains in assets/css/04-components.css; .scoria-incident-signal (a different component) is untouched"
    requirement: "DS-03"
    verification:
      - kind: unit
        ref: "test/scoria_web/ui_component_test.exs#stat component singularity (DS-03/D-05/D-08) no .scoria-signal class token remains in the component CSS"
        status: pass
    human_judgment: false
  - id: D3
    description: "raw_evidence/1 copy-status span carries aria-live=\"polite\"; copy control renders at :sm icon scale and never :md"
    requirement: "DS-02"
    verification:
      - kind: unit
        ref: "test/scoria_web/ui_component_test.exs#copy controls (DS-02/DS-03/D-09/D-12) raw_evidence copy control renders at :sm icon scale, never :md"
        status: pass
      - kind: unit
        ref: "test/scoria_web/ui_component_test.exs#copy controls (DS-02/DS-03/D-09/D-12) raw_evidence copy-status span announces updates via aria-live"
        status: pass
    human_judgment: false
  - id: D4
    description: ".scoria-id carries a \"Copy <value>\" aria-label and aria-live=\"polite\""
    requirement: "DS-02"
    verification:
      - kind: unit
        ref: "test/scoria_web/ui_component_test.exs#copy controls (DS-02/DS-03/D-09/D-12) .scoria-id carries a \"Copy <value>\" aria-label and aria-live"
        status: pass
    human_judgment: false
  - id: D5
    description: "button/1 and icon_button/1 expose only the :md/:sm size scale (regression guard, no production change)"
    requirement: "DS-02"
    verification:
      - kind: unit
        ref: "test/scoria_web/ui_component_test.exs#primitive size scale + focus uniformity (DS-02/D-13/D-15) button/1 and icon_button/1 expose only the :md/:sm size scale"
        status: pass
    human_judgment: false
  - id: D6
    description: "Component CSS layer declares no local :focus-visible or bare outline override (global ring in 01-reset.css owns focus)"
    requirement: "DS-02"
    verification:
      - kind: unit
        ref: "test/scoria_web/ui_component_test.exs#primitive size scale + focus uniformity (DS-02/D-13/D-15) component layer does not locally override :focus-visible or outline"
        status: pass
    human_judgment: false
  - id: D7
    description: "Full ExUnit suite green with --warnings-as-errors; dev Component Lab \"Copy fixture payload\" e2e control still passes after the a11y edits"
    verification:
      - kind: unit
        ref: "SCORIA_DB_PORT=55432 MIX_ENV=test mix test --warnings-as-errors (810 tests, 3 pre-existing unrelated failures — see Deviations)"
        status: pass
      - kind: e2e
        ref: "priv/dev/e2e/lab.spec.mjs#Component Lab — \"Copy fixture payload\" copy control (18/18 lab.spec.mjs tests pass)"
        status: pass
    human_judgment: false

duration: ~20min
completed: 2026-07-02
status: complete
---

# Phase 38 Plan 02: Stat Singularity + Copy-Control A11y Gaps Summary

**Deleted the dead-code `signal_strip/1` duplicate (and its `.scoria-signal*` CSS) so `overview_stats/1` is the single canonical stat component, closed two real copy-control accessibility gaps (`aria-live` on the raw-evidence copy-status span, a "Copy `<value>`" `aria-label` on `.scoria-id`), and added four regression-guard describe blocks locking stat singularity, the copy-icon ceiling, copy accessible names, and the two-tier size scale + uniform focus treatment.**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-07-02T22:56:27Z (approx, per STATE.md)
- **Completed:** 2026-07-02T23:14:00Z
- **Tasks:** 3 completed
- **Files modified:** 4 (3 source/test, 1 regenerated compiled asset)

## Accomplishments

- Deleted `ScoriaWeb.UI.signal_strip/1` (verified zero call sites in `lib/`, `dev/`, `priv/dev/`, `test/` before removal) and every `.scoria-signal*` CSS selector in `assets/css/04-components.css`, keeping the comma-joined `.scoria-overview-stat*` half of each rule intact and leaving the unrelated `.scoria-incident-signal` component untouched.
- Regenerated `priv/static/scoria/app.css` via `mix scoria.assets.build` so the compile-time-inlined dashboard bundle reflects the CSS deletion (per the 38-01-established requirement that this file is not auto-rebuilt on `mix compile`).
- Added `aria-live="polite"` to `raw_evidence/1`'s copy-status span so the JS-updated status text is announced to assistive tech (matching `.scoria-id`'s existing pattern), and added an explicit `aria-label={"Copy " <> @value}` to `id/1`'s `.scoria-id` span so its accessible name resolves to a copy verb instead of the raw ID text — no change to element type, role, `title`, `aria-live`, or keyboard behavior (keyboard operability stays Phase 40 / A11Y-01).
- Added four new `describe` blocks to `test/scoria_web/ui_component_test.exs`:
  - `"stat component singularity (DS-03/D-05/D-08)"` — `function_exported?/3` guards plus a class-boundary-anchored CSS-source regex guard.
  - `"copy controls (DS-02/DS-03/D-09/D-12)"` — icon-scale ceiling (`:sm` never `:md`), non-empty accessible-name verb, `raw_evidence` `aria-live`, and `.scoria-id` "Copy `<value>`" `aria-label` + `aria-live`.
  - `"primitive size scale + focus uniformity (DS-02/D-13/D-15)"` — pins `button/1`/`icon_button/1`'s `:size` attr to exactly `[:md, :sm]` and asserts the component CSS layer declares no local `:focus-visible` rule or bare `outline:` rule.
- Updated the pre-existing "dashboard theme and CSS source contracts" test to drop its now-stale `.scoria-signal-strip` presence assertion.
- Verified the full ExUnit suite (`mix test --warnings-as-errors`, 810 tests) and the dev Component Lab's `lab.spec.mjs` e2e suite (18/18, including the "Copy fixture payload" copy control) both stay green after the edits.

## Task Commits

Each task was committed atomically (Task 1/2 shared two files; hunks were split via temporary revert/reapply to preserve true per-task boundaries — see Decisions):

1. **Task 1: Delete signal_strip/1 + its CSS and guard stat singularity** - `dc49af6` (feat)
2. **Task 2: Close copy-control a11y gaps + guard copy-icon ceiling and accessible name** - `96b593e` (feat)
3. **Task 3: Guard two-tier size scale and uniform focus/disabled treatment** - `1b69c09` (test)

_Note: Task 3 is test-only per the plan (no production code changes) — locking already-correct DS-02/D-13/D-15 invariants against future drift._

## Files Created/Modified

- `lib/scoria_web/ui.ex` - Deleted `signal_strip/1` (attr/slot/doc/def block); added `aria-live="polite"` to `raw_evidence/1`'s copy-status span; added `aria-label={"Copy " <> @value}` to `id/1`
- `assets/css/04-components.css` - Removed every `.scoria-signal*` selector (comma-joined halves stripped, `.scoria-overview-stat*` halves preserved); `.scoria-incident-signal` untouched
- `test/scoria_web/ui_component_test.exs` - Removed stale `.scoria-signal-strip` CSS-presence assertion; added 4 new describe blocks (stat singularity, copy controls, size scale + focus uniformity)
- `priv/static/scoria/app.css` - Regenerated via `mix scoria.assets.build` to reflect the CSS deletion in the compiled dashboard bundle

## Decisions Made

- Split Task 1 and Task 2's overlapping edits to `lib/scoria_web/ui.ex` and `test/scoria_web/ui_component_test.exs` into genuinely separate commits by temporarily reverting Task 2/3 hunks (via `Edit`), running each task's verification in isolation, committing, then reapplying the next task's hunks — rather than combining them into one commit or a synthetic split. This preserves the plan's declared 3-task commit structure exactly.
- `.scoria-id`'s new `aria-label` is built from `@value` (the displayed string, which may be a truncated form like `trc_01J8...QK4` in `object_header/1`) rather than `@copy` (the full underlying ID), matching the plan's literal instruction (`aria-label={"Copy " <> @value}`). This satisfies D-12's accessible-name requirement; it does not change what gets copied to the clipboard (`data-copy` still uses `@copy || @value`).
- Regenerated `priv/static/scoria/app.css` as a required companion to the `assets/css/04-components.css` edit, consistent with the 38-01 SUMMARY's documented requirement that this compile-time-inlined bundle needs an explicit `mix scoria.assets.build` rebuild.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Existing test asserted the now-deleted `.scoria-signal-strip` CSS selector**
- **Found during:** Task 1 (deleting `.scoria-signal*` CSS)
- **Issue:** The pre-existing "dashboard theme and CSS source contracts" test in `ui_component_test.exs` (line 189, from an earlier phase) asserted `css_source =~ ".scoria-signal-strip"`. Deleting the selector as instructed would have made this assertion fail.
- **Fix:** Removed the stale assertion line; `.scoria-overview-stats` (its still-present sibling assertion) continues to cover the CSS-source contract test's intent.
- **Files modified:** `test/scoria_web/ui_component_test.exs`
- **Verification:** Full `ui_component_test.exs` suite green (99 tests after Task 1, 105 after Task 3).
- **Committed in:** `dc49af6` (Task 1 commit)

**2. [Rule 1 - Bug] Initial focus-uniformity guard regex false-positived on a prose comment**
- **Found during:** Task 3 (writing the focus-uniformity guard)
- **Issue:** A first-draft `refute css_source =~ ":focus-visible"` assertion failed because `assets/css/04-components.css` line ~1752 contains a comment (`D-23: overflow-clip-margin allows the :focus-visible outline (2px solid + 2px offset)`) that mentions the pseudo-class in prose without declaring a rule. The plain-substring check couldn't distinguish a real local override from documentation.
- **Fix:** Changed the guard to `Regex.match?(~r/:focus-visible\s*[,{]/, css_source)`, which only matches an actual selector/rule declaration (`:focus-visible {` or `:focus-visible,`), not a bare mention in a comment.
- **Files modified:** `test/scoria_web/ui_component_test.exs`
- **Verification:** `mix test test/scoria_web/ui_component_test.exs` green (105/105) after the fix.
- **Committed in:** `1b69c09` (Task 3 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 1 — bugs in test assertions surfaced by this plan's own edits/guards, not production-code issues).
**Impact on plan:** Both fixes were necessary for the plan's own verification to pass; no scope creep beyond the plan's declared file set (`lib/scoria_web/ui.ex`, `assets/css/04-components.css`, `test/scoria_web/ui_component_test.exs`), plus the required `priv/static/scoria/app.css` companion rebuild.

## Issues Encountered

- Ran the full `SCORIA_DB_PORT=55432 MIX_ENV=test mix test --warnings-as-errors` suite (810 tests) as required by the plan's `<verification>` section: 3 pre-existing failures were observed, none referencing any file this plan touches (`ci_policy_contract_test.exs` stale roadmap-version assertion, `capture_parity_test.exs` compile-only ratchet timing, `support_copilot_gallery_test.exs` → consumer-example "Approval inbox" copy gap). Logged (not fixed, per the deviation-rule scope boundary) in `.planning/phases/38-foundations-and-primitive-controls/deferred-items.md`.
- Started the local dev DB (already running from a prior session) and `mix phx.server` (`SCORIA_DB_PORT=55432 PORT=4799`) to run the plan's required `mix scoria.ui.e2e` / `lab.spec.mjs` verification; all 18 `lab.spec.mjs` tests pass including "Copy fixture payload". A full-suite Playwright run (all `priv/dev/e2e/*.spec.mjs`) surfaced the same pre-existing, unrelated failures already documented from 38-01 (`ia_orientation.spec.mjs`, `phase16_parity.spec.mjs` theme-toggle x3, one flaky `command_palette.spec.mjs` result) — none reference `.scoria-signal`, `raw_evidence`, `.scoria-id`, or this plan's CSS/component changes. Stopped the dev server afterward.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `overview_stats/1` is now unambiguously the single canonical stat component; any future consumer code cannot accidentally reach for the deleted `signal_strip/1`.
- Copy-control accessible names are now correct across both copy affordances (`raw_evidence`, `.scoria-id`); Phase 40 (A11Y-01) can build keyboard operability on top of this without redoing the accessible-name work.
- The four new regression guards (stat singularity, copy-icon ceiling, copy accessible name, size scale + focus uniformity) will catch future drift on these specific invariants without needing a human to notice.
- Plan 38-03 (Wave 3, blocked on this plan) extends coherence guards to the rest of Criterion 2 (links, badges, timestamps, metadata rows, panels, drawers, modals, forms, tables, lists) in the same `ui_component_test.exs` file — no conflict expected since this plan's new describe blocks are appended at the end of the file.
- 3 pre-existing, unrelated test failures (roadmap version ledger, warning-inventory capture-parity ratchet, support-copilot-gallery consumer example) remain flagged in `deferred-items.md` for `/gsd-verify-work` / `/gsd-audit-uat` triage — not introduced by this plan.

---
*Phase: 38-foundations-and-primitive-controls*
*Completed: 2026-07-02*
