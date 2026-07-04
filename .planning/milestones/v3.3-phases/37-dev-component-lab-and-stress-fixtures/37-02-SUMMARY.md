---
phase: 37-dev-component-lab-and-stress-fixtures
plan: 02
subsystem: ui
tags: [phoenix-liveview, dev-only-tooling, design-system, component-lab, elixir]

# Dependency graph
requires:
  - phase: 37-01
    provides: DevLab.Fixtures (states_for/2, inventory_id/1, scenario/1) and DevLab.Sections.States (state_tone/1, states_band/1) — this plan's entire data/render spine
provides:
  - DevLab.Sections.Foundations (dev/lab/sections/foundations.ex) — foundations/1: read-only inspection of semantic color tokens, type scale, in-lab spacing scale (space-1-space-6), and motion durations, plus a CSS-only "Reduced motion" affordance reflecting the OS/browser prefers-reduced-motion signal
  - DevLab.Sections.Primitives (dev/lab/sections/primitives.ex) — primitives/1: 18 canonical ScoriaWeb.UI primitives rendered across all 10 D-11 states via states_band/1, each anchored to its Phase-36 PRIM-* inventory ID, with an optional :item deep-link filter
affects: [37-03, 37-04, 37-05, 37-06]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "with_lab_state/1 — embeds the current D-11 state atom into each derived fixture map before it reaches a states_band/1 :render slot, so per-specimen tone/id/copy logic can route through DevLab.Sections.States.state_tone/1 without the :render slot needing direct access to the outer loop variable (states_band/1's slot only exposes :fixture, not :state)"
    - "Per-component tone-vocabulary clamp (toast_tone/1) — downstream primitives with a restricted attr(:tone, values: [...]) (here <.toast>, which excludes :brand/:trace) still resolve through the single state_tone/1 mapping, then narrow only the out-of-range result, rather than duplicating a second state->tone table"
    - "Representative-row overlay rendering — <.drawer>/<.modal> specimens open genuinely only for the :normal state row (full-viewport position:fixed overlays would stack unusably ten deep in the same page section); the other nine rows say explicitly that open/close/focus stress lives in the Overlays IA section (D-10) instead of faking an open panel"
    - "Inline @media (prefers-reduced-motion: reduce) toggle scoped inside Foundations' own HEEx output — visualizes the SAME browser feature 05-motion.css's existing kill switch already consumes, without touching that CSS file or inventing a second motion mechanism"

key-files:
  created:
    - dev/lab/sections/foundations.ex
    - dev/lab/sections/primitives.ex
  modified: []

key-decisions:
  - "signal_strip (PRIM-SIGNAL-STRIP) is intentionally NOT given its own Primitives band — its 36-inventory.json status is duplicated (not canonical), and DevLab.Fixtures.inventory_id/1 (Plan 01 SSOT) does not carry an ID for it. overview_stats (PRIM-OVERVIEW-STATS, canonical) is rendered instead and covers the 'signal summaries' D-09 requirement in spirit; the duplication itself is Phase 38 DS-02/DS-03 consolidation scope, not this plan's to resolve"
  - "Every specimen's tone is derived by embedding the current D-11 state atom into its own fixture map (with_lab_state/1) and calling DevLab.Sections.States.state_tone/1 on that embedded value — never ScoriaWeb.UI.tone/1 on a lab-state atom, and never a literal D-11 atom written directly into a tone attr, matching the acceptance criteria and D-12's state/tone vocabulary separation"
  - "Drawer/modal primitives render open only for their :normal state row rather than all ten simultaneously, to avoid an unusable stack of ten full-viewport position:fixed overlays in one page section; the remaining nine rows carry an explicit note pointing at the dedicated Overlays IA section (D-10/D-07) for open/close/focus/dismissal stress"
  - "Foundations' Reduced motion affordance is pure CSS (@media (prefers-reduced-motion: reduce) toggling two spans), scoped inline inside foundations.ex's own HEEx output rather than editing assets/css/05-motion.css — satisfies D-14 ('display current state only, do not invent a second motion mechanism') without widening this plan's files_modified beyond the two section files"

patterns-established:
  - "Pattern: with_lab_state/1 + state_tone/1 fully-qualified call — the standard way any future Primitives/Groups band derives its own inner-specimen tone from the D-11 state without needing states_band/1's slot signature to change"
  - "Pattern: component-specific tone clamp (e.g. toast_tone/1) for any ScoriaWeb.UI primitive whose attr(:tone, values: [...]) is a strict subset of the full tone vocabulary"

