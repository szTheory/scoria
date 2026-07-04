---
phase: 37-dev-component-lab-and-stress-fixtures
plan: 05
subsystem: ui
tags: [phoenix-liveview, dev-only-tooling, design-system, component-lab, elixir, routing]

# Dependency graph
requires:
  - phase: 37-01
    provides: DevLab.Fixtures, DevLab.Sections.States (states_band/1, states_section/1) — indirectly, via the section modules this plan mounts
  - phase: 37-02
    provides: DevLab.Sections.Foundations.foundations/1, DevLab.Sections.Primitives.primitives/1
  - phase: 37-03
    provides: DevLab.Sections.Groups.groups/1, DevLab.Sections.FixturesView.fixtures_view/1
  - phase: 37-04
    provides: DevLab.Sections.Viewports.viewports/1, DevLab.Sections.Overlays.overlays/1, the "lab-noop-dismiss" event convention
provides:
  - "/scoria/_lab" route (dev/dev_router.ex) — mounted only in the dev-only router, outside scoria_dashboard/2
  - DevLab.LabLive (dev/lab/lab_live.ex) — the single param-driven LiveView rendering the D-07 IA shell and dispatching to all seven section modules
affects: [37-06]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Module-scope Phoenix.LiveView.Router import in a router file whose only prior live/live_session availability was macro-local (Pitfall 3) — import only: [live: 3, live_session: 3], the exact arities actually used, to avoid an unused-import warning under --warnings-as-errors"
    - "Single param-driven LiveView with a fixed compile-time @section_slugs allowlist (derived from one @sections source-of-truth list) for handle_params/3 route-param validation — never String.to_atom/1 on the raw param (V5)"
    - "Nav-rail-derives-from-IA-list: @sections is the single place the D-07 order/labels are declared; both the nav rail and the allowlist derive from it, so they cannot drift apart"
    - "Conditional component dispatch via :if on <.component /> tags rather than a case/cond helper function — matches the plan's Pattern 2 example and keeps render/1 a flat, auditable list of all seven sections"
    - "Shared handle_event(\"lab-noop-dismiss\", ...) no-op clause consuming the event name convention two earlier plans (37-02, 37-04) already emit from their always-open drawer/modal specimens"

key-files:
  created:
    - dev/lab/lab_live.ex
  modified:
    - dev/dev_router.ex

key-decisions:
  - "import Phoenix.LiveView.Router, only: [live: 3, live_session: 3] (not live: 4) — the three new routes all use the live/3 form (path, module, action), so importing live/4 as suggested by the plan's illustrative example produced an unused-import warning under --warnings-as-errors; trimmed to the arities actually called"
  - "Primary command \"Run lab proof\" patches to /scoria/_lab/states (the States IA section — the canonical ten-state vocabulary overview) rather than performing any server-side action. Neither 37-CONTEXT.md D-27 nor 37-RESEARCH.md specifies primary-command behavior beyond its label; running the actual browser proof (Playwright, mix scoria.ui.e2e) from inside a request handler would be an architectural/security decision out of this plan's scope (Rule 4 territory), so the command instead navigates to the section that most directly demonstrates the lab's proof value. Secondary command \"Open fixture matrix\" patches to /scoria/_lab/fixtures per the plan's explicit instruction"
  - "Both header commands render as <.link patch=...> styled with the existing scoria-button / scoria-button--primary / scoria-button--ghost CSS classes (already defined for ScoriaWeb.UI.button/1 in assets/css/04-components.css) rather than <.button>, since <.button> only emits a <button type=...> element and these are navigational — the same class-reuse-on-<a> pattern ScoriaWeb.UI.attention_card/1 already establishes elsewhere in the codebase"
  - "item is passed only to the three section components whose attr contract declares it (primitives/1, groups/1, fixtures_view/1); foundations/1, states_section/1, viewports/1, overlays/1 take no item attr and are called with none, verified against each section file's actual attr() declarations rather than assumed from the plan prose"
  - "Dispatch uses :if={@section == \"...\"} on each imported <.component /> tag (Pattern 2's own style) rather than a private case-based section_body/1 helper — keeps render/1 a single flat, greppable list of all seven sections with no indirection"

patterns-established:
  - "Pattern: single-source IA list (@sections) that both a nav rail and a route-param allowlist derive from, for any future multi-section param-driven LiveView in this codebase"

requirements-completed: [LAB-01, LAB-02]

