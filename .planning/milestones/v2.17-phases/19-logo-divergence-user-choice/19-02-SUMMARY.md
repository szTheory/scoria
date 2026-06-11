---
phase: 19-logo-divergence-user-choice
plan: "02"
subsystem: brand
tags: [svg, logo, presets, gallery, geometry, typemark, favicon, design-intent]

# Dependency graph
requires:
  - phase: 19-logo-divergence-user-choice
    plan: "01"
    provides: markPath/svgDocument/wordmarkPath/integratedTypemark/composeLockup toolchain APIs
provides:
  - presets.mjs — 6 hand-authored mark presets (TV-1/2/3, CM-1/2, AP-1) + 2 typemark presets (TYPE-1/2), each with an @design-intent block and (Trace Vesicle) a holes16 16px favicon simplification
  - generate.mjs — orchestrator rendering 23 candidate SVGs (mark/mono/fav/lockup per mark + full typemarks) into candidates/
  - gallery.mjs — standalone options-gallery.html builder (inline SVG, dual ground, full evidence rows, ranked recommendation)
  - candidates/ — 23 committed candidate SVGs (6 marks, 6 lockups, 6 mono, 3 favicons, 2 typemarks)
  - options-gallery.html — gate-#2 evidence page
affects:
  - 19-03 (gallery verifier + human gate #2 — judges these candidates and the recommendation)
  - 20 (logo convergence — the chosen direction graduates to brandbook/ root; losers pruned)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Curated presets as discrete named exports (no random-seed loop) — each carries a JSDoc @design-intent block stating the option's distinction"
    - "holes16 key on Trace Vesicle presets = the LOGO-06 16px favicon simplification (exactly 3 holes), distinct from the full holes layout"
    - "Favicon hole sizing verified by geometry math: hole radius x render-scale >= 1.5px AND inter-hole edge-gap >= 0.5x smaller radius (webs survive)"
    - "Gallery inlines SVG by injecting width/height + color: on the <svg> root; monochrome SVGs (currentColor) inherit the ground's flipped text color"
    - "SVG xmlns namespace URI is the only http reference and is not a network fetch — the file:// page is fully self-contained"

key-files:
  created:
    - brandbook/tools/presets.mjs
    - brandbook/tools/generate.mjs
    - brandbook/tools/gallery.mjs
    - brandbook/tools/options-gallery.html
    - brandbook/tools/candidates/ (23 SVGs)
  modified: []

key-decisions:
  - "Sixth slot = TV-3 (third Trace Vesicle) NOT CC-1 (Cutaway Cone). The §8 ranking de-prioritizes Cutaway Cone to #4 because a cone cross-section loses its silhouette at 16px — it fails favicon survival by construction. The brief permits swapping CC-1 for a third Trace Vesicle; TV-3 deepens the #1 direction (horizontal cross-rail reading) while CM-1/2 + AP-1 keep >=2 directions beyond Trace Vesicle for honest divergence."
  - "Favicon legibility is a geometry constraint, not a preference: holes16 retuned so each of the 3 holes clears >=1.5px at a 16px render and the webs between them survive — caught and fixed via generate-time math, not by eyeballing pixels."
  - "TYPE-2 extra punches added in generate.mjs (the 'a' bowl at x~262,y~-15 in the wordmark coord space) by appending vesicleHoles to the integratedTypemark compound path — the 19-01 integratedTypemark() only does the 'o' ring, so the second-letterform porosity is layered on at render time."
  - "Gallery uses an IBM Plex Sans system-fallback stack (no @font-face, no webfont load) so the file:// page renders instantly offline — honoring the self-contained / no-network requirement."

patterns-established:
  - "Each logo option is a hand-tuned parameter object + a prose @design-intent block — the design intent travels with the geometry"
  - "Verify visually-relevant invariants numerically (aspect ratio in [0.85,1.15], hole survival px, hole spacing) since pixels can't be inspected directly"

requirements-completed: [BRAND-03]

# Metrics
duration: 14min
completed: 2026-06-11
---

# Phase 19 Plan 02: Curated Logo Options + Gate-#2 Gallery Summary

**Six hand-tuned, design-intent-documented logo marks across three directions (Trace Vesicle x3, Cinder x2, Aperture study x1) plus two integrated typemark studies, rendered to 23 structurally-compliant candidate SVGs and assembled into a standalone, dual-ground, full-evidence options-gallery.html for the gate-#2 human choice.**

## Performance

- **Duration:** ~14 min
- **Tasks:** 3
- **Files created:** 4 source/output files + 23 candidate SVGs (27 files)
- **Lines added:** ~2,215

## Accomplishments

- **6 hand-authored mark presets** (no random-seed loop), each preceded by a `@design-intent` block stating its distinction:
  - **TV-1 "Span rail"** — quiet, disciplined Trace Vesicle; tight vertical span tree, closed silhouette, favicon-safest.
  - **TV-2 "Open branch"** — dynamic, asymmetric; trace tree forks and one vesicle bleeds the right edge as a notch (the "breaking boundaries" taste).
  - **TV-3 "Cross rail"** — horizontal reading of the trace tree; chiselled arrow-ish chunk (the discretionary 6th slot, chosen over Cutaway Cone).
  - **CM-1 "Field sample"** — classic cinder chunk, 5 scattered holes, dominant core, flat base facet.
  - **CM-2 "Tumbled"** — softer/rounder sibling, 7 even holes, higher porosity, flat upper-left facet.
  - **AP-1 "Aperture study"** — central cavity + 4 radial satellites; flagged STUDY ONLY (surfaces the camera/eye risk).
- **2 integrated typemark studies** (LOGO-05): **TYPE-1 "Ring o"** ('o' → vesicle ring, weight ≈ 'S' stem, advance/x-height preserved) and **TYPE-2 "Porous a"** (same ring 'o' + 2 tiny vesicles punched in the 'a' bowl).
- **23 candidate SVGs** generated into `candidates/`: 6 marks, 6 lockups (no subtitle, data-gap-ratio=0.4), 6 monochrome, 3 Trace-Vesicle favicons, 2 typemarks — all single-path evenodd, brand-hex/currentColor fill, no rect, no stroke.
- **Favicon craft pass:** all three Trace Vesicle `holes16` simplifications verified by geometry math — each of the 3 holes survives ≥1.5px at a 16px render and the inter-hole webs survive (caught a real defect where the smallest hole dropped to ~1.2px; fixed by re-spreading + resizing).
- **options-gallery.html** — 1,264-line standalone file:// page: dual ground (Basalt-950 / Ash-50), per-option 256/64/32/16px ramp + lockup, monochrome row, browser-tab favicon strip, 24px sidebar mock, README header band, ranked recommendation block with my pick + rationale, and the "none of these → second round" escape note. Zero external network references.

## My ranked recommendation (feeds gate #2)

**#1 — TV-1 "Span rail."** It is the only option that passes every hard test cleanly:

- **16px favicon:** its 3-hole simplification keeps three well-separated holes, each ≥1.5px rendered (geometry-verified) with surviving webs — it stays legible where the full 4-hole mark's smallest holes vanish.
- **Monochrome:** the trace-node hierarchy (root → child → leaf) reads as deliberate internal logic, not random porosity, so it survives currentColor.
- **Silhouette:** ~1.04:1 aspect — never starves the sidebar/favicon slots.
- **Distinctiveness:** the traceable internal structure is genuinely different from devtools competitors (abstract nodes / colorful blobs) and orthogonal to Threadline's line motif.

**Close runner-up: TV-2 "Open branch"** if the user wants more energy — its edge-notch breaks the closed-blob feel and matches the stated "we like somewhat breaking the boundaries" taste, at a small cost to favicon tidiness. **Cinder (CM-1/CM-2)** is the honest #2 fallback (simpler, better small-size survival, but no internal logic). **AP-1** is included as a rejectable study. Full rationale is rendered in the gallery's recommendation block.

## Task Commits

1. **Task 1: Hand-tuned presets with design-intent comments** — `1dbd26c` (feat)
2. **Task 2: Generate candidate SVGs** — `bc70930` (feat)
3. **Task 3: Build options-gallery.html** — `9baa89a` (feat)

**Plan metadata:** _(final commit — see below)_

## Verification Evidence

- `node generate.mjs` exits 0, writes 23 SVGs; `node gallery.mjs` exits 0, writes the HTML.
- `presets.mjs`: 6 marks + 2 types; 9 `@design-intent` tags (≥8); 5 core stable IDs; `holes16` keys present; **zero** preset-generating for-loops.
- Candidates: **0** `<rect>`, every `*-mark.svg` has exactly **1** `<path>` with `fill-rule="evenodd"`, **0** strokes, **0** subtitle leaks in lockups.
- Gallery: 1,264 lines; **0** external `http(s)` resource refs; **0** `<img>`; 8 stable IDs; sizes 256/64/32/16 all present; both grounds (`#11100F`, `#FAF5EF`) present.
- Scope: **0** files under `brandbook/` root; **0** `favicon.svg` / `social-card.svg` (Phase 20/22 scope kept clean).
- 19-01 `smoke.mjs` still exits 0 (toolchain not regressed).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Trace Vesicle 16px favicon holes were illegible at render size**
- **Found during:** Task 2 (favicon geometry verification)
- **Issue:** The initial `holes16` simplifications (kept from the full 3 largest nodes) rendered their smallest hole at ~1.2–1.3px at 16px — below the ~1.5px legibility floor; a first enlargement pass then over-shot, merging adjacent holes into one blob (edge-gap negative / under 0.5× the smaller radius).
- **Fix:** Re-tuned all three `holes16` sets: spread the 3 holes to the silhouette's diagonal/horizontal extremes (TV-3 kept a shallow horizontal diagonal to preserve its cross-rail identity) and sized each radius to its per-silhouette threshold (computed as 1.5 / render-scale). Final result: all three favicons pass survival (each ≥1.5px), edge clearance (inside the silhouette), and spacing (web ≥ 0.5× smaller radius).
- **Files modified:** brandbook/tools/presets.mjs
- **Verification:** geometry-math harness reports `survive / edge-ok / spacing-ok ✓` for TV-1/TV-2/TV-3.
- **Committed in:** `bc70930` (Task 2 commit)

**Total deviations:** 1 auto-fixed (1 Rule 1 bug). This was the core craft iteration the plan called for — refining preset params at least once before settling, using geometry as the "eyes."

## Known Stubs

None. All presets are fully hand-authored; all 23 candidates render real geometry; the gallery inlines every candidate with full evidence rows. The AP-1 aperture is intentionally a study (documented as such, not a stub). TYPE-2's 'a'-bowl punches are real appended vesicles, not placeholders.

## Threat Flags

None. The gallery introduces no network surface — the only `http` string is the SVG XML namespace URI (`http://www.w3.org/2000/svg`), which browsers never fetch; there are zero `<link>`, `<script src>`, `@import`, `<img>`, or external resource references (T-19-03 mitigated by construction). Candidate SVGs carry no hidden `<rect>`/white shapes and are single-path evenodd (T-19-04 mitigated).

## Next Phase Readiness

- `options-gallery.html` is the gate-#2 artifact: 19-03 verifies the evidence rows + structural compliance, then the orchestrator presents the choice (incl. the "second round" escape) via AskUserQuestion.
- The recommendation is explicit (TV-1 #1, TV-2 runner-up, Cinder fallback, Aperture study) so the user has a defensible default.
- The generator is reproducible scaffolding: `node generate.mjs && node gallery.mjs` rebuilds everything; Phase 20 graduates the chosen direction to `brandbook/` root and prunes the losers.

## Self-Check: PASSED

All created files verified present (presets.mjs, generate.mjs, gallery.mjs, options-gallery.html, 19-02-SUMMARY.md, 23 candidate SVGs) and all three task commits (`1dbd26c`, `bc70930`, `9baa89a`) verified in git log.

---
*Phase: 19-logo-divergence-user-choice*
*Completed: 2026-06-11*
