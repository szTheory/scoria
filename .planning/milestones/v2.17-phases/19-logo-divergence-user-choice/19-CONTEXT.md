# Phase 19: Logo divergence + user choice - Context

**Gathered:** 2026-06-11
**Status:** Ready for planning
**Source:** Gate #1 locked decisions (brandbook/pressure-test.md §Decisions Locked + §SECTION 8) + approved milestone plan

<domain>
## Phase Boundary

Generate ≥6 genuinely distinct, hand-tuned programmatic SVG logo options (mark + tight lockup each) plus ≥2 integrated logotype-only studies, present them in `brandbook/tools/options-gallery.html` for the user to choose a direction (gate #2). Deliverables: generation tooling in `brandbook/tools/`, the candidate SVGs, the gallery page, and a recorded user choice. NO final variant set (Phase 20), NO tokens/brand-book/index.html (Phase 21).

</domain>

<decisions>
## Implementation Decisions

### Locked inputs from gate #1 (binding)
- Logo direction ranking: 1. **Trace Vesicle Mark** (primary recommendation — vesicle holes form a subtle trace-tree hierarchy: root → LLM → tool → eval), 2. **Cinder Mark** (fallback — irregular faceted cinder, 5–7 scattered holes), 3. **Aperture Mark** (study only — risks camera/eye reading), 4. **Cutaway Cone** (deprioritized — include only if a surprising simplification emerges).
- Tagline (for the subtitle-variant preview only, NOT the main lockup): "AI ops for Phoenix apps."
- Wordmark: "Scoria" in IBM Plex Sans SemiBold (600), Title Case, tracking -1% to 0%.
- Palette for renders: Ember-500 #E65A32 / Molten-400 #FF7A4D accents on dark (Basalt-950 #11100F); Scoria-600 #B94F31 on light (Ash-50 #FAF5EF). Monochrome via currentColor.

### HARD constraints (LOGO-01..07 — every option must satisfy; gallery must demonstrate)
- LOGO-01: NO rectangular background/container shapes. The mark silhouette IS the boundary.
- LOGO-02: Negative space via `fill-rule="evenodd"` punched holes in a single path — holes show the page behind.
- LOGO-03: Logotype optically tight to mark: gap ≈ 0.35–0.5× cap height, optical baseline alignment.
- LOGO-04: NO subtitle in the primary lockup. (A subtitle variant is generated in Phase 20, not here.)
- LOGO-05: ≥2 integrated logotype-only studies — motif worked INTO the letterforms (e.g. the 'o' of Scoria replaced by a vesicle-aperture form whose ring weight matches the stem weight; optionally 1–2 tiny punched vesicles in the 'a' bowl). NOT icon-left-of-text.
- LOGO-06: 16px favicon render is pass/fail evidence in the gallery.
- LOGO-07: Monochrome render (single currentColor fill, holes intact) is pass/fail evidence in the gallery.

### Geometry language (anti-blob discipline)
- Silhouettes: faceted irregular polygons — 6–8 anchors on a perturbed circle, LOW-frequency radius variance only (±12–18%), 1–2 deliberate flat facets ("basalt chunk", not amoeba), uniform corner rounding via quadratic/arc joins. Fills only, NO strokes (16px fuzz risk).
- Holes: 5–7 circular vesicles, one dominant "core" vesicle, deliberate size hierarchy. For Trace Vesicle options the hole positions encode a downward-branching trace tree (root large, children smaller), subtle — readable as texture first, diagram second.
- Curated presets, NOT random seeds: each option is a hand-tuned parameter set committed in the generator. Option mix: Trace Vesicle ×2, Cinder ×2, Aperture ×1, Cutaway Cone ×1 (= 6 marks + lockups), plus ≥2 integrated typemark studies.
- ViewBox hugs the artwork (no padding box). All numbers rounded to ≤2 decimals for clean diffs.

### Tooling
- `brandbook/tools/` gets its own `package.json` with `opentype.js` + `wawoff2` (decompress repo woff2 → ttf buffer at generation time); `node_modules/` gitignored (add brandbook/tools/.gitignore). Node ≥18 ESM scripts.
- Font source: `assets/fonts/ibm-plex-sans_latest_latin-600-normal.woff2` (latin subset covers S-c-o-r-i-a). Convert "Scoria" to outline paths via opentype.js `Font.getPath`. Do NOT commit any font binaries to brandbook/.
- Generator architecture: a geometry library (mark presets → SVG path strings), a wordmark module (text → outlined path + integrated-glyph surgery), a lockup composer (mark + wordmark with LOGO-03 spacing), and a gallery builder that writes options-gallery.html + the candidate SVGs into `brandbook/tools/candidates/`.
- Candidates live in `brandbook/tools/candidates/` (NOT brandbook/ root — only Phase 20's chosen variants graduate to the root). Committed for diffability; losers deleted in Phase 20.
- Generated SVGs may be hand-finished; the generator is reproducible scaffolding, not a lockfile.

### Gallery (gate #2 evidence)
- `brandbook/tools/options-gallery.html`, standalone file:// page, self-contained (inline SVG, no network). Page sections on Basalt-950 AND Ash-50 grounds (backgrounds belong to the page, never the SVG).
- Per option: lockup + mark at 256 / 64 / 32 / 16 px, monochrome row (currentColor on both grounds), simulated browser-tab favicon strip, 24px dashboard-sidebar mock row, README header band mock.
- Integrated typemark studies shown at full width + small sizes.
- Gallery includes a ranked recommendation block (which option and why) and labels each option with a stable ID (e.g. TV-1, TV-2, CM-1, CM-2, AP-1, CC-1, TYPE-1, TYPE-2).
- Gate #2 is presented by the ORCHESTRATOR via AskUserQuestion after the user opens the gallery; "none of these → second round" is an explicit option.

### Claude's Discretion
- Exact preset parameters, hole layouts, facet placement — craft judgment.
- Whether Cutaway Cone earns its slot or is swapped for a third Trace Vesicle variation (keep ≥6 total, keep ≥2 directions beyond Trace Vesicle for honest divergence).
- Gallery page styling (use brand palette; keep it utilitarian and fast).
- Integrated-typemark technique details (glyph replacement preferred; avoid full boolean letterform surgery).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Locked decisions + constraints
- `brandbook/pressure-test.md` — §SECTION 8 (logo system rules, LOGO-01..07, direction ranking), §Decisions Locked, §Gate #1 record
- `.planning/phases/18-pressure-test-audit-decision-lock/18-02-SUMMARY.md` — gate #1 outcome summary

### Source material
- `prompts/scoria-brand-book-deep-research.md` — §logo concepts (the 4 directions' original descriptions), §5 color (hex values)
- `assets/fonts/ibm-plex-sans_latest_latin-600-normal.woff2` — wordmark glyph source (woff2 → decompress at runtime)

### Precedent (read-only)
- `/Users/jon/projects/threadline/brandbook/logo-primary.svg` + `logo-mark.svg` — sibling's SVG conventions (structure, title/desc accessibility tags)

</canonical_refs>

<specifics>
## Specific Ideas

- The trace-tree hole layout should echo the dashboard's span rail: a root vesicle near the top, two-three children branching down-right, one leaf offset — abstract enough to read as porous rock at first glance.
- IBM Plex Sans 'o' is nearly circular — the integrated-typemark replacement 'o' should keep the same advance width and x-height alignment so kerning is undisturbed; ring weight matches the 'S' stem (~the font's stem width at 600 weight).
- SVGs include `<title>` and `role="img"`/`aria-hidden` appropriately per Threadline precedent.
- User taste calibration: "we like somewhat breaking the boundaries" — silhouettes can have one hole bleeding through the edge (a notch/bite) on some options to break the closed-blob feeling.

</specifics>

<deferred>
## Deferred Ideas

- Full variant set (primary dark/light, mono, subtitle, favicon, social card) — Phase 20.
- Hand optical-correction pass — Phase 20 (after direction chosen).
- Any brandbook/ root logo files — Phase 20.

</deferred>

---

*Phase: 19-logo-divergence-user-choice*
*Context gathered: 2026-06-11 from gate #1 locked decisions*