coverage:
  - id: D1
    description: "The lab is reachable in local dev at /scoria/_lab, mounted only by ScoriaWeb.DevRouter, entirely outside the public scoria_dashboard/2 macro"
    requirement: "LAB-01"
    verification:
      - kind: unit
        ref: "MIX_ENV=dev mix compile --warnings-as-errors"
        status: pass
      - kind: unit
        ref: "test/scoria_web/dev_lab_boundary_test.exs (9/9) — public dashboard macro never mounts the lab, dashboard nav/command palette never link it"
        status: pass
      - kind: other
        ref: "git diff --stat lib/scoria_web/router.ex — empty (no change)"
        status: pass
    human_judgment: true
    rationale: "Automated checks prove structural mounting (dev-only compile boundary, zero lib/ router diff, zero public-macro/nav reference) but not that the route is actually reachable and renders correctly in a real running browser session — that is Plan 06's formal browser proof (lab.spec.mjs / mix scoria.ui.e2e), consistent with this plan's own <verification> block ('Manual smoke: make dev... formal browser proof is Plan 06')."
  - id: D2
    description: "DevLab.LabLive renders the D-07 IA (Foundations/Primitives/Groups/States/Viewports/Overlays/Fixtures) with the exact D-27 page copy, dispatching to the section modules from a fixed compile-time allowlist; :section/:item route params are never String.to_atom/1'd"
    requirement: "LAB-02"
    verification:
      - kind: unit
        ref: "MIX_ENV=dev mix compile --warnings-as-errors"
        status: pass
      - kind: unit
        ref: "grep -n \"String.to_atom(\" dev/dev_router.ex dev/lab/lab_live.ex — zero matches"
        status: pass
      - kind: other
        ref: "mix run (dev env): DevLab.LabLive.render/1 called directly for all seven section values via Phoenix.LiveViewTest.rendered_to_string/1 — all seven rendered without exception (14770-189823 bytes each); a second run confirmed the exact D-27 title, subtitle, \"Run lab proof\", \"Open fixture matrix\" strings and all seven exact D-07 nav labels are present in the rendered HTML"
        status: pass
      - kind: unit
        ref: "test/scoria_web/ds06_drift_guard_test.exs (4/4) — zero raw hex/raw palette classes in dev/lab/**"
        status: pass
    human_judgment: true
    rationale: "The mix run smoke proves every section dispatches without a runtime exception and the exact locked copy/labels render — not that the assembled shell is visually correct, legible, or navigable via real router-driven live_patch/handle_params round-trips (patch clicks, browser back/forward, live socket join) in an actual browser. That behavioral proof is Plan 06's job (lab.spec.mjs) per this plan's own <verification> block."

duration: ~25min
completed: 2026-07-02
status: complete
---

# Phase 37 Plan 05: Mount The Lab (Route + LabLive Shell) Summary

**Mounted `/scoria/_lab` in the dev-only router (module-scope `Phoenix.LiveView.Router` import, new scope textually separate from the public `scoria_dashboard/2` macro) and built `DevLab.LabLive` — the single param-driven LiveView rendering the D-07 IA shell with exact D-27 copy and dispatching to all seven Wave 1-2 section modules via a fixed compile-time param allowlist.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-07-02T21:12:46Z (STATE.md session marker)
- **Completed:** 2026-07-02T21:18:32Z
- **Tasks:** 2
- **Files modified:** 2 (1 modified, 1 created)

## Accomplishments

