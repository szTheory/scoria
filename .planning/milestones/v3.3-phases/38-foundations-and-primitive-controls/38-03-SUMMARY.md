---
phase: 38-foundations-and-primitive-controls
plan: 03
subsystem: ui
tags: [phoenix-component, accessibility, aria, css, regression-guard, source-scan]

requires:
  - phase: 38-foundations-and-primitive-controls (plan 02)
    provides: "Four regression-guard describe blocks in ui_component_test.exs (stat singularity, copy controls, size scale + focus uniformity), sequenced in Wave 3 to avoid a shared-file conflict."
provides:
  - "Two new regression-guard describe blocks in ui_component_test.exs closing out ROADMAP Criterion 2's full primitive enumeration: 'primitive accessible-name + structure coverage' (modal, drawer, field, table, badge, time, evidence_rows) and 'primitive spacing / variant / link-token coherence' (no ad-hoc pixel styles, locked variant/tone/size vocabularies, --scoria-link token consumption, spacing-token spot-check across panel/drawer/modal/form-section/table/evidence-rows/list)."
affects: [39-page-flows, 40-a11y-motion-responsive-sweep]

tech-stack:
  added: []
  patterns:
    - "Default-value-anchored regex to disambiguate two attr(:variant, ...) declarations sharing an identical values: list (button/1 defaults :primary, icon_button/1 defaults :ghost) without needing to match forward to the def boundary."
    - "Multi-line-tolerant attr(:tone, ...) regex (~r/attr\\(:tone,\\s*:atom,?\\s*(?:\\n\\s*default: :\\w+,)?\\s*values:\\s*\\[([^\\]]*)\\]/) that captures both the single-line toast/1 form and the newline-wrapped evidence_section/1 form, then parses the captured atom list and asserts it is a subset of the locked 7-atom tone vocabulary — a non-empty-list assertion pins the regex itself against silently matching zero attrs after a future refactor."
    - "Style-attribute-scoped pixel regex (~r/style=(?:\"|\\{\")[^\"]*?\\d+px/) that only flags a literal pixel value appearing inside a style attribute's source text, correctly ignoring modal/1's style={\"max-width: #{@max_width}\"} (a dynamic interpolation whose 560px default lives in a separate attr(...) line, not in the style= literal itself)."

key-files:
  created: []
  modified:
    - test/scoria_web/ui_component_test.exs

key-decisions:
  - "Verified every one of the plan's 'already coherent' claims (modal/drawer role=dialog+aria-labelledby+aria-labelled close button, field <label for>, table th/pagination, badge visible text, time datetime+title, evidence_rows dl/dt/dd, zero pixel-valued inline styles, locked variant/tone/size vocabularies, --scoria-link token consumption, spacing-token usage across all seven named component rules) against the live source with standalone Elixir scripts BEFORE writing the ExUnit assertions, to avoid guessing regex shapes against a 1447-line file. Both tasks landed as pure guards-only commits with zero lib/scoria_web/ui.ex changes, confirming the plan's RESEARCH grounding was accurate."
  - "Skipped starting a local Phoenix dev server to re-run `mix scoria.ui.e2e` for this plan: Task 1/2 made zero production-code or CSS changes (guards-only test additions), so the rendered DOM is byte-identical to what 38-02 already verified end-to-end. Re-running Playwright against an unchanged UI surface would add ~5min of server lifecycle for zero incremental verification signal. Documented here rather than silently skipped."

requirements-completed: [DS-02, DS-03]

