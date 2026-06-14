/**
 * presets.mjs — Curated, hand-authored logo option presets (Phase 19 craft core)
 *
 * These are NOT loop-generated or seeded-random variations. Each option below is
 * a deliberately tuned parameter set with an explicit `@design-intent` block
 * stating what the option IS and what distinguishes it from its siblings. The
 * 19-01 geometry/wordmark/lockup libraries consume these objects directly:
 *
 *   markPreset  → geometry.markPath(preset)  → single evenodd compound path
 *   markPreset.holes16 → the LOGO-06 16px favicon simplification (exactly 3 holes
 *                        for Trace Vesicle options, vertical/diagonal arrangement)
 *   typemarkPreset → wordmark.integratedTypemark(text, opts)
 *
 * Coordinate system: marks are authored centered near the origin with
 * baseRadius ≈ 50 (so the silhouette spans roughly ±50). Holes are placed in
 * that same space. The libraries compute a tight viewBox that hugs the artwork.
 *
 * Geometry discipline (from 19-CONTEXT §Geometry language):
 *   - 6–8 anchors on a perturbed circle, LOW-frequency radius variance ±12–18%
 *   - 1–2 deliberate flat facets ("basalt chunk", never amoeba)
 *   - holes are circular vesicles with a deliberate size hierarchy + one core
 *   - Trace Vesicle hole positions encode a downward-branching trace tree
 *     (root near top → 2–3 children stepping down-right → one offset leaf),
 *     readable as porous rock first, diagram second.
 *
 * Palette (19-CONTEXT §decisions):
 *   Dark ground accents: Ember-500 #E65A32, Molten-400 #FF7A4D
 *   Light ground mark:   Scoria-600 #B94F31
 *   Monochrome:          currentColor (set by the renderer, not here)
 */

// Brand hexes used as preset render fills (the gallery owns grounds, not the SVG).
export const PALETTE = {
  ember500: '#E65A32', // dark-ground accent
  molten400: '#FF7A4D', // dark-ground bright accent
  scoria600: '#B94F31', // light-ground mark
};

/*
 * ============================================================================
 * TRACE VESICLE — direction #1 (PRIMARY per §8 ranking)
 * The vesicle holes are arranged as a downward-branching trace-node hierarchy
 * (root → child → child → leaf), echoing the dashboard span rail. This is the
 * direction with the strongest internal logic at small sizes.
 * ============================================================================
 */

/**
 * @design-intent TV-1 "Span rail" — the quiet, disciplined Trace Vesicle.
 * A compact, slightly-taller-than-wide cinder whose four holes trace a tight
 * vertical span tree: a dominant root vesicle upper-left, two children stepping
 * down-and-right, one small leaf at the bottom. Low radius variance and a single
 * flat facet keep the silhouette calm and rail-like. This is the most
 * favicon-safe Trace Vesicle: its 16px simplification keeps exactly the three
 * largest nodes (root + first child + leaf) in a clean diagonal (LOGO-06).
 * Distinguished from TV-2 by being tighter, more vertical, fully closed (no
 * edge notch) — the conservative sibling.
 */
export const TV_1 = {
  id: 'TV-1',
  name: 'Span rail',
  direction: 'trace-vesicle',
  fill: PALETTE.ember500,
  // Silhouette: tight, slightly vertical, calm.
  anchors: 7,
  baseRadius: 48,
  radiusVariance: 0.13,
  flatFacets: 1,
  rounding: 7,
  seed: 11,
  edgeNotch: false,
  // Trace tree: root (large) upper-left → child → child stepping down-right → leaf.
  holes: [
    { cx: -16, cy: -22, r: 13 }, // root node (dominant core, upper-left)
    { cx: 2, cy: -2, r: 8.5 }, // first child, stepping down-right
    { cx: 16, cy: 16, r: 6 }, // second child, continuing the rail
    { cx: 6, cy: 30, r: 4 }, // offset leaf at the bottom
  ],
  // LOGO-06: 16px favicon simplification — EXACTLY 3 holes, vertical/diagonal.
  // Keep the three largest nodes; drop the tiny leaf that vanishes sub-2px.
  // Tuned (verified by generate-time geometry math) so each hole clears ≥1.5px
  // AND the inter-hole webs survive: holes spread to the silhouette's diagonal
  // extremes with edge-gaps ≥ 0.5× the smaller radius so they read as 3 holes,
  // not one merged blob, at 16px.
  holes16: [
    { cx: -23, cy: -24, r: 12 }, // root (upper-left)
    { cx: 1, cy: 0, r: 10.5 }, // mid (center)
    { cx: 25, cy: 25, r: 10 }, // leaf (lower-right)
  ],
};

