---
phase: 19-logo-divergence-user-choice
plan: "01"
subsystem: brand
tags: [svg, opentype, wawoff2, logo, geometry, wordmark, lockup, nodejs, esm]

# Dependency graph
requires:
  - phase: 18-pressure-test-audit-decision-lock
    provides: LOGO-01..07 hard constraints, IBM Plex Sans SemiBold font confirmed, gate #1 locked
provides:
  - facetedPolygon() — low-frequency seeded radius perturbation, quadratic corner rounding
  - vesicleHoles() — circle approximation via 4-cubic-bezier arcs (kappa=0.5523)
  - markPath() — single compound evenodd path (outer polygon + punched holes)
  - pathBBox() — coordinate-scan bbox for tight viewBox computation
  - svgDocument() — single-path SVG with role=img, title, fill-rule=evenodd, tight viewBox
  - loadFont() — wawoff2 decompress + opentype.js parse of repo woff2, cached
  - wordmarkPath() — outlined Scoria path + capHeight + width measurements
  - integratedTypemark() — wordmark with 'o' replaced by vesicle-ring form
  - composeLockup() — mark + wordmark SVG with LOGO-03 gap, data-gap-ratio attribute
  - smoke.mjs — structural validity gate for the toolchain (exits 0 on PASS)
affects:
  - 19-02 (divergence craft — uses all module APIs for preset generation)
  - 19-03 (gallery verifier — asserts data-gap-ratio in [0.35, 0.5])

# Tech tracking
tech-stack:
  added:
    - opentype.js ^1.3.5 (1.x line — parse(ArrayBuffer) + Font.getPath API)
    - wawoff2 ^2.0.1 (Google woff2 WASM port — CJS default import in ESM)
  patterns:
    - wawoff2 CJS-safe import: `import wawoff2 from 'wawoff2'` then `wawoff2.decompress(buf)`
    - All SVG coordinates rounded to <=2 decimals for clean diffs
    - Low-frequency radius perturbation: 1.5 sine cycles across all anchors (not per-anchor jitter)
    - LOGO-03 contract: data-gap-ratio attribute on lockup SVG root, clamped [0.35, 0.5]
    - evenodd compound path: outer polygon + reversed hole sub-paths in single d string

key-files:
  created:
    - brandbook/tools/package.json
    - brandbook/tools/.gitignore
    - brandbook/tools/lib/geometry.mjs
    - brandbook/tools/lib/svg.mjs
    - brandbook/tools/lib/wordmark.mjs
    - brandbook/tools/lib/lockup.mjs
    - brandbook/tools/smoke.mjs
  modified: []

key-decisions:
  - "opentype.js pinned to ^1.3.5 (1.x line) — npm latest is 2.0.0 which is a major bump; 1.x has the parse(ArrayBuffer) + Font.getPath API this plan uses"
  - "wawoff2 CJS-only — must use default import, not named export; named export does not exist in ESM wrapper"
  - "Low-frequency radius perturbation via 1.5 sine cycles across all anchors — ensures smooth shape variance (anti-amoeba) rather than per-anchor jitter"
  - "data-gap-ratio attribute on lockup SVG root is the machine-checkable LOGO-03 contract — 19-03 verifier asserts it numerically"
  - "vesicleHoles uses 4-cubic-bezier circle approximation (kappa=0.5523) for clean compound path composition"
  - "Smoke test writes throwaway artifacts to os.tmpdir() — never under brandbook/candidates/ (which is 19-02 territory)"

patterns-established:
  - "SVG module pattern: single <path fill-rule='evenodd'>, role=img, <title>, no <rect>, no stroke"
  - "Geometry first: markPath() always returns a single compound d string — callers never concatenate paths"
  - "lockup.mjs scales the mark to capHeight for proportional lockup sizing"

requirements-completed: [BRAND-03]

# Metrics
duration: 6min
completed: 2026-06-11
---

# Phase 19 Plan 01: Logo Generation Toolchain Summary

