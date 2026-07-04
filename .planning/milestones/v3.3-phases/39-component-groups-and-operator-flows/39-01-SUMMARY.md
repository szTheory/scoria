---
phase: 39-component-groups-and-operator-flows
plan: 01
subsystem: ui
tags: [phoenix-component, elixir, design-system, status-label, page-header]

# Dependency graph
requires:
  - phase: 38-foundations-and-primitive-controls
    provides: Locked Criterion 2 primitive set (`ScoriaWeb.UI` tone/badge/id/time/copy-control vocabulary) that this plan's two new primitives extend.
provides:
  - "page_header/1 — thin ScoriaWeb.UI function component owning each page's single page-outline <h1>."
  - "status_label/1 additive curated upgrade — D-25 canonical operator status vocabulary, generic fallback retained."
affects: [39-02, 39-03, 39-04, 39-05, 39-06, 39-07, 39-08]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "page_header/1 mirrors page_section/1's conditional :actions-slot idiom (ui.ex:207) but emits <h1> from a required :string attr, not a slot, so schema/module names structurally cannot leak into the page heading."
    - "status_label/1 mirrors tone/1's curated-case-above-fallback idiom (ui.ex:23-47): curated case clauses sit above the retained generic String.replace fallback and the Unknown catch-all, so unseen statuses degrade gracefully instead of raising."

key-files:
  created: []
  modified:
    - lib/scoria_web/ui.ex
    - test/scoria_web/ui_component_test.exs

key-decisions:
  - "page_header/1's :actions wrapper <div :if={@actions != []}> carries no class attribute at all (not even an unstyled one), satisfying the plan's zero-new-CSS-class constraint literally while still applying the existing .scoria-pagehead__title--with-actions modifier."
  - "The :summary <p> is rendered as a sibling of .scoria-pagehead__title (matching the simplest existing analog, dataset_live/index.ex:62-67) rather than nested inside it (matching the richer review_queue_live.ex:52-56 markup) — both existing analogs disagree on nesting, and the flex layout is identical either way since .scoria-pagehead__title only flexes its own direct children."
  - "Curated the exact D-25 vocabulary and no more (Pending/Approved/Expired/Passed/Failed/Regressed/Running/Promoted/Draft/Published/Connected/Disconnected/Idle) — did not curate 'rejected' per D-24d (approval-domain 'Denied' is ApprovalCopy's responsibility, landing in Plan 39-02/39-03)."

patterns-established:
  - "Structural TDD RED discriminator for behavior-preserving refactors: when a curated-vocabulary upgrade's individual outputs are identical to what the pre-existing generic fallback already produces (all D-25 words are single simple tokens with no underscores), a pure behavioral test doesn't fail before the code exists. Added a source-scan structural assertion (case-dispatch presence + ordering relative to the fallback) so RED is genuine before GREEN, per the TDD fail-fast rule."

requirements-completed: [FLOW-01, COPY-01]

coverage:
  - id: D1
    description: "page_header/1 renders exactly one <h1> from a required :string title attr; :summary slot renders a <p class=\"scoria-pagehead__description\">; :actions slot (0..1) applies .scoria-pagehead__title--with-actions only when present; reuses only existing .scoria-pagehead* CSS."
    requirement: "FLOW-01"
    verification:
      - kind: unit
        ref: "test/scoria_web/ui_component_test.exs#page_header/1 design-system surface contract (D-01, Phase 39)"
        status: pass
    human_judgment: false
  - id: D2
    description: "status_label/1 additively curates the D-25 canonical operator status vocabulary above the retained generic String.replace fallback and Unknown catch-all; atom input still delegates through the binary path; an unseen status returns a titleized string without raising; \"rejected\" resolves to \"Rejected\", not \"Denied\"."
    requirement: "COPY-01"
    verification:
      - kind: unit
        ref: "test/scoria_web/ui_component_test.exs#status_label/1 additive curated upgrade (D-24a/D-25, Phase 39)"
        status: pass
    human_judgment: false

duration: 15min
completed: 2026-07-03
status: complete
---

# Phase 39 Plan 01: Component Groups And Operator Flows — page_header/1 and status_label/1 Summary

**Thin `page_header/1` (single-string-attr `<h1>`) and an additive `status_label/1` curated-vocabulary upgrade, both landed in `ScoriaWeb.UI` with zero new CSS classes and zero caller changes.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-07-03T08:41:57Z (first commit)
- **Completed:** 2026-07-03T08:43:40Z (last commit)
- **Tasks:** 2 completed
- **Files modified:** 2

