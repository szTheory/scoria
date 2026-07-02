---
phase: 37-dev-component-lab-and-stress-fixtures
plan: 04
subsystem: ui
tags: [phoenix-liveview, dev-only-tooling, component-lab, responsive, overlays, elixir]

# Dependency graph
requires:
  - phase: 37-01
    provides: DevLab.Fixtures.scenario/1, DevLab.Fixtures.states_for/2, DevLab.Fixtures.inventory_id/1
provides:
  - DevLab.Sections.Viewports (dev/lab/sections/viewports.ex) — viewports/1: the six D-13 proof-target viewport-simulator frames (320/375/768/1024/1440/wide), each constraining the shared dense table specimen
  - DevLab.Sections.Overlays (dev/lab/sections/overlays.ex) — overlays/1: the seven curated D-10 flow probes (dense-approvals-with-toast, mobile summary, drawer/modal, command palette, mobile nav, copy-control, long-evidence)
affects: [37-05, 37-06]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Viewport simulator frame: inline width/max-width style on a wrapper div around existing panel/1+table/1, never a new breakpoint token"
    - "Overlay probe reuse: existing scoria.js hooks are attached via their existing data-attribute contract (data-command-open, data-mobile-nav-open/close) rather than re-wired — the same document-level listeners already driving production dashboard chrome fire for lab-authored markup with zero new JS"
    - "Curated-probe ceiling/floor enforcement: exactly seven D-10 panels, each with an inline HEEx numbered comment (1..7) so the count is visually auditable in source, not just in the moduledoc"

key-files:
  created:
    - dev/lab/sections/viewports.ex
    - dev/lab/sections/overlays.ex
  modified: []

key-decisions:
  - "Viewports' dense table specimen reuses DevLab.Fixtures.states_for(:table, :dataset_promoted)'s :dense row verbatim (the same fixture DevLab.Sections.Primitives already renders for the table primitive band) rather than deriving a second dense dataset"
  - "Overlays' dense-approvals probe builds 8 deterministic rows from the two existing approval_requested/approval_denied scenarios (id/inserted_at/workflow_run_id/arguments_preview enrichment, matching DevLab.Sections.Groups' approval_inbox_fixture/1 shape) rather than adding a new fixture scenario, since files_modified is scoped to the two section files only"
  - "The long-unbroken-evidence probe reuses the approval_requested scenario's own policy_name field (already a long, whitespace-free dotted/dashed string) instead of inventing a new literal in this file"
  - "Command palette probe rows point at /scoria/_lab/<section> paths (forward-referencing the Plan 05 route), matching the same forward-reference convention DevLab.Sections.Groups/Primitives already use for their :item deep-link filters"
  - "Mobile nav probe reuses the real ScoriaWeb.Layouts.nav_groups/0 dashboard nav data rather than inventing lab-only nav content, since the probe is proving the MobileNav hook mechanics (open/close/focus-trap), not new content"

patterns-established:
  - "Pattern: viewport-simulator frame (viewport_frame_style/1) — inline width-only constraint on a wrapper div, reused by any future lab section needing a width-boxed specimen"
  - "Pattern: curated D-10 probe panel — one <.panel> per probe, an evidence <.id> chip in :actions citing the relevant PRIM-*/GROUP-*/RISK-* reference, and an explicit 'this does not fix X' sentence in the body for any probe tied to a deferred Phase 38/39 risk"

requirements-completed: [LAB-02]

