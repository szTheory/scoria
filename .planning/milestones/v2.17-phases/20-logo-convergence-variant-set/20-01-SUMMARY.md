---
phase: 20-logo-convergence-variant-set
plan: "01"
subsystem: brand
tags: [svg, logo, convergence, variant-set, optical-pass, verifier, pruning]

# Dependency graph
requires:
  - phase: 19-logo-divergence-user-choice
    plan: "03"
    provides: "Gate #2 locked direction (TV-1 mark + LK-B fused lockup) + verify-logos.mjs LOGO-01..07 verifier"
provides:
  - "8 canonical root logo SVGs at brandbook/ root (logo-primary, -light, -mark, -monochrome, -lockup-subtitle, logotype-integrated, favicon, social-card)"
  - "brandbook/tools/lib/root-variants.mjs — 8 recolor/derive composers over the frozen gate-#2 artwork"
  - "brandbook/tools/converge.mjs — async writer emitting the 8 root SVGs"
  - "brandbook/tools/variant-spec.md — documented optical pass + clear-space/min-size spec"
  - "verify-logos.mjs extended with 10 ROOT-* checks; BUDGET back to <500 KB"
  - "pruned candidates/ (TV-1 lineage + LK-B only) + both galleries deleted"
affects:
  - 21 (brand book — consumes the root SVGs + variant-spec.md)
  - 22 (README/dashboard/Hex integration — consumes the canonical logo system)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Recolor-layer composers: read frozen candidate SVG path d strings verbatim off disk, recolor/substitute currentColor/retighten viewBox — never regenerate geometry"
    - "Async SVG writer loop (await fn()) so opentype.js tagline-outlining builders resolve before writeFileSync"
    - "Pixel-grid favicon snap: Math.round(n/2)*2 on holes16 centers+radii (even 16-grid), silhouette copied verbatim"
    - "Verifier check-skip guards (existsSync) so gallery-completeness checks degrade to a documented PASS after pruning"

key-files:
  created:
    - brandbook/tools/lib/root-variants.mjs
    - brandbook/tools/converge.mjs
    - brandbook/tools/variant-spec.md
    - brandbook/logo-primary.svg
    - brandbook/logo-primary-light.svg
    - brandbook/logo-mark.svg
    - brandbook/logo-monochrome.svg
    - brandbook/logo-lockup-subtitle.svg
    - brandbook/logotype-integrated.svg
    - brandbook/favicon.svg
    - brandbook/social-card.svg
  modified:
    - brandbook/tools/verify-logos.mjs
    - brandbook/tools/package.json

key-decisions:
  - "Primary ships TWO-TONE (white-hot/basalt letters + ember/scoria 'o') — ink density 0.61 vs letters 0.57 (~7%) confirms color carries the accent, not weight; PRIMARY_TWO_TONE flag flips it."
  - "logotype-integrated.svg is byte-identical to logo-monochrome.svg — LK-B IS the integrated typemark, so one source of truth for the single-color fused form."
  - "Composers read frozen path d strings verbatim from candidates/ rather than re-running geometry libs — guarantees zero coordinate drift from gate-#2 artwork (T-20-01 mitigation)."
  - "Favicon snapped to even 16-grid; holes render 2.00/1.67/1.67px at 16px (all >=1.5px); 734 bytes via stripped title/desc."

# Metrics
duration: ~22min
completed: 2026-06-11
---

# Phase 20 Plan 01: Logo Convergence — Full Variant Set Summary

**The gate-#2 winner (TV-1 "Span rail" mark + LK-B "Mark-as-o" fused lockup) graduated to the canonical 8-variant set at `brandbook/` root via recolor-only composers over frozen artwork, with a documented optical-correction pass, a 10-check ROOT-* verifier gate (exit 0), and galleries + losing candidates pruned to land brandbook/ at 400 KB (well under the 500 KB target).**

## Performance

- **Duration:** ~22 min
- **Tasks:** 3 auto (no checkpoints in this plan; confirm checkpoint is 20-02)
- **Files created:** 11 (3 tooling/spec + 8 root SVGs)
- **Files modified:** 2 (verify-logos.mjs, package.json)
- **Files deleted:** 26 (24 losing candidates + 2 gallery HTML)

## Accomplishments

### Task 1 — Root-variant composers + converge.mjs (commit `ad487d7`)

`lib/root-variants.mjs` exports 8 composers that read the frozen LK-B lockup,
TV-1 mark, and TV-1 favicon path `d` strings **verbatim** off disk and only
recolor / substitute `currentColor` / retighten viewBox / snap the favicon / add
outlined tagline text. `converge.mjs` is an **async** writer (`await fn()`) so the
subtitle + social-card builders — which outline the tagline via `wordmarkPath()` —
resolve to strings, not `[object Promise]`. All 8 census-named SVGs written to
`brandbook/` root; favicon is **734 bytes** (≤1KB). `"converge"` script added to
package.json. Verified: letterform path byte-identical to the frozen LK-B source.

### Task 2 — Optical-correction pass + variant-spec.md (commit `dc40793`)

`variant-spec.md` documents the numeric craft review:
- **Two-tone primary** call with ink-density proxy (mark 0.61 vs letters 0.57, ~7% — color carries the accent, root-hole micro-tune from 19-02b preserved).
- **Overshoot/baseline**: mark occupies x 111.22–167.87, y −53.38–1.18 (x-height band), width 56.64u vs o-advance 56.30u — no clip/float, no neighbour collision (re-measured this pass, matches 19-03).
- **logotype-integrated lineage**: byte-identical to logo-monochrome, rationale stated.
- **Favicon legibility**: 3 holes snapped to even 16-grid, radii 2.00/1.67/1.67px at 16px (all ≥1.5px).
- **Clear space** = cap-height/2 (≈38.4u), with the §8 unit-*v* alternate noted.
- **Min sizes**: lockup ≥120px, mark ≥20px, favicon exact 16/32px (§8 ≥112 alternate noted).
- **LOGO-01..07 binding** confirmation for the root set.