/**
 * @design-intent TV-2 "Open branch" — the dynamic, boundary-breaking Trace
 * Vesicle. Wider and more asymmetric than TV-1, its trace tree branches into
 * TWO leaves at the bottom (a fork, not a single rail), and the lowest-right
 * vesicle bleeds through the silhouette edge as a notch/bite — honouring the
 * user's "we like somewhat breaking the boundaries" taste. Higher radius
 * variance and a flat facet on the upper edge give it more movement. Same
 * trace-tree DNA as TV-1 but louder and open. 16px simplification keeps root +
 * the two surviving branch nodes (LOGO-06).
 */
export const TV_2 = {
  id: 'TV-2',
  name: 'Open branch',
  direction: 'trace-vesicle',
  fill: PALETTE.molten400,
  // Silhouette: wider, more dynamic, one flat facet up top.
  anchors: 8,
  baseRadius: 52,
  radiusVariance: 0.17,
  flatFacets: 1,
  rounding: 6,
  seed: 23,
  edgeNotch: true, // one hole bleeds the right edge as a notch
  // Trace tree: root upper-left → child → FORK into two leaves down-right.
  holes: [
    { cx: -18, cy: -20, r: 13.5 }, // root node (core)
    { cx: 0, cy: -4, r: 8 }, // child
    { cx: 18, cy: 12, r: 6.5 }, // branch leaf A
    { cx: 8, cy: 24, r: 5 }, // branch leaf B (the fork)
    { cx: 34, cy: 22, r: 6, edgeBite: true }, // leaf bleeding the right edge (notch)
  ],
  // LOGO-06: 3-hole favicon — root + the two strongest branch nodes, diagonal.
  // Spread to the diagonal extremes so the webs survive at 16px and the three
  // holes stay distinct (each ≥1.5px, edge-gap ≥ 0.5× smaller radius).
  holes16: [
    { cx: -25, cy: -25, r: 12.5 },
    { cx: 1, cy: 0, r: 11.5 },
    { cx: 27, cy: 25, r: 11 },
  ],
};

/*
 * ============================================================================
 * CINDER — direction #2 (strong favicon/icon fallback per §8 ranking)
 * Irregular faceted cinder chunk, 5–7 scattered holes, NO trace-tree logic —
 * pure porous-rock texture with a deliberate size hierarchy and one flat facet
 * so the chunk "sits". This is the easier-to-read fallback if the Trace Vesicle
 * proves too busy at ≤20px.
 * ============================================================================
 */

/**
 * @design-intent CM-1 "Field sample" — the classic cinder chunk. A confident,
 * slightly angular basalt fragment with 5 holes scattered NON-hierarchically
 * (the opposite of the Trace Vesicle's ordered tree): one dominant core, four
 * satellites of descending size, no diagram logic — it reads as porous rock,
 * full stop. A single flat facet at the BASE gives it a ground line so it sits
 * rather than floats. Distinguished from CM-2 by lower porosity (5 vs 6–7
 * holes), larger core, and the flat facet at the bottom rather than top-left.
 */
export const CM_1 = {
  id: 'CM-1',
  name: 'Field sample',
  direction: 'cinder',
  fill: PALETTE.ember500,
  anchors: 7,
  baseRadius: 50,
  radiusVariance: 0.16,
  flatFacets: 1,
  rounding: 5,
  seed: 41,
  edgeNotch: false,
  // Scattered porosity: one core + four descending satellites, no tree.
  holes: [
    { cx: -8, cy: -14, r: 14 }, // dominant core
    { cx: 18, cy: -8, r: 7 }, // satellite
    { cx: -22, cy: 12, r: 6 }, // satellite
    { cx: 10, cy: 18, r: 5 }, // satellite
    { cx: 26, cy: 20, r: 3.5 }, // smallest satellite
  ],
};