coverage:
  - id: D1
    description: "Viewports section frames the six D-13 proof-target widths (320/375/768/1024/1440/wide) with exact maintainer labels and no device marketing names, constraining one shared dense table specimen via inline width style only (no new breakpoint token)"
    requirement: "LAB-02"
    verification:
      - kind: unit
        ref: "MIX_ENV=dev mix compile --warnings-as-errors"
        status: pass
      - kind: unit
        ref: "test/scoria_web/dev_lab_boundary_test.exs (9 tests, 0 failures)"
        status: pass
      - kind: unit
        ref: "test/scoria_web/ds06_drift_guard_test.exs (4 tests, 0 failures — zero raw hex/palette in dev/lab/**)"
        status: pass
    human_judgment: true
    rationale: "Automated checks prove compile cleanliness, label-string exactness, and zero raw-hex/palette drift, but not visual correctness of the responsive frame layout in a real browser — that behavioral proof is deferred to Plan 06's Playwright suite once the lab route mounts in Plan 05. Flag for a visual walkthrough once /scoria/_lab is reachable."
  - id: D2
    description: "Overlays section provides EXACTLY the seven curated D-10 flow probes (dense-approvals-with-toast, mobile table/list summary, drawer/modal focus & dismissal, command palette, mobile nav, raw-evidence copy controls, long unbroken evidence payload), reusing existing scoria.js hooks/data-attributes and the runtime's own overlay dismiss contract with no new JS, no new motion duration, and no toast-legibility fix attempted"
    requirement: "LAB-02"
    verification:
      - kind: unit
        ref: "MIX_ENV=dev mix compile --warnings-as-errors"
        status: pass
      - kind: unit
        ref: "test/scoria_web/dev_lab_boundary_test.exs (9 tests, 0 failures)"
        status: pass
      - kind: unit
        ref: "test/scoria_web/ds06_drift_guard_test.exs (4 tests, 0 failures — zero raw hex/palette in dev/lab/**)"
        status: pass
    human_judgment: true
    rationale: "Automated checks prove compile cleanliness, exact probe count/content by source inspection, and zero raw-hex/palette drift, but not that the CommandPalette/MobileNav hooks and drawer/modal dismiss contract actually behave correctly in a live browser (focus trap, Escape dismiss, toast overlap visibility) — that behavioral proof is deferred to Plan 06's Playwright suite once the lab route mounts in Plan 05."

duration: ~15min
completed: 2026-07-02
status: complete
---

# Phase 37 Plan 04: Viewports and Overlays Cross-Cutting Probe Sections Summary

**Six D-13 viewport-simulator frames sharing one dense table specimen, plus exactly seven curated D-10 overlay/flow probes (dense-approvals-with-toast, mobile summary, drawer/modal, command palette, mobile nav, copy-control, long-evidence) reusing scoria.js hooks with zero new JS.**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-07-02T20:57:15Z (STATE.md session marker)
- **Completed:** 2026-07-02T21:09:27Z
- **Tasks:** 2
- **Files modified:** 2 (both new)

## Accomplishments

- `DevLab.Sections.Viewports` (`dev/lab/sections/viewports.ex`): `viewports/1` renders the six D-13 proof-target widths — `320px — small mobile`, `375px — mobile`, `768px — tablet`, `1024px — small desktop`, `1440px — desktop`, `Wide desktop` — verbatim, each frame constraining the same `states_for(:table, :dataset_promoted)` `:dense` specimen via inline `width`/`max-width` style only (no new breakpoint/spacing/type token, no raw hex).
- `DevLab.Sections.Overlays` (`dev/lab/sections/overlays.ex`): `overlays/1` renders exactly the seven curated D-10 probes: (1) dense approvals with a `.scoria-toast-region`-stacked toast overlay (RISK-TOAST-LEGIBILITY stress fixture, not fixed here), (2) the same inbox framed at 375px to inspect the `table/1` mobile_summary collapse (RISK-RESPONSIVE-SCAN), (3) a genuinely open `<.drawer>` + `<.modal>` pair proving the existing dismiss contract (RISK-OVERLAY-FOCUS), (4) an embedded `<.command_palette>` wired to the existing `CommandPalette` hook via `data-command-open`, (5) an off-canvas mobile nav wired to the existing `MobileNav` hook via `data-mobile-nav-open`/`data-mobile-nav-close`, rendered against the real `ScoriaWeb.Layouts.nav_groups/0` data, (6) a `<.raw_evidence copyable copy_label="Copy fixture payload">` block over an approval fixture payload, and (7) the `approval_requested` scenario's own `policy_name` rendered inside the existing evidence-notebook group as a genuinely long, whitespace-free evidence string.
- Both modules build ONLY from existing `ScoriaWeb.UI` primitives + `--scoria-*` tokens; no new JS, no new CSS, no new motion duration was introduced.

## Task Commits

Each task was committed atomically:

1. **Task 1: Build the Viewports simulator section** - `83529b9` (feat)
2. **Task 2: Build the Overlays curated flow-probe section** - `53d186f` (feat)

**Plan metadata:** _pending (this commit)_

## Files Created/Modified

- `dev/lab/sections/viewports.ex` - `DevLab.Sections.Viewports`: `viewports/1` (six D-13 proof-target frames)
- `dev/lab/sections/overlays.ex` - `DevLab.Sections.Overlays`: `overlays/1` (the seven curated D-10 flow probes)

