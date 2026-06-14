---
phase: 22-integration-quality-gate
plan: 01
subsystem: brand-integration
tags: [brand, readme, favicon, layouts, assets, copy, hex, github]
completed: "2026-06-11"

dependency_graph:
  requires: []
  provides: [brand-integration-surfaces, favicon-inline-pipeline, tv1-mark-real]
  affects: [README.md, lib/scoria_web/components/layouts.ex, lib/scoria_web/assets.ex, lib/scoria_web/components/layouts/root.html.heex, priv/static/favicon.svg, mix.exs]

tech_stack:
  added: []
  patterns:
    - compile-time SVG favicon data-URI (mirrors css/0 js/0 model in ScoriaWeb.Assets)
    - evenodd SVG path with CSS-var fill for DS-06 compliance
    - GitHub dark/light-aware picture block in README

key_files:
  created:
    - priv/static/favicon.svg
    - .planning/phases/22-integration-quality-gate/22-01-SUMMARY.md
  modified:
    - README.md
    - lib/scoria_web/components/layouts.ex
    - lib/scoria_web/assets.ex
    - lib/scoria_web/components/layouts/root.html.heex
    - mix.exs

decisions:
  - Used the favicon's native viewBox (-53.32 -52.98 99.66 96.07) on the brand_mark SVG element rather than coordinate-translating to 0 0 24 24 — avoids floating-point rounding errors and keeps the path identical to favicon.svg
  - Favicon wired as compile-time base64 data-URI (favicon_data_uri/0) to stay consistent with the dashboard's fully self-contained inline model (no Plug.Static dependency)
  - picture block uses relative paths (brandbook/logo-primary.svg, brandbook/logo-primary-light.svg) — these resolve on GitHub; HexDocs gracefully degrades to the retained H1

metrics:
  duration: ~12min
  tasks_completed: 3
  files_changed: 6
---

# Phase 22 Plan 01: Brand Integration Summary

**One-liner:** Wired the real TV-1 Span-rail mark, inlined favicon data-URI, verbatim brand copy into README/Hex/GitHub, and all six surface tests green.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | README brand header + verbatim opener | 79a2c36 | README.md |
| 2 | Dashboard TV-1 mark swap + favicon wiring | 26244d9 | priv/static/favicon.svg, layouts.ex, assets.ex, root.html.heex |
| 3 | Hex/GitHub copy swap + full mix test gate | c13899b | mix.exs |

## What Was Built

### Task 1: README brand header
Replaced the plain `# Scoria` H1 with a centered `<picture>` block using `<source media="(prefers-color-scheme: dark)" srcset="brandbook/logo-primary.svg">` and `<img src="brandbook/logo-primary-light.svg">`. Retained the `# Scoria` H1 immediately below for graceful degradation on HexDocs. Added the primary tagline "AI ops for Phoenix apps." beneath. Kept all six existing badges verbatim in original order. Replaced the stale opening paragraph with the brand-book.md verbatim README opener.

### Task 2: Dashboard TV-1 mark + favicon
- `priv/static/favicon.svg`: byte-for-byte copy of `brandbook/favicon.svg` (3-hole, evenodd, pixel-snapped, 16px-legible)
- `brand_mark/1` in `layouts.ex`: replaced the placeholder (blob path with opacity/stroke + 3 `<circle>` elements) with a single `<path fill-rule="evenodd" fill="var(--scoria-ember-500)">` using the favicon's native geometry and viewBox. No stroke, no opacity layers, no hardcoded hex values — DS-06 compliant.
- `ScoriaWeb.Assets.favicon_data_uri/0`: compile-time `@external_resource` + `File.read!` + `Base.encode64` pattern, producing a `data:image/svg+xml;base64,...` string. Returns `""` gracefully if file absent at compile time.
- `root.html.heex`: `<link rel="icon" type="image/svg+xml" href={ScoriaWeb.Assets.favicon_data_uri()} />` added after `<.live_title>`, keeping the dashboard fully self-contained.

### Task 3: Hex/GitHub copy + test gate
- `mix.exs description/0`: updated to the verbatim 136-char Hex.pm copy block from brand-book.md §2.
- GitHub repo description: updated via `gh repo edit szTheory/scoria --description "..."` to the verbatim brand-book.md GitHub repo description block; verified via `gh repo view --json description`.
- `mix test`: **3 doctests, 632 tests, 0 failures** (15 excluded by tag). `test/support/ds06_baseline.txt` byte-identical (`git diff --quiet` passes).

## Deviations from Plan

### Auto-resolved

**1. [Rule 1 - Spec discrepancy] Plan verify check for `! grep -q "<circle"` is file-wide but circles exist in `icon/1` nav icons**
- **Found during:** Task 2 verification
- **Issue:** The plan's automated verify script `! grep -q "<circle" lib/scoria_web/components/layouts.ex` checks the entire file. The `icon/1` function contains `<circle>` elements for the `:tree` nav icon and the default fallback — these are pre-existing, intentional, and unrelated to `brand_mark/1`.
- **Fix:** Confirmed `brand_mark/1` itself has zero `<circle>` elements (checked via awk). The intent of the check is satisfied: the placeholder circles in `brand_mark/1` are removed. The remaining circles in `icon/1` are correct and must stay.
- **Files modified:** None — this was a spec interpretation, not a code change.

None — plan executed as written with the above clarification.

## Known Stubs

None. All surfaces are wired to real brand assets and real copy blocks.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. The favicon data-URI is a static brand SVG with no PII, consistent with the existing inlined CSS/JS model (T-22-02: accepted per threat register). The `gh repo edit` mutation was verified against the expected string (T-22-03: mitigated).

## Self-Check: PASSED

- [x] `priv/static/favicon.svg` exists: FOUND
- [x] `lib/scoria_web/assets.ex` has `def favicon_data_uri`: FOUND
- [x] `lib/scoria_web/components/layouts/root.html.heex` has `rel="icon"`: FOUND
- [x] `README.md` has `<picture>`: FOUND
- [x] `README.md` has `# Scoria`: FOUND
- [x] `mix.exs` has verbatim Hex description: FOUND
- [x] Commits 79a2c36, 26244d9, c13899b: FOUND
- [x] mix test: 632 tests, 0 failures
- [x] DS-06 baseline: byte-identical
- [x] GitHub description: verified verbatim match
