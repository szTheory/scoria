---
phase: 39-component-groups-and-operator-flows
plan: 04
subsystem: ui
tags: [phoenix, liveview, heex, page_header, stub_page, empty_state, design-system]

# Dependency graph
requires:
  - phase: 39-component-groups-and-operator-flows
    provides: "page_header/1 (Plan 01) added to ScoriaWeb.UI"
provides:
  - "orchestrator_live Home, workflow_live/index, eval_spec_live/index, and prompt_live/index each render their single page-outline <h1> through page_header/1"
  - "coming_soon_live's two hand-rolled header shapes (reserved-capability + not-found) reconciled into sanctioned page-level headers (stub_page/1 + page_header/1 + empty_state/1)"
  - "eval_spec_live rubrics title drops its parenthetical module-name suffix (D-23)"
  - "prompt_live leads with operator language ('Edit Prompt' / 'Prompt' column) and demotes the opaque entity_id to <.id> evidence"
affects: [39-05, 39-08]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "page_header/1 attr :title (not slot) as the single page-outline <h1> source of truth"
    - "page-level not-found state = page_header/1 + empty_state/1 (D-02/D-03), not a table :empty slot"
    - "opaque IDs demoted to <.id> evidence with an explicit per-row id when the same value can repeat across table rows"

key-files:
  created: []
  modified:
    - lib/scoria_web/live/orchestrator_live.ex
    - lib/scoria_web/live/workflow_live/index.ex
    - lib/scoria_web/live/eval_spec_live/index.ex
    - lib/scoria_web/live/prompt_live/index.ex
    - lib/scoria_web/live/coming_soon_live.ex
    - test/scoria_web/live/prompt_live_test.exs

key-decisions:
  - "prompt_live has no human-readable name field on PromptTemplate (entity_id is a generated UUID, verified against schema/migration/dev_seed — no 'name' column exists anywhere in the domain). Per D-22's domain-noun framing and the established release_workbench_live analog (object_type=\"Prompt\" + key_scalar=\"v{version}\"), the fix leads the title/column with the domain noun \"Prompt\" and demotes entity_id to <.id> evidence (still visible, still copyable, just no longer the primary orientation text) rather than fabricating a name or adding a schema column (which would be a Rule 4 architectural change out of scope for a microcopy plan)."
  - "Dropped the page-specific .scoria-home__identity CSS class on orchestrator_live's summary paragraph in favor of page_header's shared .scoria-pagehead__description styling — no new CSS added, consistent with 'add no CSS' constraint. The now-unused .scoria-home__identity rule in 04-components.css was left in place (out of this plan's file scope per files_modified)."
  - "coming_soon_live's not-found branch uses page_header/1 + empty_state/1 rather than stub_page/1, because stub_page/1's required :works_today/:tracking_url fields and 'Soon' badge semantically describe a *future* capability, not a *missing* one — reusing it for 404 would misrepresent state."

requirements-completed: [FLOW-01, FLOW-02, COPY-01]

coverage:
  - id: D1
    description: "orchestrator_live Home renders its single <h1> through page_header/1, no residual hand-rolled .scoria-pagehead markup"
    requirement: "FLOW-01"
    verification:
      - kind: unit
        ref: "test/scoria_web/live/orchestrator_live_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "workflow_live/index renders its single <h1> through page_header/1"
    requirement: "FLOW-01"
    verification:
      - kind: unit
        ref: "test/scoria_web/live/workflow_live_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "eval_spec_live/index routes its <h1> through page_header/1 and drops the '(EvalSpecs)' module-name suffix"
    requirement: "COPY-01"
    verification:
      - kind: unit
        ref: "test/scoria_web/live/eval_spec_live/index_test.exs"
        status: pass
    human_judgment: false
  - id: D4
    description: "prompt_live/index migrates its page header to page_header/1, leads edit title/'Prompt' column with operator language, and demotes entity_id to <.id> evidence"
    requirement: "COPY-01"
    verification:
      - kind: unit
        ref: "test/scoria_web/live/prompt_live_test.exs"
        status: pass
    human_judgment: false
  - id: D5
    description: "coming_soon_live reconciles both hand-rolled header shapes (reserved-capability + not-found) into sanctioned page-outline headers with no bare <h1>"
    requirement: "FLOW-01"
    verification:
      - kind: unit
        ref: "test/scoria_web/live/coming_soon_live_test.exs"
        status: pass
    human_judgment: false

duration: 15min
completed: 2026-07-03
status: complete
---

# Phase 39 Plan 04: Component Groups And Operator Flows — Page Header + Microcopy Migration Summary

**Migrated 5 LiveViews (orchestrator Home, workflow index, eval-spec index, prompt index, coming-soon) off hand-rolled `.scoria-pagehead`/`.scoria-stub` markup onto `page_header/1`/`stub_page/1`/`empty_state/1`, and fixed the eval-spec module-name suffix + prompt entity_id microcopy offenders.**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-07-03T09:13:00Z
- **Completed:** 2026-07-03T09:17:16Z
- **Tasks:** 3
- **Files modified:** 6 (5 LiveViews + 1 test file)

