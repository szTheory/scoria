---
phase: 37-dev-component-lab-and-stress-fixtures
plan: 03
subsystem: ui
tags: [phoenix-liveview, dev-only-tooling, design-system, component-lab, elixir]

# Dependency graph
requires:
  - phase: 37-01
    provides: DevLab.Fixtures (scenario/1, states_for/2, inventory_id/1, domains/0, scenarios_for_domain/1) and DevLab.Sections.States (states_band/1) — this plan's entire data/render spine
provides:
  - DevLab.Sections.Groups (dev/lab/sections/groups.ex) — groups/1: renders the real approval inbox, workflow tree, workflow detail, connector drawer, and incident evidence lib/scoria_web/components/*.ex groups across all 10 D-11 states, each anchored to its Phase-36 GROUP-* inventory ID; workflow detail organically exercises the nested replay/semantic evidence notebook groups it composes in production
  - DevLab.Sections.FixturesView (dev/lab/sections/fixtures_view.ex) — fixtures_view/1: browses all 15 D-20/D-19 fixture scenarios grouped by domain, with inventory/risk-ref id chips and progressive-disclosure raw payload evidence via the existing notebook/1 + raw_evidence/1 group; locked D-27 empty/error copy
affects: [37-04, 37-05, 37-06]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Per-group deterministic adapter helpers (approval_inbox_fixture/1, workflow_tree_steps/1, workflow_detail_step/1, connector_drawer_fixture/1, incident_evidence_fixture/1) that reshape DevLab.Fixtures.scenario/1 domain-noun payloads into the exact prop shape each real lib/scoria_web/components/*.ex module expects — literal, deterministic filler only (D-17: no randomness), never a second fixture catalog"
    - "Composed-component coverage: rather than mounting GROUP-REPLAY-EVIDENCE-NOTEBOOK-COMPONENT and GROUP-SEMANTIC-EVIDENCE-NOTEBOOK-COMPONENT a second time in isolation, Groups renders the real WorkflowDetailPanelComponent, which nests both notebooks internally — matching production composition instead of duplicating it"
    - "Defensive scenario_result/1 render-failure wrapper (Fixtures section): a function-level rescue around DevLab.Fixtures.scenario/1 so one broken future scenario clause fails gracefully inside its own specimen card instead of crashing the whole /scoria/_lab page; the locked D-27 error copy is a module attribute string (grep-able verbatim) that a String.replace/3 call may prepend component/fixture detail into without altering the wrapper"
    - "Verbatim-copy-as-constant: both D-27 locked strings (@fixture_empty_copy, @fixture_error_copy) live as module attributes in fixtures_view.ex even though DevLab.Fixtures already carries an identical empty_copy field per _empty scenario — guarantees the exact text is source-verbatim in this file too, not just re-derived at runtime"

key-files:
  created:
    - dev/lab/sections/groups.ex
    - dev/lab/sections/fixtures_view.ex
  modified: []

key-decisions:
  - "Groups feeds each band from ONE base domain-noun scenario per group (approval_requested, workflow_waiting_for_approval, workflow_failed_step, connector_degraded, incident_opened) via states_for/2's structural 10-state derivation — matching the single-base-scenario convention DevLab.Sections.Primitives established in Plan 02. Browsing BOTH the normal and empty/error scenario per domain (D-19's dual-scenario requirement) is the Fixtures section's job, not Groups' — a deliberate division of responsibility between the two sections in this plan"
  - "IncidentEvidenceComponent's deeply-nested @evidence shape (health_rollup/budget/breaker/incidents/audit_rows/deliveries) has no graceful nil-default path in the real component, unlike ApprovalInboxComponent/WorkflowDetailPanelComponent/ConnectorDetailDrawerComponent (all of which tolerate missing/default attrs). incident_evidence_fixture/1 therefore builds the full nested map deterministically from the base incident scenario plus literal, domain-realistic filler for sub-fields the scenario itself doesn't carry — never DB-fetched, never random (D-17)"
  - "Documented, not fixed: ScoriaWeb.ApprovalInboxComponent hardcodes its own <.table id=\"approvals\"> DOM id with no caller override. Stacking the real component across all ten state rows repeats that id ten times on the page — invalid HTML, but functionally inert (no JS hook/selector keys off it). Editing lib/ to add a caller-supplied id attr is out of this dev-only plan's files_modified boundary; logged in groups.ex's moduledoc rather than silently accepted or worked around with a non-real substitute"
  - "Fixtures section's :item deep-link filter matches a scenario NAME (e.g. \"approval_requested\"), not a domain — verified live: filtering to approval_requested renders 4833 bytes containing only that scenario, versus 51099 bytes unfiltered containing all 15"

patterns-established:
  - "Pattern: per-group prop adapter — when a real lib/ component's attr shape diverges from the shared DevLab.Fixtures scenario shape, write one small deterministic private function per group (not a second fixture catalog) that reshapes the derived fixture into the exact attrs the real component needs"
  - "Pattern: locked-copy-as-module-attribute — any UI-SPEC/D-27 locked microcopy string that a lab section must render verbatim (with or without an additive prepend) should live as a `@` module attribute literal, so the exact text is always grep-able in source regardless of runtime derivation"

requirements-completed: [LAB-02, FIXT-01]

coverage:
  - id: D1
    description: "Groups section renders the real approval inbox, workflow tree, workflow detail, connector drawer, and incident evidence lib/scoria_web/components/*.ex groups across domain-noun stress fixtures, each band anchored to its Phase-36 GROUP-* inventory ID; workflow detail organically exercises the nested replay/semantic evidence notebook groups"
    requirement: "LAB-02"
    verification:
      - kind: unit
        ref: "MIX_ENV=dev mix compile --warnings-as-errors"
        status: pass
      - kind: unit
        ref: "test/scoria_web/dev_lab_boundary_test.exs#guard #7: every canonical PRIM-*/GROUP-* inventory ID is referenced under dev/lab/** (D-08/D-32)"
        status: pass
      - kind: unit
        ref: "test/scoria_web/ds06_drift_guard_test.exs#dev/lab/** (Component Lab) has zero raw palette classes and zero raw hex colors (D-26)"
        status: pass
      - kind: other
        ref: "mix run (dev env): DevLab.Sections.Groups.groups(%{item: nil, class: nil}) rendered via Phoenix.LiveViewTest.rendered_to_string/1 with no exception (187800 bytes)"
        status: pass
    human_judgment: true
    rationale: "The automated checks prove compile-clean structure, inventory-ID anchoring, zero raw-palette/hex drift, and a crash-free runtime render — not that all 50 specimens (5 groups x 10 states) are visually correct/legible in a real browser across themes and viewports. That behavioral/browser proof is deferred to Plan 06 (lab.spec.mjs) once the route mounts in Plan 05, consistent with this plan's own <verification> block."
  - id: D2
    description: "Fixtures section lets a maintainer browse all 15 D-20/D-19 fixture scenarios grouped by domain and inspect each scenario's raw payload as evidence via the existing notebook/1 + raw_evidence/1 (open:false) group, with the exact D-27 Copy fixture payload / Open fixture matrix labels and empty/error copy"
    requirement: "FIXT-01"
    verification:
      - kind: unit
        ref: "MIX_ENV=dev mix compile --warnings-as-errors"
        status: pass
      - kind: unit
        ref: "test/scoria_web/dev_lab_boundary_test.exs (9/9, incl. D-11 state and D-20 scenario name coverage scans)"
        status: pass
      - kind: other
        ref: "mix run (dev env): DevLab.Sections.FixturesView.fixtures_view/1 rendered 51099 bytes containing the exact locked D-27 empty-state body, \"Copy fixture payload\", and \"Open fixture matrix\" strings verbatim; :item=\"approval_requested\" deep-link filter rendered 4833 bytes containing only that scenario"
        status: pass
      - kind: other
        ref: "mix run (dev env): forced scenario_result/1 failure path (rescue clause) renders \"Lab fixture failed to render: DevLab.Fixtures.scenario(:not_a_real_scenario) / FunctionClauseError. Check the fixture builder and component attrs before changing runtime UI.\" — locked wrapper intact, detail prepended per acceptance criteria"
        status: pass
    human_judgment: true
    rationale: "Automated checks prove structural coverage, exact copy strings, and both the empty-scenario and forced-failure render paths work without crashing — not that the fixture catalog reads as genuinely useful/scannable to a maintainer in a real browser. That judgment, plus full browser proof, is deferred to Plan 06 once the route mounts in Plan 05."

duration: ~30min
completed: 2026-07-02
status: complete
---

# Phase 37 Plan 03: Groups And Fixtures Catalog Sections Summary

**Groups renders the real approval-inbox/workflow-tree/workflow-detail/connector-drawer/incident-evidence lib/ components across all 10 D-11 states via deterministic per-group prop adapters; Fixtures browses all 15 domain-noun scenarios grouped by domain with raw-payload evidence and the locked D-27 empty/error copy.**

## Performance

- **Duration:** ~30 min
- **Started:** 2026-07-02T20:40:03Z
- **Completed:** 2026-07-02T20:53:11Z
- **Tasks:** 2
- **Files modified:** 2 (both created)

## Accomplishments

- `DevLab.Sections.Groups` (`dev/lab/sections/groups.ex`): renders the REAL `ScoriaWeb.ApprovalInboxComponent`, `WorkflowTreeComponent`, `WorkflowDetailPanelComponent`, `ConnectorDetailDrawerComponent`, and `IncidentEvidenceComponent` modules — not stand-ins — across all 10 D-11 states via `states_band/1`, each band anchored to its Phase-36 `GROUP-*` inventory ID. Five small deterministic adapter functions reshape `DevLab.Fixtures.scenario/1` domain-noun payloads into the exact prop shapes each real component expects (e.g. `IncidentEvidenceComponent`'s deeply-nested `health_rollup`/`budget`/`breaker`/`incidents` evidence map, which has no graceful nil-default path in the real component).
- Rendering `WorkflowDetailPanelComponent` organically exercises `GROUP-REPLAY-EVIDENCE-NOTEBOOK-COMPONENT` and `GROUP-SEMANTIC-EVIDENCE-NOTEBOOK-COMPONENT` nested inside it — the same composition the real dashboard uses — satisfying D-09's "evidence notebook groups" coverage without mounting them a second time in isolation.
- `DevLab.Sections.FixturesView` (`dev/lab/sections/fixtures_view.ex`): lists all 15 D-20/D-19 scenarios grouped by the 8 D-19 domains (approvals, incidents, reviews, datasets, workflow, connectors, prompts, evals), each with inventory/risk-ref `<.id>` chips and a raw-payload disclosure reusing the existing `notebook/1` + `raw_evidence/1` (`open: false`) evidence group — no new disclosure widget. The `Copy fixture payload` label wires through `raw_evidence`'s `copy_label` attr; the three `_empty` scenarios (`review_queue_empty`/`dataset_empty`/`prompt_registry_empty`) render the exact locked D-27 empty-state body via their own `empty_copy` field.
- A defensive `scenario_result/1` render-failure path (function-level `rescue`) proves the locked D-27 error wrapper renders verbatim with an optional prepended component/fixture detail, without altering the locked copy — verified live by forcing a failing scenario name.
- Both files compile clean under `MIX_ENV=dev mix compile --warnings-as-errors`, pass all 13 boundary/drift guard tests, and render without exception at runtime (verified via `Phoenix.LiveViewTest.rendered_to_string/1` in a `mix run` script, since `test/`'s `elixirc_paths` excludes `dev/`).

## Task Commits

Each task was committed atomically:

1. **Task 1: Build the Groups section for recurring component groups under stress** - `0153cb3` (feat)
2. **Task 2: Build the Fixtures catalog browser section** - `4aba5ff` (feat)

**Plan metadata:** _pending (this commit)_

## Files Created/Modified

- `dev/lab/sections/groups.ex` - `DevLab.Sections.Groups.groups/1`: 5 group panels (approval inbox, workflow tree, workflow detail, connector drawer, incident evidence), each a `states_band/1` over a real `lib/scoria_web/components/*.ex` module; 5 private deterministic prop adapters
- `dev/lab/sections/fixtures_view.ex` - `DevLab.Sections.FixturesView.fixtures_view/1`: domain-grouped scenario browser, private `scenario_specimen/1` component, `scenario_result/1` defensive rescue wrapper, locked D-27 copy module attributes

## Decisions Made

- Groups feeds each band from ONE base domain-noun scenario per group via `states_for/2`'s structural 10-state derivation (matching the Plan 02 Primitives convention) — full dual-scenario (normal + empty/error) domain coverage is deliberately the Fixtures section's responsibility instead, keeping the two sections' scope distinct.
- `IncidentEvidenceComponent`'s nested evidence shape required a full deterministic literal-filler adapter (no graceful defaults exist in the real component, unlike the other four groups) — every filler value is domain-realistic and constant, never random or DB-fetched (D-17).
- Documented rather than fixed: `ApprovalInboxComponent`'s hardcoded internal `<.table id="approvals">` repeats across all ten stacked state rows — invalid HTML but functionally inert; fixing it would mean editing `lib/`, out of this plan's `files_modified` boundary.
- Fixtures section's `:item` deep-link filter matches a scenario name (not a domain), verified live to correctly narrow rendered output from 51099 bytes (all 15 scenarios) to 4833 bytes (one scenario).

## Deviations from Plan

None — plan executed exactly as written. The per-group adapter functions, the single-base-scenario convention (vs. paired scenarios), and the `IncidentEvidenceComponent` full-shape adapter were implementation judgment calls made while satisfying the plan's explicit "renders the real dashboard component modules... fed by `DevLab.Fixtures.scenario/1`" key link, not deviations from any explicit plan instruction.

## Issues Encountered

- `WorkflowDetailPanelComponent`'s `checkpoint`/`selected_comparison_entry`/`promotion_context` attrs are typed `:map` with `default: nil` — Phoenix.Component's compile-time attr validator rejects an explicit `nil` literal passed to a `:map`-typed attr (warning-as-error) even though the attr's own default is `nil`. Fixed by omitting those three attrs entirely from the call site so they fall through to their declared defaults, rather than passing `nil` explicitly. No scope change; resolved before the first commit.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `DevLab.Sections.Groups.groups/1` and `DevLab.Sections.FixturesView.fixtures_view/1` are stable public function components, ready for `DevLab.LabLive` to mount once Plan 05 wires the `/scoria/_lab` route.
- Both modules' optional `item` attr is the seam Plan 05's `/scoria/_lab/groups/:item` and `/scoria/_lab/fixtures/:item` routes need — no further change to either file required to support deep-linking (verified live: `item` filtering already narrows rendered output correctly for both).
- Plan 01's guard #7 inventory-ID coverage floor and the D-26 `dev/lab/**` raw-hex/raw-palette guard both remain green with these two new files in the scan path (13/13 tests).
- Full open/close/focus/dismissal overlay stress and dense-approvals-with-toast/mobile-nav/command-palette flow probes are explicitly NOT covered here (D-10) — that is Plan 04's `Overlays` IA section.
- Behavioral/browser render proof (does every one of the 50 Groups specimens and 15 Fixtures scenarios actually look right and stay legible across themes/viewports in a real browser) is deferred to Plan 06 (`lab.spec.mjs`) once the route is reachable — this plan's automated checks and `mix run` smoke renders only prove compile-clean structure, inventory-ID anchoring, drift-guard cleanliness, and crash-free server-side rendering, consistent with this plan's own `<verification>` block.
- No blockers.

## Self-Check: PASSED

Both claimed files found on disk (`dev/lab/sections/groups.ex`, `dev/lab/sections/fixtures_view.ex`).
Both task commit hashes (`0153cb3`, `4aba5ff`) found in `git log`.

---
*Phase: 37-dev-component-lab-and-stress-fixtures*
*Completed: 2026-07-02*