coverage:
  - id: D1
    description: "modal/1 and drawer/1 expose role=dialog, aria-labelledby, and an aria-labelled close control (accessible-name coverage guard)"
    requirement: "DS-02"
    verification:
      - kind: unit
        ref: "test/scoria_web/ui_component_test.exs#primitive accessible-name + structure coverage (DS-02/DS-03/Criterion 2) modal exposes role=dialog, aria-labelledby, and an aria-labelled close control"
        status: pass
      - kind: unit
        ref: "test/scoria_web/ui_component_test.exs#primitive accessible-name + structure coverage (DS-02/DS-03/Criterion 2) drawer exposes role=dialog, aria-labelledby, and an aria-labelled close control"
        status: pass
    human_judgment: false
  - id: D2
    description: "field/1 renders a <label for> bound to the input's id"
    requirement: "DS-03"
    verification:
      - kind: unit
        ref: "test/scoria_web/ui_component_test.exs#primitive accessible-name + structure coverage (DS-02/DS-03/Criterion 2) field renders a <label for> bound to the input's id"
        status: pass
    human_judgment: false
  - id: D3
    description: "table/1 renders scoria-table__th column headers and an aria-labelled Pagination nav"
    requirement: "DS-02"
    verification:
      - kind: unit
        ref: "test/scoria_web/ui_component_test.exs#primitive accessible-name + structure coverage (DS-02/DS-03/Criterion 2) table renders scoria-table__th column headers and an aria-labelled pagination nav"
        status: pass
    human_judgment: false
  - id: D4
    description: "badge/1 always renders visible text alongside tone (never color-alone); time/1 renders a machine-readable <time datetime> with an exact-time title; evidence_rows/1 renders a <dl> of dt/dd metadata pairs"
    requirement: "DS-03"
    verification:
      - kind: unit
        ref: "test/scoria_web/ui_component_test.exs#primitive accessible-name + structure coverage (DS-02/DS-03/Criterion 2) badge always renders a visible text label alongside tone (never color-alone)"
        status: pass
      - kind: unit
        ref: "test/scoria_web/ui_component_test.exs#primitive accessible-name + structure coverage (DS-02/DS-03/Criterion 2) time renders a machine-readable <time datetime> with an exact-time title"
        status: pass
      - kind: unit
        ref: "test/scoria_web/ui_component_test.exs#primitive accessible-name + structure coverage (DS-02/DS-03/Criterion 2) evidence_rows (metadata rows) renders a <dl> of dt/dd pairs"
        status: pass
    human_judgment: false
  - id: D5
    description: "No ad-hoc pixel-valued inline style attribute anywhere in lib/scoria_web/ui.ex (D-14)"
    requirement: "DS-02"
    verification:
      - kind: unit
        ref: "test/scoria_web/ui_component_test.exs#primitive spacing / variant / link-token coherence (DS-02/DS-03/D-13/D-14) no ad-hoc pixel-valued inline style attribute in ui.ex (D-14)"
        status: pass
    human_judgment: false
  - id: D6
    description: "button/1 variant vocabulary locked to [:primary, :ghost, :danger]; size scale reinforced at [:md, :sm]; tone vocabulary locked to the 7-atom set"
    requirement: "DS-02"
    verification:
      - kind: unit
        ref: "test/scoria_web/ui_component_test.exs#primitive spacing / variant / link-token coherence (DS-02/DS-03/D-13/D-14) button/1 variant vocabulary stays locked to [:primary, :ghost, :danger]"
        status: pass
      - kind: unit
        ref: "test/scoria_web/ui_component_test.exs#primitive spacing / variant / link-token coherence (DS-02/DS-03/D-13/D-14) size scale stays locked to [:md, :sm] (reinforces 38-02's D-13/D-15 guard)"
        status: pass
      - kind: unit
        ref: "test/scoria_web/ui_component_test.exs#primitive spacing / variant / link-token coherence (DS-02/DS-03/D-13/D-14) tone vocabulary stays within the locked 7-atom set; no new tone atom introduced"
        status: pass
    human_judgment: false
  - id: D7
    description: "Links resolve through --scoria-link / --scoria-link-hover semantic tokens in both theme blocks; panel/drawer/modal/form-section/table/evidence-rows/list component rules all reference a spacing token (closes 'lists' from Criterion 2's enumeration)"
    requirement: "DS-03"
    verification:
      - kind: unit
        ref: "test/scoria_web/ui_component_test.exs#primitive spacing / variant / link-token coherence (DS-02/DS-03/D-13/D-14) --scoria-link / --scoria-link-hover are declared in both theme blocks and consumed by .scoria-link (DS-01/DS-03)"
        status: pass
      - kind: unit
        ref: "test/scoria_web/ui_component_test.exs#primitive spacing / variant / link-token coherence (DS-02/DS-03/D-13/D-14) panel/drawer/modal/form-section/table/evidence-rows/list rules reference spacing tokens (D-14)"
        status: pass
    human_judgment: false
  - id: D8
    description: "Full ExUnit suite green with --warnings-as-errors (same 3 pre-existing unrelated failures documented in 38-02 recur verbatim; none reference this plan's surface)"
    verification:
      - kind: unit
        ref: "SCORIA_DB_PORT=55432 MIX_ENV=test mix test --warnings-as-errors (823 tests, 3 pre-existing unrelated failures — see Deviations / deferred-items.md)"
        status: pass
    human_judgment: false