**Faceted-polygon + evenodd-hole geometry library, IBM Plex Sans SemiBold wordmark outliner (wawoff2+opentype.js), LOGO-03-enforcing lockup composer, and passing smoke test — full Node >=18 ESM toolchain in brandbook/tools/**

## Performance

- **Duration:** 6 min
- **Started:** 2026-06-11T16:20:55Z
- **Completed:** 2026-06-11T16:26:56Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments

- Full ESM toolchain in `brandbook/tools/` with `package.json` (opentype.js ^1.3.5, wawoff2 ^2.0.1), node_modules gitignored, no font binaries committed
- Geometry library emits a single evenodd compound path string — outer faceted polygon (6–8 anchors, low-frequency radius perturbation, quadratic corner rounding) + punched vesicle holes — all coords <=2 decimals, no rect, no stroke
- Wordmark module decompresses the repo woff2 at runtime via wawoff2, parses with opentype.js, outlines "Scoria" as an SVG path with measured capHeight and total width; integrated 'o'-replacement hook swaps the 'o' glyph for a vesicle-ring form preserving advance width and x-height alignment
- Lockup composer enforces LOGO-03 gap (0.35–0.5× capHeight), emits `data-gap-ratio` attribute on SVG root for machine-checkable compliance, tight viewBox over both elements
- `node brandbook/tools/smoke.mjs` exits 0 and prints PASS, asserting LOGO-01/02/03 structurally

## Task Commits

Each task was committed atomically:

1. **Task 1: Tooling scaffold (package.json + .gitignore)** - `3ba19a5` (chore)
2. **Task 2: Geometry + SVG document libraries** - `36b0f4c` (feat)
3. **Task 3: Wordmark + lockup modules + smoke test** - `f2cd057` (feat)

**Plan metadata:** _(final commit — see below)_

## Public API Signatures (for 19-02's consumption)

### `lib/geometry.mjs`

```js
// Closed rounded faceted polygon path d string
facetedPolygon({ anchors, baseRadius, radiusVariance, flatFacets, rounding, seed, cx, cy }) → string

// Vesicle-hole sub-paths (concatenated circles as 4-bezier arcs)
vesicleHoles([{ cx, cy, r }]) → string

// Single compound path: outer polygon + holes (fill-rule=evenodd)
markPath({ anchors, baseRadius, radiusVariance, flatFacets, rounding, seed, holes, cx, cy, edgeNotch }) → string

// Bounding box from path coordinate scan
pathBBox(d) → { minX, minY, maxX, maxY }
```

### `lib/svg.mjs`

```js
// Single-path SVG document: role=img, <title>, fill-rule=evenodd, tight viewBox
svgDocument({ pathD, fillRule, fill, viewBox, title, id, pad }) → string

// Tight viewBox string from single path d
tightViewBox(d, pad?) → string  // "minX minY width height"

// Tight viewBox string from two combined path d strings
combinedViewBox(d1, d2, pad?) → string
```

### `lib/wordmark.mjs`

```js
// Load + cache the IBM Plex Sans SemiBold font (wawoff2 decompress + opentype.js parse)
loadFont() → Promise<Font>

// Outlined path for text string + measurements
wordmarkPath(text, { fontSize, tracking, x, y }) → Promise<{ d, capHeight, width, bbox }>
// bbox: { x1, y1, x2, y2 }

// Wordmark with 'o' replaced by vesicle-ring form (LOGO-05 integrated typemark)
integratedTypemark(text, { fontSize, tracking, x, y, oReplacement }) → Promise<{ d, capHeight, width, bbox }>
```

### `lib/lockup.mjs`

```js
// Mark + wordmark SVG with LOGO-03 spacing and data-gap-ratio attribute
composeLockup({
  markD,         // string — mark compound path d
  markBox,       // { minX, minY, maxX, maxY } — from pathBBox(markD)
  wordmarkD,     // string — wordmark path d
  wordmarkBbox,  // { x1, y1, x2, y2 } — from wordmarkPath()
  capHeight,     // number — from wordmarkPath()
  fill,          // string (default 'currentColor')
  markFill,      // string (optional override for mark)
  title,         // string (default 'Scoria')
  gapRatio,      // number (default 0.4, clamped to [0.35, 0.5])
}) → string  // SVG with data-gap-ratio="<value>" on root
```

**LOGO-03 contract:** The lockup SVG root always carries `data-gap-ratio="<gap/capHeight, 2 decimals>"`. Value is clamped to [0.35, 0.5]. The smoke test and 19-03 verifier assert this attribute numerically.

## Files Created/Modified

- `brandbook/tools/package.json` — type:module, Node>=18, opentype.js ^1.3.5, wawoff2 ^2.0.1, smoke + generate scripts
- `brandbook/tools/.gitignore` — node_modules/, *.ttf transient buffers
- `brandbook/tools/lib/geometry.mjs` — facetedPolygon, vesicleHoles, markPath, pathBBox (211 lines)
- `brandbook/tools/lib/svg.mjs` — svgDocument, tightViewBox, combinedViewBox (89 lines)
- `brandbook/tools/lib/wordmark.mjs` — loadFont, wordmarkPath, integratedTypemark (233 lines)
- `brandbook/tools/lib/lockup.mjs` — composeLockup (140 lines)
- `brandbook/tools/smoke.mjs` — structural validation smoke test, exits 0 on PASS (175 lines)

## Decisions Made

- **opentype.js pinned to ^1.3.5** — 1.x line has `parse(ArrayBuffer) + Font.getPath` API; 2.0.0 is a breaking major bump. npm deprecated 1.3.5 in May 2026 (it was accidentally published as 1.3.5 instead of 2.0.0); functionally the API is present and correct for our toolchain use.
- **wawoff2 CJS default import** — `import wawoff2 from 'wawoff2'` is the only form that works in Node ESM; named export `{ decompress }` does not exist in the ESM wrapper.
- **Low-frequency perturbation** — 1.5 sine cycles across all anchors gives smooth, slightly irregular polygon shapes instead of per-anchor random jitter (which produces amoeba silhouettes).
- **data-gap-ratio on lockup root** — machine-checkable LOGO-03 contract; value clamped to [0.35, 0.5] in composeLockup, asserted in smoke.mjs and handed to 19-03 verifier.
- **Smoke artifacts to os.tmpdir()** — throwaway SVGs never written under brandbook/ (candidates/ is strictly 19-02 territory).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed viewBox tightness assertion in smoke.mjs**
- **Found during:** Task 3 (smoke.mjs execution)
- **Issue:** The initial smoke test asserted `|viewBox.x| < 15`, but the mark is centered at origin with baseRadius=50, so the viewBox x origin is ~-51 — correctly tight but failed the over-strict check
- **Fix:** Replaced the hardcoded 15 threshold with a bounds check relative to `SMOKE_PRESET.baseRadius` (origin within ±1.3× baseRadius, width/height < 3.5× baseRadius)
- **Files modified:** brandbook/tools/smoke.mjs
- **Verification:** Smoke test exits 0
- **Committed in:** f2cd057 (Task 3 commit)

**2. [Rule 1 - Bug] Fixed false positive in named-import grep check**
- **Found during:** Task 3 acceptance criteria verification
- **Issue:** A JSDoc comment containing `import { decompress } from 'wawoff2'` (showing the bad form to avoid) caused `grep -c "import {.*} from 'wawoff2'"` to return 1 instead of 0
- **Fix:** Rewrote the comment to describe the constraint without quoting the forbidden import form
- **Files modified:** brandbook/tools/lib/wordmark.mjs
- **Verification:** grep returns 0
- **Committed in:** f2cd057 (Task 3 commit)

---

**Total deviations:** 2 auto-fixed (2 Rule 1 bugs)
**Impact on plan:** Both fixes necessary for correctness. No scope creep.

## Issues Encountered

None — opentype.js 1.3.5 API was present and functional despite the deprecation warning (accidental version publish). wawoff2 default import worked as documented.

## Known Stubs

None — the toolchain modules implement their full stated contracts. The integrated 'o'-replacement uses a simplified vesicle ring (two circles via vesicleHoles) rather than a fully hand-tuned glyph form — that craft work is 19-02's responsibility.

## Threat Flags

None — no new network endpoints, auth paths, or trust boundaries introduced. The npm packages (opentype.js, wawoff2) were legitimacy-verified per the threat register (T-19-01): opentype.js >1M weekly downloads, est. 2015; wawoff2 official Google woff2 WASM port. node_modules is gitignored; no vendored code enters the repo.

## Next Phase Readiness

- All four library modules are ready for 19-02 to import directly by name
- Public API signatures documented above are the authoritative contract for 19-02 preset generation
- `markPath()` + `wordmarkPath()` + `composeLockup()` is the full generation chain per option
- `integratedTypemark()` covers LOGO-05 integrated typemark studies
- No candidates/ directory created yet — 19-02 creates it and populates it with curated presets

---
*Phase: 19-logo-divergence-user-choice*
*Completed: 2026-06-11*
