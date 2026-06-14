---
phase: 21-tokens-brandbook-html
plan: 02
subsystem: ui
tags: [brand, brand-book, svg, design-tokens, copywriting, voice, logo-system]

# Dependency graph
requires:
  - phase: 18-pressure-test
    provides: pressure-test.md audit (verdicts, §10 copy blocks, contrast table, Decisions Locked)
  - phase: 20-logo-convergence
    provides: 8 shipped logo SVGs + variant-spec.md (two-tone primary, clear-space, min-sizes)
provides:
  - "Post-audit canonical brand-book.md (543 lines, all KEEP/TIGHTEN/REWORK verdicts applied)"
  - "Final ready-to-paste copy blocks (Hex/GitHub desc, README opener, hero, CTAs, 3 feature blurbs, 3 why bullets, error/empty/success microcopy, release note) — consumed verbatim by Phase 22"
  - "7 specimen example SVGs (palette, typography, components, terminal, readme-header, landing-hero, docs-page) within budget"
affects: [22-integration, brandbook-index-html]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Hand-authored SVG specimens: <rect>/<text> with system-fallback font stacks, no embedded fonts, no network refs"
    - "Logo path data reused verbatim (mark + wordmark d-strings) where logos appear — never redrawn"
    - "brand-book.md is the canonical guide; copy blocks are final and version-frozen for Phase 22 consumption"

key-files:
  created:
    - brandbook/brand-book.md
    - brandbook/examples/palette.svg
    - brandbook/examples/typography.svg
    - brandbook/examples/components.svg
    - brandbook/examples/terminal.svg
    - brandbook/examples/readme-header.svg
    - brandbook/examples/landing-hero.svg
    - brandbook/examples/docs-page.svg
  modified: []

key-decisions:
  - "Single brand-book.md (not split into ui-guide.md) — UI guidance kept as a brand-expression section pointing to lib/scoria_web/ui.ex, keeping the doc at 543 lines within the 400–700 budget"
  - "Copy blocks transcribed verbatim from pressure-test.md §10 with zero edits — Phase 22 pastes them directly"
  - "readme-header.svg + docs-page.svg reuse the shipped logo-primary/logo-mark path data verbatim (confirmed byte-match) rather than redrawing"
  - "Dark-first art direction across all 7 specimens; Basalt-950 ground, Ember-500 signature accent, hex labels sourced from assets/css/02-tokens.css"

patterns-established:
  - "Specimen SVGs are illustrations not pixel-perfect product UI — schematics + system-fallback fonts, reproducible by any maintainer without design software"
  - "Every status badge/span carries a text label (Pass/Fail/Warning/Trace) — color is secondary confirmation"

requirements-completed: [BRAND-05]

# Metrics
duration: 18min
completed: 2026-06-11
---

# Phase 21 Plan 02: Brand book + examples Summary

**Post-audit 543-line canonical brand-book.md with final ready-to-paste copy blocks, plus 7 dark-first specimen SVGs (25.7KB total) reusing shipped logo path data verbatim.**

## Performance

- **Duration:** ~18 min
- **Started:** 2026-06-11
- **Completed:** 2026-06-11
- **Tasks:** 3
- **Files modified:** 8 (all created)

## Accomplishments

- Wrote `brandbook/brand-book.md` (543 lines) replacing the 1,618-line deep-research draft as the canonical guide — applies every KEEP/TIGHTEN/REWORK verdict from `pressure-test.md` and embeds all final copy blocks verbatim from §10.
- Authored 7 specimen SVGs covering the full census, each ≤12KB, totaling 25,681 bytes (well under the 60KB cap), with zero network asset references.
- `readme-header.svg` and `docs-page.svg` reuse the shipped `logo-primary.svg` / `logo-mark.svg` `d`-path data verbatim (mark + wordmark byte-match confirmed) — no redraw.
- `landing-hero.svg` demonstrates the locked tagline hierarchy: verb-triplet display headline, "AI ops for Phoenix apps." register line, and both CTAs, plus a genuine run-tree span schematic.