## Accomplishments
- `orchestrator_live` Home and `workflow_live/index` now render their single page-outline `<h1>` via `page_header/1` instead of hand-rolled `.scoria-pagehead` markup.
- `eval_spec_live/index`'s "Evaluation Rubrics" heading now routes through `page_header/1` and drops the `(EvalSpecs)` module-name suffix — operator language only.
- `prompt_live/index` migrates its hand-rolled header to `page_header/1`; the edit title now leads with "Edit Prompt" and the "Prompt" table column both demote the opaque `entity_id` to `<.id>` copyable evidence instead of interpolating it as raw text.
- `coming_soon_live`'s two distinct hand-rolled header shapes are reconciled: the reserved-capability branch already used `stub_page/1` (unchanged), and the "Capability not found" not-found branch now uses `page_header/1` + `empty_state/1` (D-02/D-03) instead of a hand-inlined `.scoria-stub` block with a bare `<h1>`.
- All five modules verified to have zero residual `<h1>` literals or hand-rolled pagehead/stub markup (grep-confirmed).

## Task Commits

Each task was committed atomically:

1. **Task 1: Migrate orchestrator Home + workflow index headers to page_header/1** - `e2286a6` (feat)
2. **Task 2: Migrate eval-spec + prompt headers and fix their microcopy offenders** - `f7b9312` (feat)
3. **Task 3: Reconcile coming_soon_live's two header shapes (D-03 not-found)** - `8448b68` (feat)

**Plan metadata:** (this commit)

## Files Created/Modified
- `lib/scoria_web/live/orchestrator_live.ex` - Home header migrated to `page_header/1`; dropped page-specific `.scoria-home__identity` class
- `lib/scoria_web/live/workflow_live/index.ex` - Runs index header migrated to `page_header/1`
- `lib/scoria_web/live/eval_spec_live/index.ex` - Rubrics header migrated to `page_header/1`; dropped `(EvalSpecs)` suffix
- `lib/scoria_web/live/prompt_live/index.ex` - Header migrated to `page_header/1`; edit title and "Prompt" column lead with domain noun + `<.id>` evidence for `entity_id`
- `lib/scoria_web/live/coming_soon_live.ex` - Not-found branch migrated from hand-inlined `.scoria-stub` to `page_header/1` + `empty_state/1`; outer redundant `.scoria-pagehead` wrapper removed
- `test/scoria_web/live/prompt_live_test.exs` - Updated title assertions for the new "Edit Prompt" + `<.id>` copy (entity_id still appears in HTML via the `<.id>` evidence primitive)

## Decisions Made
- **prompt_live "human name" resolution:** `PromptTemplate` genuinely has no name field (verified schema, migration, and `dev_seed.exs` — `entity_id` is `Ecto.UUID.generate()`'d and used purely to group draft/active versions of one logical template). Fabricating a name or adding a schema column would be a Rule 4 architectural change outside this plan's scope. Instead, per D-22's domain-noun framing and the existing `release_workbench_live` analog (`object_type="Prompt"` + `key_scalar="v{version}"`), the title/column now lead with the domain noun "Prompt" and demote `entity_id` to `<.id>` evidence — satisfying "not the primary orientation/cell" without inventing data that doesn't exist.
- **coming_soon_live not-found uses `page_header/1` + `empty_state/1`, not `stub_page/1`:** `stub_page/1` requires `:works_today`/`:tracking_url` and renders a "Soon" badge — semantically a *future* capability, not a *missing* one. Reusing it for a 404 state would misrepresent the page's meaning, so the not-found branch composes `page_header/1` (sanctioned `<h1>`) + `empty_state/1` (D-02 empty_state-style body) instead.
- Dropped the page-specific `.scoria-home__identity` CSS class usage on orchestrator_live's summary text in favor of `page_header/1`'s shared `.scoria-pagehead__description` styling — no new CSS added. The now-unused CSS rule in `assets/css/04-components.css` was left untouched (out of this plan's `files_modified` scope).

## Deviations from Plan

None - plan executed exactly as written. The "human name" ambiguity for `prompt_live` (see Decisions Made) was resolved within the plan's stated intent (D-22/D-23 demotion rule + existing in-repo analog) without requiring an architectural change or user check-in.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All five migrated pages are grep-confirmed to have exactly one sanctioned page-outline header and zero residual hand-rolled `.scoria-pagehead`/`.scoria-stub` markup — Plan 08's D-05 source-scan guard should find these files green on arrival.
- `page_header/1`, `stub_page/1`, and `empty_state/1` each now have a second/third real consumer beyond their original definition sites, further validating the shared-component contract for the sibling Wave-2 plan (39-05, disjoint file set) and the guard plan (39-08).
- No blockers.

---
*Phase: 39-component-groups-and-operator-flows*
*Completed: 2026-07-03*

## Self-Check: PASSED

All 5 modified LiveView files, the updated test file, and all 3 task commit hashes (`e2286a6`, `f7b9312`, `8448b68`) were verified present.