requirements-completed: [LAB-02]

coverage:
  - id: D1
    description: "Foundations IA section: read-only specimens of the existing semantic color tokens, type scale, in-lab spacing scale (space-1-space-6), and motion durations, built only from existing ScoriaWeb.UI chrome primitives, with zero new hex/spacing/type/motion values and a Reduced motion affordance reflecting the real prefers-reduced-motion signal"
    requirement: "LAB-02"
    verification:
      - kind: unit
        ref: "MIX_ENV=dev mix compile --warnings-as-errors"
        status: pass
      - kind: unit
        ref: "test/scoria_web/ds06_drift_guard_test.exs#dev/lab/** (Component Lab) has zero raw palette classes and zero raw hex colors (D-26)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Primitives IA section: 18 canonical ScoriaWeb.UI primitives (button, icon_button, badge, panel, page_section, overview_stats, table, drawer, modal, toast, field, form_section, notebook, raw_evidence, empty_state, skeleton, id, time) rendered across all 10 D-11 states via states_band/1, each anchored to its Phase-36 PRIM-* inventory ID, tone resolved exclusively via state_tone/1"
    requirement: "LAB-02"
    verification:
      - kind: unit
        ref: "MIX_ENV=dev mix compile --warnings-as-errors"
        status: pass
      - kind: unit
        ref: "test/scoria_web/dev_lab_boundary_test.exs#guard #7: every canonical PRIM-*/GROUP-* inventory ID is referenced under dev/lab/** (D-08/D-32)"
        status: pass
    human_judgment: true
    rationale: "Guard #7 is a coverage FLOOR (literal-string presence of inventory IDs), not proof that every one of the 18 primitives actually renders correctly across all 10 states with legible tone/copy — that requires the browser-render proof arriving in Plan 06 (lab.spec.mjs) once the route is mounted in Plan 05. This SUMMARY's automated checks confirm compile-clean structure and inventory-ID anchoring only."

# Metrics
duration: ~35min
completed: 2026-07-02
status: complete
---

# Phase 37 Plan 02: Foundations And Primitives Specimen Sections Summary

**Read-only Foundations token/type/spacing/motion inspection plus an 18-primitive Primitives specimen bench, every primitive rendered across all 10 D-11 states through Plan 01's states_band/1 and anchored to its Phase-36 PRIM-* inventory ID.**

## Performance

- **Duration:** ~35 min
- **Completed:** 2026-07-02T20:37:54Z
- **Tasks:** 2
- **Files modified:** 2 (both created)

## Accomplishments