## Accomplishments
- `page_header/1` — the single home for every Phase 39 page's `<h1>`, with `title` as a required `:string` attr (not a slot) so IDs/module names structurally cannot leak into the heading (D-01/D-23/D-26), plus `:summary` and 0..1 `:actions` slots reusing only the existing `.scoria-pagehead*` CSS family.
- `status_label/1` additively upgraded with the D-25 canonical operator vocabulary (13 curated statuses) sitting above the retained generic `String.replace`/`Unknown` fallback — proven never to raise on an unseen status, and proven NOT to curate `"rejected"` to `"Denied"` (that stays approval-domain-only, D-24d).
- 11 new unit tests (6 for `page_header/1`, including a `<h1>`-count assertion and a no-new-CSS-class assertion; 6 for `status_label/1`, including a structural source-scan assertion that curated clauses are genuinely above the fallback) — 132/132 green under `--warnings-as-errors`.

## Task Commits

Each task followed the RED → GREEN TDD cycle with separate commits:

1. **Task 1: Add page_header/1 to ScoriaWeb.UI**
   - `e9b8e27` (test) — RED: 6 failing tests against undefined `page_header/1`
   - `8d9ac90` (feat) — GREEN: `page_header/1` implementation, 120/120 tests passing
2. **Task 2: Additively upgrade status_label/1**
   - `80163ef` (test) — RED: 1 genuinely failing structural test (behavioral assertions alone don't discriminate — see Deviations)
   - `45d1b94` (feat) — GREEN: curated case clauses above the retained fallback, 126/126 tests passing

**Plan metadata:** (this commit, following SUMMARY creation)

## Files Created/Modified
- `lib/scoria_web/ui.ex` — added `page_header/1` (~ui.ex:216-247, immediately after `page_section/1`); upgraded `status_label/1` (~ui.ex:51-83) with 13 curated case clauses above the retained generic fallback and `Unknown` catch-all.
- `test/scoria_web/ui_component_test.exs` — added `describe "page_header/1 design-system surface contract (D-01, Phase 39)"` (6 tests) and `describe "status_label/1 additive curated upgrade (D-24a/D-25, Phase 39)"` (6 tests).

## Decisions Made
- `page_header/1`'s action-region wrapper carries no `class` attribute at all rather than a bare unstyled class, satisfying "zero new CSS classes" literally.
- The `:summary` `<p>` is rendered as a sibling of `.scoria-pagehead__title` (per the simplest existing analog `dataset_live/index.ex:62-67`), not nested inside it (per the richer `review_queue_live.ex:52-56` analog) — the two existing hand-rolled instances disagree on nesting and the plan's `<behavior>` spec ("renders... below the title") is satisfied either way.
- Curated exactly the D-25 vocabulary (13 statuses) — no more, no less — and explicitly did NOT curate `"rejected"` per D-24d.

## Deviations from Plan

None — plan executed exactly as written, with one TDD-process note documented below (not a deviation from the plan's required behavior, but a note on how RED was proven).

### Process note: structural RED discriminator for Task 2

**Found during:** Task 2 (status_label/1 upgrade), writing the RED test.

**Observation:** All 13 D-25 vocabulary words (`pending`, `approved`, `expired`, etc.) are single lowercase tokens with no underscores. The pre-existing generic fallback (`String.replace("_", " ") |> String.capitalize()`) already produces the identical output for every one of them (e.g., `"approved"` → `"Approved"` via either path). A purely behavioral RED test (`status_label("approved") == "Approved"`) would therefore pass BEFORE the curated clauses were added — violating the TDD fail-fast rule ("if a test passes unexpectedly during RED, STOP and investigate").

**Resolution:** Added a discriminating structural test asserting (a) a `case status do` dispatch exists inside the binary clause, (b) it contains a literal `"approved" -> "Approved"` clause, (c) the generic `String.replace` fallback line appears AFTER (not instead of) the case dispatch, and (d) no `"rejected" -> "Denied"` clause exists. This test genuinely failed pre-implementation (confirmed via `mix test`) and passed post-implementation. All 5 purely-behavioral tests were also run and pass, confirming the runtime contract independent of the structural check.

**Files modified:** test/scoria_web/ui_component_test.exs (part of the `80163ef` RED commit)
**Verification:** `mix test test/scoria_web/ui_component_test.exs` — confirmed 1 genuine failure pre-implementation, 0 failures post-implementation.

---

**Total deviations:** 0 (process note only, no plan-behavior deviation)
**Impact on plan:** None — plan requirements met exactly as specified.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- `page_header/1` and the curated `status_label/1` are ready for adoption by Plans 04/05/06 (page-file migrations) and Plan 02 (copy modules, which reuse `status_label/1`'s retained fallback as their own atom-safety backstop).
- No page callers were touched in this plan (by design — zero page-file overlap with the parallel Wave 1 plans).
- `mix test.knowledge`/DS-06/token-contrast guards all remain green; no raw-palette or contrast drift introduced.

---
*Phase: 39-component-groups-and-operator-flows*
*Completed: 2026-07-03*

## Self-Check: PASSED

All created/modified files verified present on disk; all 4 task commit hashes (`e9b8e27`, `8d9ac90`, `80163ef`, `45d1b94`) verified present in `git log`.