## Decisions Made

- Reused Plan 02's exact `states_for(:table, :dataset_promoted)` `:dense` fixture for all six Viewports frames rather than deriving a second dense dataset — keeps the D-06 spine as the single source of "what dense data looks like."
- Built the dense-approvals probe's 8 rows as deterministic literals from the two existing approval scenarios (mirroring `DevLab.Sections.Groups.approval_inbox_fixture/1`'s enrichment shape) instead of touching `dev/lab/fixtures.ex`, since this plan's `files_modified` is scoped to the two section files only.
- Sourced the "long unbroken evidence payload" probe from the `approval_requested` scenario's real `policy_name` field (already long and whitespace-free) rather than inventing a new literal string.
- Command palette probe rows forward-reference `/scoria/_lab/<section>` paths — the Plan 05 route — matching the same forward-reference convention `DevLab.Sections.Groups`/`Primitives` already use for their `:item` deep-link filters.
- Mobile nav probe renders the real `ScoriaWeb.Layouts.nav_groups/0` dashboard nav data (a `dev/` -> `lib/` read, which is the permitted direction under D-21) instead of inventing lab-only nav content, since the probe exists to prove the `MobileNav` hook's open/close/focus-trap mechanics, not to author new navigation copy.
- Both open overlay specimens (drawer/modal in probe 3) use `on_dismiss="lab-noop-dismiss"`, matching the exact string convention `DevLab.Sections.Primitives` already established for its always-open `:normal`-row drawer/modal specimens — a single shared no-op event name across the phase rather than a per-file invention.

## Deviations from Plan

None - plan executed exactly as written. Both files compile clean under `MIX_ENV=dev --warnings-as-errors`, contain the exact D-13 label strings and exactly seven D-10 probes, introduce no new JS/CSS/motion token, and the Plan 01 boundary + DS-06 drift guards both pass unchanged.

## Issues Encountered

- Broad `SCORIA_DB_PORT=55432 mix test --warnings-as-errors` (run for extra confidence beyond this plan's own verify command) reported 3 failures on a background run (`Scoria.CiPolicyContractTest`, `Scoria.WarningInventory.CaptureParityTest`, `Scoria.SupportCopilotGalleryTest`) — the same pre-existing/unrelated failures already logged in `37-01-SUMMARY.md`'s Issues Encountered and `.planning/phases/37-dev-component-lab-and-stress-fixtures/deferred-items.md`. A second local re-run instead surfaced a different transient failure (`SupportCopilotWeb.OrchestratorProducerTest`, an async producer-path race), confirming this is pre-existing suite flakiness unrelated to `dev/lab/**` (neither new file is referenced by `test/`'s `elixirc_paths`, and neither touches orchestrator/producer code). Not fixed here — out of this plan's scope (Rule 1 scope boundary: only issues directly caused by this task's changes are in scope).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `DevLab.Sections.Viewports.viewports/1` and `DevLab.Sections.Overlays.overlays/1` are ready for Plan 05 (`DevLab.LabLive` + `dev_router.ex` wiring) to mount as the `Viewports`/`Overlays` IA sections at `/scoria/_lab/viewports` and `/scoria/_lab/overlays`.
- Plan 05 must define a `handle_event("lab-noop-dismiss", ...)` clause (or equivalent) in `DevLab.LabLive` — both this plan's open drawer/modal specimens and Plan 02's Primitives specimens already emit that event name; without a matching clause, clicking a dismiss control in either section will crash the LiveView process (not a defect introduced here — the same convention Plan 02 already established, now shared by a second file).
- Plan 06's Playwright suite (`priv/dev/e2e/lab.spec.mjs`) is the deferred behavioral proof for both sections per this plan's own `<verification>` block: real `page.setViewportSize` sweeps for Viewports, and real click/focus/Escape interaction proof for the Overlays' command palette, mobile nav, and drawer/modal probes. Both `coverage:` entries above are flagged `human_judgment: true` for exactly this reason — source-level correctness is proven now, live-browser behavior is proven in Plan 06.
- No blockers.

## Self-Check: PASSED

All claimed files found on disk (`dev/lab/sections/viewports.ex`, `dev/lab/sections/overlays.ex`,
this SUMMARY.md). Both task commit hashes (`83529b9`, `53d186f`) found in `git log`.

---
*Phase: 37-dev-component-lab-and-stress-fixtures*
*Completed: 2026-07-02*