duration: ~15min
completed: 2026-07-02
status: complete
---

# Phase 38 Plan 03: Remaining Criterion 2 Primitive Coherence Guards Summary

**Closed out ROADMAP Criterion 2's full primitive enumeration (links, badges, timestamps, metadata rows, panels, drawers, modals, forms, tables, lists) with two new regression-guard describe blocks in `ui_component_test.exs` — an audit-and-lock plan that found the codebase already coherent everywhere and added zero production code.**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-07-02T23:18:22Z (approx, per STATE.md `last_updated`)
- **Completed:** 2026-07-02T23:33:00Z
- **Tasks:** 2 completed
- **Files modified:** 1 (test file only)

## Accomplishments

- Verified, against the live source (not from memory/grounding docs alone), that every primitive named in Criterion 2 but untouched by 38-01/38-02 is already coherent: `modal/1` and `drawer/1` render `role="dialog"` + `aria-labelledby` + an aria-labelled close control; `field/1` renders `<label for={@id}>`; `table/1` renders `scoria-table__th` column headers and an `aria-labelled` `<nav>` pagination strip; `badge/1` always renders a visible text label alongside its tone class; `time/1` renders a machine-readable `<time datetime>` with an exact-time `title`; `evidence_rows/1` renders a `<dl>` of `<dt>`/`<dd>` pairs; zero pixel-valued inline styles exist in `lib/scoria_web/ui.ex`; `button/1`'s variant vocabulary is exactly `[:primary, :ghost, :danger]`; the tone vocabulary across `toast/1` and `evidence_section/1` is exactly the 7-atom locked set; `--scoria-link`/`--scoria-link-hover` are declared in both theme blocks and consumed by `.scoria-link`; and the panel/drawer/modal/form-section/table/evidence-rows/list component CSS rules all reference `var(--scoria-space-*)` spacing tokens.
- Added `describe "primitive accessible-name + structure coverage (DS-02/DS-03/Criterion 2)"` (7 tests) locking the accessible-name/semantic-structure invariants above for modal, drawer, field, table, badge, time, and evidence_rows — the primitives 38-01/38-02 did not cover.
- Added `describe "primitive spacing / variant / link-token coherence (DS-02/DS-03/D-13/D-14)"` (5 tests) with source-scan guards: no ad-hoc pixel-valued inline style, button/1's variant vocabulary locked, the size scale reinforced, the tone vocabulary locked to 7 atoms, the link-token pair declared in both themes and consumed, and spacing-token usage confirmed across all seven named component rules (including the list selectors `.scoria-selectable-list` and `.scoria-command__list`, explicitly closing "lists" from Criterion 2's enumeration — the only Criterion-2 primitive without a standalone component, since list markup lives inside `command_palette/1` and `selectable_card/1`).
- Both tasks were guards-only per the plan's expectation ("RESEARCH confirmed the codebase is mostly already-correct") — `lib/scoria_web/ui.ex` was read and audited but never modified.
- Re-ran the full ExUnit suite (`mix test --warnings-as-errors`, 823 tests) confirming the same 3 pre-existing, unrelated failures documented in 38-02's SUMMARY recur verbatim and reference none of this plan's guards.

## Task Commits

Each task was committed atomically:

1. **Task 1: Accessible-name + semantic-structure coverage guards** - `0c7d76e` (test)
2. **Task 2: Spacing / variant-vocabulary / link-token coherence lock** - `d680465` (test)

_Note: both tasks are test-only per the plan's audit-and-lock nature — no production code changes were needed since every invariant was already correct._

## Files Created/Modified

- `test/scoria_web/ui_component_test.exs` - Added two new describe blocks (12 tests total): `"primitive accessible-name + structure coverage (DS-02/DS-03/Criterion 2)"` and `"primitive spacing / variant / link-token coherence (DS-02/DS-03/D-13/D-14)"`, appended after 38-02's `"primitive size scale + focus uniformity"` block without touching any existing describe block.

## Decisions Made