- `DevLab.Sections.Foundations` (`dev/lab/sections/foundations.ex`): read-only specimens of six semantic color tokens (surface-app, surface-panel, action, text-muted, border, focus-ring), the full six-role type scale (badge/eyebrow through display/metric, each with its exact size/weight/line-height), the in-lab spacing scale (`space-1`-`space-6`), and the three motion durations (`dur-fast`/`dur-mid`/`dur-slow`) — every value resolved through a `var(--scoria-*)` custom-property reference, zero new hex/spacing/type/motion values. A `Reduced motion` affordance (exact D-27 label) toggles between two spans purely via `@media (prefers-reduced-motion: reduce)`, visualizing the same browser signal `05-motion.css`'s existing kill switch already consumes.
- `DevLab.Sections.Primitives` (`dev/lab/sections/primitives.ex`): 18 canonical `ScoriaWeb.UI` primitives — button, icon_button, badge, panel, page_section, overview_stats, table, drawer, modal, toast, field, form_section, notebook, raw_evidence, empty_state, skeleton, id, time — each rendered through `states_band/1` across all 10 D-11 states, anchored to its Phase-36 `PRIM-*` inventory ID (visible both via the band's `inventory_id` attr and an `<.id>` evidence chip in the panel header). Supports an optional `item` deep-link filter for the future `/scoria/_lab/primitives/:item` route.
- Every specimen's visual tone is derived exclusively through `DevLab.Sections.States.state_tone/1` — a new `with_lab_state/1` helper embeds the current D-11 state atom into each derived fixture map so per-specimen tone logic can resolve it without needing direct access to `states_band/1`'s outer loop variable. No HEEx literal ever passes a bare D-11 state atom as a `tone` attr.
- Drawer and modal specimens render genuinely open only for the `:normal` state row (avoiding ten stacked full-viewport `position: fixed` overlays); the other nine rows carry an explicit note that open/close/focus/dismissal stress belongs to the dedicated Overlays IA section (D-10), landing in a later plan in this phase.

## Task Commits

Each task was committed atomically:

1. **Task 1: Build the Foundations inspection section** - `145afcc` (feat)
2. **Task 2: Build the Primitives specimen section across all 10 states** - `9c1dcf9` (feat)

**Plan metadata:** _pending (this commit)_

## Files Created/Modified

- `dev/lab/sections/foundations.ex` - `DevLab.Sections.Foundations.foundations/1`: read-only token/type/spacing/motion inspection
- `dev/lab/sections/primitives.ex` - `DevLab.Sections.Primitives.primitives/1`: 18-primitive states_band/1 specimen bench, `with_lab_state/1`, `show?/2` deep-link filter, per-primitive tone/copy helpers

## Decisions Made

- `signal_strip` (`PRIM-SIGNAL-STRIP`, status `duplicated` in `36-inventory.json`) is intentionally not given its own Primitives band — `DevLab.Fixtures.inventory_id/1` (Plan 01 SSOT) has no ID for it. `overview_stats` (`PRIM-OVERVIEW-STATS`, canonical) covers the D-09 "signal summaries" requirement in spirit; the underlying duplication is Phase 38 DS-02/DS-03 consolidation scope.
- Every specimen's tone routes through `DevLab.Sections.States.state_tone/1` on a state atom embedded into the fixture map via `with_lab_state/1`, never `ScoriaWeb.UI.tone/1` on a lab-state atom and never a literal D-11 atom written directly into a `tone` attr (D-12, acceptance criteria).
- `<.toast>`'s `attr(:tone, values: [:pass, :fail, :warn, :info, :neutral])` excludes `:brand`/`:trace`; `toast_tone/1` clamps `state_tone/1`'s `:brand` output (produced for the `:selected` state) down to `:info` rather than passing an out-of-range value, while still routing exclusively through `state_tone/1`.
- Drawer/modal specimens open only for the `:normal` row instead of all ten simultaneously, to avoid an unusable stack of full-viewport overlays; the other nine rows explicitly defer open/close/focus stress to the Overlays IA section.
- Foundations' `Reduced motion` affordance is pure CSS (`@media (prefers-reduced-motion: reduce)`) scoped inline inside `foundations.ex`'s own HEEx output, rather than editing `assets/css/05-motion.css` — keeps this plan's `files_modified` to exactly the two section files while still satisfying D-14.

## Deviations from Plan

None - plan executed exactly as written. `signal_strip`/`overview_stats` scoping and the drawer/modal `:normal`-only-open rendering were judgment calls made while implementing D-09's "cover at minimum..." list against Plan 01's already-fixed `inventory_id/1` map and `states_band/1` signature, not deviations from any explicit plan instruction.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `DevLab.Sections.Foundations.foundations/1` and `DevLab.Sections.Primitives.primitives/1` are stable public function components, ready for `DevLab.LabLive` to mount once Plan 05 wires the `/scoria/_lab` route.
- `Primitives.primitives/1`'s optional `item` attr is the seam Plan 05's `/scoria/_lab/primitives/:item` route needs — no further primitives.ex change required to support deep-linking.
- Plan 01's guard #7 inventory-ID coverage floor and the D-26 dev/lab/** raw-hex/raw-palette guard both remain green with these two new files in the scan path.
- Overlay open/close/focus/dismissal stress (drawer, modal, toast-over-dense-UI, command palette) is explicitly NOT covered here beyond a single representative open row — that is Plan 04's `Overlays` IA section per D-10, and this plan's drawer/modal specimens say so inline.
- Behavioral/browser render proof (does every one of the 18 primitives actually look right across all 10 states) is deferred to Plan 06 (`lab.spec.mjs`) once the route is reachable — this plan only proves compile-clean structure and inventory-ID anchoring, consistent with this plan's own `<verification>` block.
- No blockers.

## Self-Check: PASSED

Both claimed files found on disk (`dev/lab/sections/foundations.ex`, `dev/lab/sections/primitives.ex`).
Both task commit hashes (`145afcc`, `9c1dcf9`) found in `git log`.

---
*Phase: 37-dev-component-lab-and-stress-fixtures*
*Completed: 2026-07-02*