/**
 * @design-intent CM-2 "Tumbled" — the softer cinder sibling. Rounder silhouette
 * (more anchors, gentler facets, larger corner rounding) with HIGHER porosity:
 * 7 smaller, more evenly-sized holes for a tumbled-pumice texture feel, no single
 * dominant core. A flat facet at the UPPER-LEFT contrasts CM-1's base facet.
 * Where CM-1 is an angular field specimen, CM-2 is a rolled, weathered stone —
 * the same direction explored toward roundness and even porosity.
 */
export const CM_2 = {
  id: 'CM-2',
  name: 'Tumbled',
  direction: 'cinder',
  fill: PALETTE.molten400,
  anchors: 8,
  baseRadius: 50,
  radiusVariance: 0.12, // rounder
  flatFacets: 1,
  rounding: 9, // softer corners
  seed: 57,
  edgeNotch: false,
  // Higher, more even porosity — no dominant core.
  holes: [
    { cx: -12, cy: -16, r: 8.5 },
    { cx: 8, cy: -14, r: 7 },
    { cx: -20, cy: 4, r: 6.5 },
    { cx: 2, cy: 2, r: 7.5 },
    { cx: 20, cy: 6, r: 6 },
    { cx: -6, cy: 22, r: 6 },
    { cx: 16, cy: 24, r: 5 },
  ],
};

/*
 * ============================================================================
 * APERTURE — direction #3 (STUDY ONLY per §8 ranking)
 * Central cavity + surrounding smaller cavities. Honest study — flagged because
 * it RISKS reading as a camera aperture / eye (generic, off-metaphor). Included
 * so the user can see and reject the direction with evidence, not in the
 * abstract.
 * ============================================================================
 */

/**
 * @design-intent AP-1 "Aperture study" — STUDY ONLY, expected to read
 * aperture-ish (that is the point of including it). A near-symmetric cinder with
 * a single large CENTRAL cavity ringed by four evenly-spaced satellite cavities.
 * The radial symmetry is exactly what makes it risk reading as a camera iris or
 * eye — generic and off-metaphor versus the Trace Vesicle's asymmetric internal
 * logic. Lowest radius variance of any option (most circular silhouette) to make
 * the aperture risk legible. Documented as #3 / study per §8 ranking.
 */
export const AP_1 = {
  id: 'AP-1',
  name: 'Aperture study',
  direction: 'aperture',
  fill: PALETTE.ember500,
  anchors: 8,
  baseRadius: 50,
  radiusVariance: 0.1, // most circular — surfaces the aperture/eye risk
  flatFacets: 0,
  rounding: 10,
  seed: 7,
  edgeNotch: false,
  // Central cavity + 4 satellites in radial symmetry (the aperture/eye risk).
  holes: [
    { cx: 0, cy: 0, r: 15 }, // large central cavity
    { cx: 0, cy: -26, r: 5.5 }, // satellite N
    { cx: 26, cy: 0, r: 5.5 }, // satellite E
    { cx: 0, cy: 26, r: 5.5 }, // satellite S
    { cx: -26, cy: 0, r: 5.5 }, // satellite W
  ],
};

/*
 * ============================================================================
 * SIXTH SLOT — discretionary (19-CONTEXT §Claude's Discretion)
 * Choice: a THIRD Trace Vesicle (TV-3) rather than a Cutaway Cone (CC-1).
 *
 * Rationale (documented per plan): The §8 ranking de-prioritizes Cutaway Cone to
 * #4 precisely because a cross-section of a cone loses its silhouette at 16px —
 * it fails the single hardest test (favicon survival) by construction, so a CC-1
 * slot would spend craft on a direction the audit already expects to fail. The
 * brief explicitly permits swapping CC-1 for a third Trace Vesicle to deepen the
 * winning direction while still keeping ≥2 directions beyond Trace Vesicle
 * (Cinder ×2 + Aperture ×1 satisfy that). TV-3 explores a horizontal-rail trace
 * tree — a genuinely different reading of the #1 direction, not parameter noise —
 * giving the user three real Trace Vesicle choices to pick the silhouette they
 * like best at gate #2.
 * ============================================================================
 */

/**
 * @design-intent TV-3 "Cross rail" — the third Trace Vesicle, a horizontal
 * reading of the trace tree. Where TV-1 runs the span rail vertically and TV-2
 * forks it open, TV-3 lays the hierarchy along a left-to-right diagonal: root
 * upper-left, children marching ACROSS to the right at a shallow slope, leaf
 * trailing. Wider-than-tall silhouette (the only landscape-ish Trace Vesicle),
 * two flat facets giving a chiselled, almost arrow-like chunk. This is the sixth
 * slot, chosen over a Cutaway Cone (see block above) to give the user a third
 * honest take on the #1 direction. 16px keeps root + two strongest cross nodes.
 */