- Verified each regex against the live 1447-line `lib/scoria_web/ui.ex` and the CSS source files with standalone Elixir scripts before committing them into ExUnit assertions — avoided guessing at exact whitespace/formatting (e.g. the multi-line `evidence_section/1` tone attr vs. the single-line `toast/1` tone attr both needed to match the same regex).
- Used the `default: :primary` vs `default: :ghost` distinction to disambiguate `button/1`'s `attr(:variant, ...)` from `icon_button/1`'s identical `values:` list, rather than matching forward to each function's `def` boundary — simpler and equally precise given the file's structure.
- Scoped the "no ad-hoc pixel" guard to `style=` attribute contexts specifically (`~r/style=(?:"|\{")[^"]*?\d+px/`) rather than a bare `\d+px` scan across the whole file, so it correctly ignores unrelated `px` mentions in `@doc` prose (e.g. ">=768px" describing responsive breakpoints) and the `attr(:max_width, ..., default: "560px")` declaration (a separate line from the `style={"max-width: #{@max_width}"}` binding that consumes it).
- Skipped re-running the Playwright `mix scoria.ui.e2e` suite: since this plan made zero production-code or CSS changes, the rendered DOM is unchanged from what 38-02 already verified end-to-end; starting a dev server would add latency with no new coverage.

## Deviations from Plan

None - plan executed exactly as written. Both tasks were guards-only as the plan anticipated ("if the audit finds everything already coherent (expected), ui.ex is unchanged and this is a guards-only plan") — no accessible-name gaps were found on any of the seven audited primitives, so `lib/scoria_web/ui.ex` required zero edits.

Two minor test-assertion adjustments were needed during authoring (not deviations from the plan, just render-output fidelity fixes caught immediately by the verification loop):
- `assert html =~ ~s(<th class="scoria-table__th")` → dropped the closing quote (`~s(<th class="scoria-table__th)`) because Phoenix's class-list join leaves a trailing space before the closing quote when the column's `class:` value is `nil`.
- Same fix applied to the `<dl class="scoria-evidence-rows")` assertion in the `evidence_rows` test, for the same reason.

Both were caught by the first `mix test` run before any commit and fixed in the same edit pass — no separate commit needed.

## Issues Encountered

- Ran the full `SCORIA_DB_PORT=55432 MIX_ENV=test mix test --warnings-as-errors` suite (823 tests) as required by the plan's `<verification>` section: the same 3 pre-existing failures documented in 38-02's SUMMARY recur verbatim (`ci_policy_contract_test.exs` stale `"v2.15"` roadmap-version assertion, `capture_parity_test.exs` compile-only ratchet timing, `support_copilot_gallery_test.exs` "Approval inbox" consumer-example copy gap). None reference `modal`, `drawer`, `field`, `table`, `badge`, `time`, `evidence_rows`, `--scoria-link`, or any pixel/variant/tone/spacing guard added by this plan. Logged an additional confirmation entry in `.planning/phases/38-foundations-and-primitive-controls/deferred-items.md` (not fixed, per the deviation-rule scope boundary).
- Did not start a local `mix phx.server` for `mix scoria.ui.e2e` (see Decisions above) — no production markup or CSS changed this plan, so the Playwright surface is byte-identical to 38-02's already-verified state.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Criterion 2's full primitive enumeration (links, badges, timestamps, metadata rows, panels, drawers, modals, forms, tables, lists, plus 38-01/38-02's toasts/stats/copy-controls/button-scale) is now under regression-guard coverage in a single test file — Phase 39 (page flows) and Phase 40 (focus-order/WCAG/motion/responsive sweep) can build on this locked coherence without re-auditing these primitives.
- No new variant/tone/size atom, no component redesign, and no ad-hoc pixel value can land in `lib/scoria_web/ui.ex` or `assets/css/04-components.css` without breaking one of these 12 new guards (or the 4 from 38-02, or the guards from 38-01) — future phases get an immediate regression signal on primitive drift.
- The 3 pre-existing, unrelated test failures (roadmap version ledger, warning-inventory capture-parity ratchet, support-copilot-gallery consumer example) remain flagged in `deferred-items.md` for `/gsd-verify-work` / `/gsd-audit-uat` triage — not introduced by this or any 38-0x plan.
- Phase 38 (foundations-and-primitive-controls) is now feature-complete across all 3 planned waves (38-01, 38-02, 38-03).

---
*Phase: 38-foundations-and-primitive-controls*
*Completed: 2026-07-02*

## Self-Check: PASSED

All modified files verified present (`test/scoria_web/ui_component_test.exs`, this SUMMARY.md);
both task commit hashes (`0c7d76e`, `d680465`) verified present in `git log`.