- `dev/dev_router.ex`: added a module-scope `import Phoenix.LiveView.Router, only: [live: 3, live_session: 3]` (Pitfall 3 — `live`/`live_session` were previously only macro-local to `scoria_dashboard/2`'s own quote block) and a new `scope "/scoria/_lab"` block, textually separate from the existing `scope "/" do ... scoria_dashboard("/scoria") end`, reusing the `:browser` pipeline verbatim (including `put_demo_tenant`). `live_session :scoria_lab, root_layout: {ScoriaWeb.Layouts, :root}` wires three routes (`/`, `/:section`, `/:section/:item`) to `DevLab.LabLive :index`. `lib/scoria_web/router.ex` is untouched (verified via `git diff --stat`).
- `dev/lab/lab_live.ex` (`DevLab.LabLive`): `use Phoenix.LiveView, layout: {ScoriaWeb.Layouts, :root}`. A single `@sections` module attribute is the sole source of truth for the D-07 IA order/labels (`Foundations`, `Primitives`, `Groups`, `States`, `Viewports`, `Overlays`, `Fixtures`); both the nav rail and the `@section_slugs` allowlist derive from it so they cannot drift apart. `handle_params/3` resolves `params["section"]` against that fixed compile-time allowlist (`section when section in @section_slugs`), defaulting unknown/nil to `"foundations"` — no `String.to_atom/1` on the unvalidated param anywhere in either changed file (V5, T-37-04). `render/1` builds the shell from `ScoriaWeb.UI.page_section/1` with the exact D-27 title (`Component Lab`), subtitle, and two commands (`Run lab proof`, `Open fixture matrix`), then dispatches via `:if={@section == "..."}` to whichever of the seven imported section components (`foundations/1`, `primitives/1`, `groups/1`, `states_section/1`, `viewports/1`, `overlays/1`, `fixtures_view/1`) matches, passing `item` only to the three that declare it.
- `handle_event("lab-noop-dismiss", _params, socket)` no-op clause added — consumed by the always-open drawer/modal specimens both `DevLab.Sections.Primitives` (37-02) and `DevLab.Sections.Overlays` (37-04) already emit; without this clause, clicking either specimen's dismiss control would crash the LiveView process.

## Task Commits

Each task was committed atomically:

1. **Task 1: Mount the dev-only lab route in dev/dev_router.ex** - `476ba08` (feat)
2. **Task 2: Build the DevLab.LabLive shell and section dispatch** - `900768e` (feat)

**Plan metadata:** _pending (this commit)_

## Files Created/Modified

- `dev/dev_router.ex` - added module-scope `Phoenix.LiveView.Router` import and the new `scope "/scoria/_lab"` / `live_session :scoria_lab` block
- `dev/lab/lab_live.ex` - `DevLab.LabLive`: `mount/3`, `handle_params/3` (allowlist-validated), `handle_event/3` (`lab-noop-dismiss`), `render/1` (D-07 nav rail + D-27 header + seven-way section dispatch)

## Decisions Made

- `import Phoenix.LiveView.Router, only: [live: 3, live_session: 3]` — trimmed the plan's illustrative `live: 4` off the import list since all three new routes use the `live/3` form; keeping the unused arity would fail `--warnings-as-errors`.
- Primary command "Run lab proof" patches to `/scoria/_lab/states` (the States IA section, the canonical ten-state vocabulary overview) since neither `37-CONTEXT.md` D-27 nor `37-RESEARCH.md` specifies concrete primary-command behavior beyond its label, and triggering the actual Playwright/`mix scoria.ui.e2e` proof from inside a request handler would be an architectural decision outside this plan's scope. Secondary command "Open fixture matrix" patches to `/scoria/_lab/fixtures` per the plan's explicit instruction.
- Both header commands render as `<.link patch=...>` styled with the existing `scoria-button`/`scoria-button--primary`/`scoria-button--ghost` CSS classes (already defined for `ScoriaWeb.UI.button/1`) rather than `<.button>` (which only emits a `<button>`, not a navigable link) — the same class-reuse-on-`<a>` pattern `ScoriaWeb.UI.attention_card/1` already establishes elsewhere in this codebase, so no new primitive was introduced.
- `item` is passed only to `primitives/1`, `groups/1`, `fixtures_view/1` — the three section components whose `attr()` declarations actually accept it (verified by reading each section file directly, not assumed from plan prose); `foundations/1`, `states_section/1`, `viewports/1`, `overlays/1` are called with no `item`.
- Dispatch uses `:if={@section == "..."}` on each imported `<.component />` tag (matching Pattern 2's own illustrative style) rather than a private `case`-based helper function, keeping `render/1` a single flat, greppable list of all seven sections.

## Deviations from Plan

None — plan executed as written. The primary-command destination and the `live: 4` import trim were implementation judgment calls filling in gaps the plan and its cited context left as Claude's Discretion, not deviations from any explicit plan instruction.

## Issues Encountered

- The smoke-test `mix run` script (run twice, both times deleted afterward — not committed) boots the full dev app including Oban and `Scoria.Workflows.Reconciler`, which logged repeated `Postgrex.Error (undefined_table)` / GenServer termination noise because no local Postgres was running for this session. Unrelated to `dev/dev_router.ex` or `dev/lab/lab_live.ex` (neither file touches DB access, Oban, or workflow reconciliation); the actual `DevLab.LabLive.render/1` calls in the same script all succeeded regardless. No code change required.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `/scoria/_lab` is now structurally mounted and `DevLab.LabLive` dispatches to all seven section modules with allowlist-validated params — Plan 06's formal browser proof (`priv/dev/e2e/lab.spec.mjs` via `mix scoria.ui.e2e`) can now drive the real route with `make dev` running.
- The `lab-noop-dismiss` event handler this plan adds is the piece both `37-02-SUMMARY.md` and `37-04-SUMMARY.md` flagged as required before their drawer/modal/overlay specimens could be clicked without crashing the LiveView — that requirement is now satisfied.
- `LAB-01` is now genuinely reachable (not just structurally satisfied, per `37-01-SUMMARY.md`'s caveat) — Plan 06's browser proof is the remaining verification step for full confidence.
- No blockers.

## Self-Check: PASSED

Both claimed files found on disk (`dev/dev_router.ex`, `dev/lab/lab_live.ex`).
Both task commit hashes (`476ba08`, `900768e`) found in `git log`.

---
*Phase: 37-dev-component-lab-and-stress-fixtures*
*Completed: 2026-07-02*