export const TV_3 = {
  id: 'TV-3',
  name: 'Cross rail',
  direction: 'trace-vesicle',
  fill: PALETTE.molten400,
  anchors: 7,
  baseRadius: 50,
  radiusVariance: 0.15,
  flatFacets: 2, // chiselled, arrow-ish
  rounding: 6,
  seed: 31,
  edgeNotch: false,
  // Horizontal trace tree: root left → children marching right → trailing leaf.
  holes: [
    { cx: -26, cy: -8, r: 13 }, // root (left)
    { cx: -6, cy: -2, r: 8.5 }, // child
    { cx: 14, cy: 4, r: 6.5 }, // child (marching right)
    { cx: 30, cy: 10, r: 4.5 }, // trailing leaf
  ],
  // LOGO-06: 3-hole favicon — root + two cross nodes along a SHALLOW horizontal
  // diagonal (preserving TV-3's left-to-right cross-rail identity at favicon
  // size). Spread to the horizontal extremes so webs survive and holes stay
  // distinct at 16px (each ≥1.5px, edge-gap ≥ 0.5× smaller radius).
  holes16: [
    { cx: -30, cy: -8, r: 12 },
    { cx: -1, cy: 0, r: 11 },
    { cx: 28, cy: 8, r: 10.5 },
  ],
};

/*
 * ============================================================================
 * INTEGRATED TYPEMARKS — LOGO-05 (first-class, not a fallback)
 * The vesicle motif worked INTO the "Scoria" letterforms via glyph replacement
 * (NO full boolean letterform surgery): the 'o' becomes a vesicle ring whose
 * weight matches the 'S' stem and whose advance width + x-height are preserved
 * so kerning is undisturbed. The integratedTypemark() library does the ring
 * substitution; these presets carry the typographic + (for TYPE-2) extra-punch
 * intent.
 * ============================================================================
 */

/**
 * @design-intent TYPE-1 "Ring o" — the clean integrated typemark. "Scoria" set
 * in IBM Plex Sans SemiBold with ONLY the 'o' replaced by a vesicle ring: outer
 * diameter matches the 'o' x-height, ring weight ≈ the 'S' stem, advance width
 * preserved so the word kerns identically to the plain wordmark. One precise
 * intervention — the motif reads as a deliberate detail, not a gimmick.
 * Distinguished from TYPE-2 by being the minimal, single-glyph treatment.
 */
export const TYPE_1 = {
  id: 'TYPE-1',
  name: 'Ring o',
  text: 'Scoria',
  fontSize: 100,
  tracking: -0.005, // -0.5%, within the -1%..0% locked range
  oReplacement: true,
  extraPunches: false,
  fill: PALETTE.scoria600,
};

/**
 * @design-intent TYPE-2 "Porous a" — the textured integrated typemark. Same
 * vesicle-ring 'o' as TYPE-1, PLUS 1–2 tiny punched vesicles in the bowl of the
 * 'a' — subtle porosity that ties the whole wordmark to the cinder motif without
 * tipping into noise (the punches are small enough to read as texture, not as a
 * second focal point). Distinguished from TYPE-1 by carrying the porosity across
 * a second letterform — the richer, more committed integration.
 */
export const TYPE_2 = {
  id: 'TYPE-2',
  name: 'Porous a',
  text: 'Scoria',
  fontSize: 100,
  tracking: -0.005,
  oReplacement: true,
  extraPunches: true, // tiny vesicles punched into the 'a' bowl
  fill: PALETTE.scoria600,
};

/**
 * Ordered, hand-authored mark presets (≥6, ≥3 directions).
 * Trace Vesicle ×3 (TV-1/2/3), Cinder ×2 (CM-1/2), Aperture ×1 (AP-1, study).
 */
export const markPresets = [TV_1, TV_2, TV_3, CM_1, CM_2, AP_1];

/** Ordered, hand-authored integrated typemark presets (≥2). */
export const typemarkPresets = [TYPE_1, TYPE_2];

export default { markPresets, typemarkPresets, PALETTE };