The review found the frozen artwork already satisfies every optical criterion, so
no further SVG adjustment was needed (the two-tone fills and favicon snap were
already applied in Task 1, matching this documented decision).

### Task 3 — ROOT-* verifier gate + pruning (commit `425a9e1`)

`verify-logos.mjs` extended with 10 ROOT-* checks over the 8 root SVGs:
ROOT-EXISTS, ROOT-NORECT (social-card's single card-ground rect exempted with an
inline 20-CONTEXT citation), ROOT-EVENODD, ROOT-STROKE, ROOT-VIEWBOX (social-card
tight-origin exempt), ROOT-DECIMALS, ROOT-CURRENTCOLOR, ROOT-FAVICON (≤1024 bytes
+ exactly 3 holes), ROOT-SUBTITLE (only the subtitle variant carries the tagline;
social-card exempt). Gallery-completeness checks now skip gracefully via an
`existsSync` guard; LOGO-05 retires with a "typemarks pruned — fused lockup is the
integrated typemark" pass. BUDGET threshold returned to **<500 KB**. Then pruned
both gallery HTML files + all losing candidates via `git rm`; `candidates/` retains
only `TV-1-mark/mono/fav/lockup` + `LK-B-lockup`.

## Verification Evidence

`node brandbook/tools/verify-logos.mjs` → **exit 0**, all checks PASS:

```
PASS  [ROOT-EXISTS]  All 8 root variant SVGs present
PASS  [ROOT-NORECT]  No <rect> in the 7 logo SVGs; social-card.svg has exactly its 1 documented card-ground rect
PASS  [ROOT-EVENODD]  All 8 root SVGs carry fill-rule="evenodd"
PASS  [ROOT-STROKE]   No active stroke attributes in 8 root SVGs
PASS  [ROOT-VIEWBOX]  logo viewBoxes tight near origin (social-card exempt)
PASS  [ROOT-DECIMALS] All coordinates ≤2 decimal places across 8 root SVGs
PASS  [ROOT-CURRENTCOLOR]  logo-monochrome + logotype-integrated use currentColor
PASS  [ROOT-FAVICON]  favicon.svg ≤1024 bytes with exactly 3 hole subpaths
PASS  [ROOT-SUBTITLE] only the subtitle variant carries the tagline
PASS  [LOGO-05]       typemarks pruned in Phase 20 — skipped
PASS  [GALLERY-*]     gallery HTML pruned in Phase 20 — skipped
PASS  [BUDGET]        brandbook/ text+SVG artifacts: 339 KB (<500 KB)
```

- `ls brandbook/*.svg` → exactly the 8 census filenames.
- `favicon.svg` = 734 bytes (`wc -c`); `du -k` reports the 4 KB APFS block (see Deviation 1).
- `ls brandbook/tools/candidates/` → `LK-B-lockup, TV-1-fav, TV-1-lockup, TV-1-mark, TV-1-mono` (5 files).
- Both `options-gallery*.html` absent.
- `du -sk brandbook` minus node_modules = **400 KB** (well under 500 KB).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking verify-command artifact] Favicon size assert uses `du -k`, which rounds to the filesystem block size**

- **Found during:** Task 1 verification.
- **Issue:** The plan's Task 1 automated check `test "$(du -k brandbook/favicon.svg | cut -f1)" -le 1` fails on macOS APFS because `du -k` reports the allocated block (4 KB) for any small file, regardless of byte count. The favicon is **734 bytes** — comfortably under 1 KB.
- **Fix:** Confirmed the real byte size with `wc -c` (734 bytes ≤ 1024). The authoritative gate is the **ROOT-FAVICON** check in verify-logos.mjs, which asserts the true on-disk byte size (`statSync().size ≤ 1024`) — that check passes. No artifact change was needed; only the throwaway verify command's `du -k` rounding was misleading.
- **Files modified:** none (verification-command artifact only).
- **Commit:** n/a (no code change).

**Total deviations:** 1 (a verify-command measurement artifact, no code impact). No Rule 1/2/4 deviations — geometry stayed frozen and no architectural changes arose.

## Known Stubs

None. Every root SVG renders real frozen artwork; the tagline/social text is real
outlined opentype paths; the verifier checks real structure; variant-spec.md
records real measured numbers.

## Threat Flags

None. The 8 root SVGs are fills-only paths (plus social-card's documented
card-ground rect) — no `<script>`, no `xlink:href`/http external refs (T-20-03
mitigated). Geometry is copied verbatim from the locked candidates, asserted by the
ROOT-* checks (T-20-01 mitigated). No package installs (T-20-SC N/A).

## Next Phase Readiness

- BRAND-04 structural half satisfied: the canonical 8-variant logo system is at `brandbook/` root and gated by verify-logos.mjs (exit 0).
- The confirm checkpoint (lightweight "ship it / adjust" visual strip) is **plan 20-02** per the phase boundary — not in this plan.
- Phase 21 (brand-book.md, tokens, examples) consumes these root SVGs + `variant-spec.md`'s clear-space/min-size rules.

## Self-Check: PASSED

- All 11 created files + the SUMMARY exist on disk (verified via `[ -f ]`).
- All 3 task commits present in git log: `ad487d7`, `dc40793`, `425a9e1`.
- `node brandbook/tools/verify-logos.mjs` exits 0 with all ROOT-* checks passing.
- `candidates/` contains exactly the 5 keepers; both galleries absent.