## Task Commits

1. **Task 1: Write brand-book.md (post-audit rewrite, final copy blocks)** — `df1f9bf` (docs)
2. **Task 2: palette/typography/components/terminal example SVGs (4 of 7)** — `5a9ef0d` (feat)
3. **Task 3: readme-header/landing-hero/docs-page example SVGs (3 of 7)** — `7231498` (feat)

**Plan metadata:** (this SUMMARY commit, below)

## Files Created/Modified

- `brandbook/brand-book.md` — Canonical brand guide: identity & positioning, ready-to-paste copy blocks, two-tone logo system, color (tone/span families + text-subtle PASS-LARGE constraint + propagation policy), typography, voice & microcopy, UI guidance, landing/docs blueprints, accessibility, do/don't.
- `brandbook/examples/palette.svg` — Swatch grid: dark neutrals, warm text scale, warm brand scale, functional accent pairs, hex labels from 02-tokens.css.
- `brandbook/examples/typography.svg` — Plex Sans weight ramp + JetBrains Mono code line across the fs scale.
- `brandbook/examples/components.svg` — Buttons, text-labelled tone badges, callout, eval-regression card.
- `brandbook/examples/terminal.svg` — Dark terminal: `mix scoria.install` + evidence-voice run-failure output.
- `brandbook/examples/readme-header.svg` — README hero band: primary lockup (verbatim logo path data) + tagline + badge row.
- `brandbook/examples/landing-hero.svg` — Hero: verb-triplet + subhead + CTAs + run-tree span schematic.
- `brandbook/examples/docs-page.svg` — HexDocs-ish light-mode mock: sidebar w/ mark, content column, brand-token code blocks.

## Decisions Made

- **Single brand-book.md, not split** — the audit (I3) suggested splitting §8–§12 UI guidance into a separate `ui-guide.md`. The plan scope is the brand book + examples only and the 400–700 line budget is comfortable at 543 lines, so UI guidance was kept as a concise brand-expression section that points to `lib/scoria_web/ui.ex` rather than spawning a new file. A future maintainer can split it if it grows.
- **Copy blocks verbatim** — §10 blocks transcribed with zero edits so Phase 22 can paste directly into mix.exs/GitHub/HexDocs.
- **Verbatim logo path reuse** — confirmed byte-match against `logo-primary.svg` (both mark and "Scoria" wordmark paths) and `logo-mark.svg` (in docs-page sidebar), honoring the "do not redraw" rule.

## Deviations from Plan

None - plan executed exactly as written. All three tasks' automated verify commands passed on first run.

## Issues Encountered

None. One verification regex (`Scoria.*never .*Scoria AI`) gave a false-negative during the overall scope check because `.*` does not span across the rendered phrasing on a single grep line; the naming rule is present and correct at `brand-book.md:62` (`Never "Scoria AI"`). The per-task verify command (`grep -qi 'never .*Scoria AI\|Scoria AI'`) passed correctly.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- BRAND-05 brand-book + examples slice complete. The 7 specimens are ready for the `index.html` (21-03) to embed.
- Copy blocks are frozen and ready for Phase 22 integration (README, mix.exs description, GitHub repo description, HexDocs, social card).
- No Phase-22-scope files (README.md, layouts.ex, mix.exs, assets/css/02-tokens.css) were touched.

## Self-Check: PASSED

- brandbook/brand-book.md — FOUND (543 lines)
- brandbook/examples/{palette,typography,components,terminal,readme-header,landing-hero,docs-page}.svg — all 7 FOUND (≤12KB each, 25.7KB total)
- Commits df1f9bf, 5a9ef0d, 7231498 — verified present in git log

---
*Phase: 21-tokens-brandbook-html*
*Completed: 2026-06-11*
