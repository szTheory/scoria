---
phase: 16-motion-responsive-theme-parity
plan: 03
subsystem: ui/css
tags: [responsive, css, grid, mobile-first, design-system, heex]
requires:
  - phase: "16-02"
    provides: [table-overflow-viewport, mobile-summary-slot]
provides:
  - named-responsive-grid-classes
  - scoria-evidence-split
  - scoria-page-split
  - scoria-page-split--xl-reverse
  - zero-unsupported-responsive-utilities
affects: [assets/css/04-components.css, lib/scoria_web/live/incidents_live/index.ex, lib/scoria_web/live/review_queue_live.ex, lib/scoria_web/live/workflow_live/show.ex, lib/scoria_web/components/incident_evidence_component.ex, lib/scoria_web/components/semantic_evidence_notebook_component.ex, lib/scoria_web/components/replay_evidence_notebook_component.ex]
tech-stack:
  added: []
  patterns: [mobile-first-grid-primitive, named-design-system-grid-class, fr-ratio-split-component-class]
key-files:
  created: []
  modified:
    - assets/css/04-components.css
    - lib/scoria_web/live/incidents_live/index.ex
    - lib/scoria_web/live/review_queue_live.ex
    - lib/scoria_web/live/workflow_live/show.ex
    - lib/scoria_web/components/incident_evidence_component.ex
    - lib/scoria_web/components/semantic_evidence_notebook_component.ex
    - lib/scoria_web/components/replay_evidence_notebook_component.ex
key-decisions:
  - ".scoria-evidence-split collapses near-identical xl fr-ratios (1.25fr/0.9fr and 1.1fr/0.9fr) into one shared class serving all three evidence callsites (D-33 dividend)"
  - ".scoria-page-split uses minmax(20rem, 0.8fr) to preserve the detail-rail minimum width while sharing the primitive across workflow show and review queue (D-33)"
  - "sm:grid-cols-3 replaced with supported md:grid-cols-3 utility (shifts 3-up to 768px breakpoint, stays in 06-utilities.css scope)"
  - "workflow_live/show.ex mobile D-11 source order confirmed correct (trace list first, detail panel second) — no markup reorder needed"
requirements-completed: [MOTION-03]
duration: ~8min
completed: "2026-06-13"
---

# Phase 16 Plan 03: Unsupported Responsive Grid Utilities Replacement Summary

**Seven unsupported `sm:grid-cols-*` / `grid-cols-[...]` callsites replaced with named mobile-first design-system grid classes (`.scoria-evidence-split`, `.scoria-page-split`, `.scoria-page-split--xl-reverse`) that actually resolve to CSS at md/lg/xl breakpoints.**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-06-13T06:50:00Z
- **Completed:** 2026-06-13T07:00:00Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added three named responsive grid primitives to `04-components.css` — all mobile-first (single-column default), scoped under `.scoria-root`, using `--scoria-space-*` token gaps, no raw hex colors
- Replaced all 7 unsupported responsive utility callsites (`sm:grid-cols-*`, `xl:grid-cols-[...]`, `lg:grid-cols-[...]`) under `lib/scoria_web/` — grep returns zero matches
- Collapsed three near-identical evidence grid ratios into one shared `.scoria-evidence-split` class (D-33 dividend paying across incident, semantic, and replay evidence components)
- Verified D-11 mobile stack order in `workflow_live/show.ex`: trace/span list appears before selected detail in source order — correct single-column mobile stacking without markup reorder

## Task Commits

1. **Task 1: Add named/general responsive grid CSS** - `7c90246` (feat)
2. **Task 2: Replace all 7 unsupported responsive utility callsites** - `dfdf557` (feat)

## Files Created/Modified

- `assets/css/04-components.css` — appended `.scoria-evidence-split` (xl, 1.25fr/0.9fr), `.scoria-page-split` (lg, minmax detail rail), `.scoria-page-split--xl-reverse` (xl, 0.85fr/1.15fr)
- `lib/scoria_web/live/incidents_live/index.ex` — stat strip `sm:grid-cols-3` → `md:grid-cols-3`; content split `xl:grid-cols-[...]` → `scoria-page-split--xl-reverse`
- `lib/scoria_web/live/review_queue_live.ex` — `lg:grid-cols-[minmax...]` → `scoria-page-split`
- `lib/scoria_web/live/workflow_live/show.ex` — `lg:grid-cols-[minmax...]` → `scoria-page-split`
- `lib/scoria_web/components/incident_evidence_component.ex` — `xl:grid-cols-[1.25fr,0.9fr]` → `scoria-evidence-split`
- `lib/scoria_web/components/semantic_evidence_notebook_component.ex` — `xl:grid-cols-[1.1fr,0.9fr]` → `scoria-evidence-split`
- `lib/scoria_web/components/replay_evidence_notebook_component.ex` — `xl:grid-cols-[1.25fr,0.9fr]` → `scoria-evidence-split`

## Decisions Made

- Collapsed all three evidence grid callsites (ratios 1.25fr/0.9fr, 1.1fr/0.9fr, 1.25fr/0.9fr) into one `.scoria-evidence-split` class — the minor ratio difference (1.1 vs 1.25) was not worth a second class; the shared primitive is the D-33 outcome.
- Used `.scoria-page-split` (lg breakpoint) for both workflow show and review queue even though the original `minmax(22rem, 0.95fr)` vs `minmax(20rem, 0.8fr)` differed slightly — one shared primitive with `minmax(20rem, 0.8fr)` covers both screens without per-screen one-offs.
- D-11 mobile source order was already correct in `workflow_live/show.ex` — no markup reorder required.
- Did not add any arbitrary-value utilities to `06-utilities.css`; all new rules went to `04-components.css` as named component classes.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — CSS and HEEx presentation changes only, no environment variables or external services.

## Threat Flags

No new attack surface. CSS class definitions and HEEx `class` attribute replacements only. No new routes, auth paths, data flows, or inputs introduced.

## Known Stubs

None. All replaced callsites reference real design-system classes with functioning CSS rules.

## Next Phase Readiness

- All 7 unsupported responsive utility callsites eliminated (D-12 closed, "Unsupported utilities must be replaced" contract clause satisfied)
- Named grid primitives available for any future screen needing the same split patterns (D-33 dividend established)
- `mix compile --warnings-as-errors` clean; DS-06 drift guard green
- Wave 5 Playwright plan can now assert multi-column layout at md/lg/xl and no overflow at 375px against these replaced classes

---
*Phase: 16-motion-responsive-theme-parity*
*Completed: 2026-06-13*
