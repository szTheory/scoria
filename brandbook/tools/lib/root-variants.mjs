/**
 * root-variants.mjs — Phase 20 convergence: the 8 canonical root logo composers.
 *
 * GEOMETRY IS FROZEN at gate #2. Every path `d` string here is COPIED VERBATIM
 * from the locked candidate artwork in candidates/ (LK-B-lockup.svg, TV-1-mark.svg,
 * TV-1-fav.svg) — these composers ONLY recolor, substitute currentColor, tighten
 * the viewBox, snap the favicon to the pixel grid, and (for subtitle/social) add
 * outlined tagline text. They NEVER perturb a silhouette or hole coordinate.
 *
 * Source of truth for the fused lockup:
 *   candidates/LK-B-lockup.svg carries TWO <path fill="#E65A32" fill-rule="evenodd">:
 *     (1) the "Sc..ria" letterform path (wordmark MINUS its 'o')
 *     (2) a <g transform="translate(141.57,-23.23) scale(0.58)"> wrapping the
 *         TV-1 mark path that sits AS the 'o' (x-height sized, holes = counter).
 *   We read those two paths + the group transform straight off disk so this file
 *   stays a recolor layer over the frozen artwork, not a redraw.
 *
 * Census colorways (20-CONTEXT §decisions):
 *   White-Hot  #FFF9F3  letters on dark surface
 *   Basalt-950 #11100F  letters on light surface / social-card ground
 *   Ember-500  #E65A32  mark / mark-'o' accent (default brand colorway)
 *   Scoria-600 #B94F31  mark-'o' on light surface (two-tone)
 *
 * presets.mjs is imported only for TV_1.holes16 (the favicon 3-hole simplification)
 * and PALETTE, keeping the TV-1 / holes16 lineage link explicit (plan key_link).
 */

import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

import { TV_1, PALETTE } from '../presets.mjs';
import { vesicleHoles, pathBBox } from './geometry.mjs';
import { wordmarkPath } from './wordmark.mjs';

const __dir = dirname(fileURLToPath(import.meta.url));
const CANDIDATES = join(__dir, '..', 'candidates');

// --- Census colorways --------------------------------------------------------
export const COLORWAY = {
  whiteHot: '#FFF9F3', // letters on dark surface
  basalt950: '#11100F', // letters on light surface + social-card ground
  ember500: PALETTE.ember500, // #E65A32 — mark / mark-'o' accent
  scoria600: PALETTE.scoria600, // #B94F31 — mark-'o' on light surface (two-tone)
};

// Optical-pass decision (documented in variant-spec.md, Task 2): the primary
// lockup ships TWO-TONE — letters in the surface ink, the mark-'o' in the brand
// accent. The ink-density review (mark 0.61 vs round letters 0.57, root hole
// micro-tuned in 19-02b) confirms the accent reads as a deliberate focal 'o',
// not a heavier glyph. Flip this single flag to ship single-tone instead.
export const PRIMARY_TWO_TONE = true;

function r2(x) {
  return Math.round(x * 100) / 100;
}

// --- Frozen LK-B lockup artwork (read verbatim from disk) --------------------
/**
 * Extract the two frozen paths + the mark group transform from the locked
 * LK-B-lockup.svg. Returns the letterform `d`, the mark `d`, and the
 * translate/scale that places the mark AS the 'o'. NOTHING is recomputed.
 */
function lkbArtwork() {
  const svg = readFileSync(join(CANDIDATES, 'LK-B-lockup.svg'), 'utf8');

  // Path 1: the letterform path (first <path ... d="...">), OUTSIDE the <g>.
  // Path 2: the mark path, INSIDE <g transform="translate(...) scale(...)">.
  const gMatch = svg.match(/<g transform="(translate\([^)]*\)\s*scale\([^)]*\))">\s*<path[^>]*\sd="([^"]+)"\s*\/?>/);
  if (!gMatch) throw new Error('root-variants: could not parse mark group from LK-B-lockup.svg');
  const markTransform = gMatch[1];
  const markD = gMatch[2];

  // The letterform path is the first <path> that is NOT the mark path.
  const pathRe = /<path[^>]*\sd="([^"]+)"/g;
  let letterD = null;
  let m;
  while ((m = pathRe.exec(svg)) !== null) {
    if (m[1] !== markD) {
      letterD = m[1];
      break;
    }
  }
  if (!letterD) throw new Error('root-variants: could not parse letterform path from LK-B-lockup.svg');

  return { letterD, markD, markTransform };
}

/**
 * Compute a tight viewBox over the fused lockup (letterform path + transformed
 * mark). The mark is transformed by translate()+scale(), so its bbox is mapped
 * into lockup space before the union. Pure measurement — no geometry change.
 */
function lockupViewBox({ letterD, markD, markTransform }, pad = 1) {
  const tMatch = markTransform.match(/translate\(([-\d.]+),\s*([-\d.]+)\)\s*scale\(([-\d.]+)\)/);
  const [tx, ty, s] = [parseFloat(tMatch[1]), parseFloat(tMatch[2]), parseFloat(tMatch[3])];
  const lb = pathBBox(letterD);
  const mb0 = pathBBox(markD);
  const mb = {
    minX: mb0.minX * s + tx, minY: mb0.minY * s + ty,
    maxX: mb0.maxX * s + tx, maxY: mb0.maxY * s + ty,
  };
  const minX = Math.min(lb.minX, mb.minX);
  const minY = Math.min(lb.minY, mb.minY);
  const maxX = Math.max(lb.maxX, mb.maxX);
  const maxY = Math.max(lb.maxY, mb.maxY);
  return {
    vb: `${r2(minX - pad)} ${r2(minY - pad)} ${r2(maxX - minX + pad * 2)} ${r2(maxY - minY + pad * 2)}`,
    bbox: { minX, minY, maxX, maxY },
  };
}

/**
 * Emit a fused-lockup SVG from the frozen artwork with explicit colors.
 * @param {object} opts
 * @param {string} opts.letterFill  fill for the "Sc..ria" letterforms
 * @param {string} opts.markFill    fill for the mark-'o' (== letterFill for single-tone)
 * @param {string} opts.label       aria-label / title text
 */
function fusedLockup(art, { letterFill, markFill, label }) {
  const { vb } = lockupViewBox(art);
  return [
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${vb}" role="img" aria-label="${label}" data-variant="LK-B" data-integrated="true">`,
    `  <title>${label}</title>`,
    `  <path fill="${letterFill}" fill-rule="evenodd" d="${art.letterD}"/>`,
    `  <g transform="${art.markTransform}">`,
    `    <path fill="${markFill}" fill-rule="evenodd" d="${art.markD}"/>`,
    `  </g>`,
    `</svg>`,
  ].join('\n');
}

// --- 1. logo-primary.svg (dark surface) --------------------------------------
export function logoPrimary() {
  const art = lkbArtwork();
  const markFill = PRIMARY_TWO_TONE ? COLORWAY.ember500 : COLORWAY.whiteHot;
  return fusedLockup(art, {
    letterFill: COLORWAY.whiteHot,
    markFill,
    label: 'Scoria',
  });
}

// --- 2. logo-primary-light.svg (light surface) -------------------------------
export function logoPrimaryLight() {
  const art = lkbArtwork();
  const markFill = PRIMARY_TWO_TONE ? COLORWAY.scoria600 : COLORWAY.basalt950;
  return fusedLockup(art, {
    letterFill: COLORWAY.basalt950,
    markFill,
    label: 'Scoria',
  });
}

// --- 3. logo-mark.svg (TV-1 mark alone) --------------------------------------
/**
 * The standalone TV-1 mark, recolored to the default Ember brand colorway.
 * Path + viewBox copied verbatim from candidates/TV-1-mark.svg (Threadline
 * conventions: role="img" + <title> + <desc>).
 */
export function logoMark() {
  const svg = readFileSync(join(CANDIDATES, 'TV-1-mark.svg'), 'utf8');
  const vb = svg.match(/viewBox="([^"]+)"/)[1];
  const d = svg.match(/<path[^>]*\sd="([^"]+)"/)[1];
  return [
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${vb}" role="img" aria-labelledby="title desc">`,
    `  <title id="title">Scoria mark</title>`,
    `  <desc id="desc">A porous cinder whose vesicle holes trace a downward span rail.</desc>`,
    `  <path fill="${COLORWAY.ember500}" fill-rule="evenodd" d="${d}"/>`,
    `</svg>`,
  ].join('\n');
}

// --- 4. logo-monochrome.svg (single currentColor fill) -----------------------
export function logoMonochrome() {
  const art = lkbArtwork();
  return fusedLockup(art, {
    letterFill: 'currentColor',
    markFill: 'currentColor',
    label: 'Scoria',
  });
}

// --- 6. logotype-integrated.svg ----------------------------------------------
/**
 * The fused wordmark in single-color (currentColor) form. Per 20-CONTEXT
 * "since LK-B IS the integrated logotype, this file is the canonical typemark
 * deliverable." Decision (documented in variant-spec.md): logotype-integrated
 * is BYTE-IDENTICAL to logo-monochrome — they share the same fused lineage and
 * the single-color currentColor treatment IS the integrated typemark. Keeping
 * them identical means one source of truth; downstream consumers can alias.
 */
export function logotypeIntegrated() {
  return logoMonochrome();
}

// --- 5. logo-lockup-subtitle.svg ---------------------------------------------
/**
 * The fused lockup (dark colorway) with the tagline set BENEATH it, outlined to
 * paths via wordmarkPath() (open tracking, smaller size). The ONLY root SVG
 * carrying the tagline. Geometry of the lockup is frozen; the tagline is new
 * outlined type placed below the lockup's baseline.
 */
export async function logoLockupSubtitle() {
  const art = lkbArtwork();
  const { bbox } = lockupViewBox(art, 0);

  const TAGLINE = 'AI ops for Phoenix apps.';
  // Tagline ~28% of lockup cap-height, tracked open (+4%), centered under the lockup.
  const tagSize = 21;
  const tag = await wordmarkPath(TAGLINE, { fontSize: tagSize, tracking: 0.04 });
  const lockupW = bbox.maxX - bbox.minX;
  const tagW = tag.bbox.x2 - tag.bbox.x1;
  // Center tagline horizontally under the lockup; sit it 22u below the baseline (y=0).
  const tagX = r2(bbox.minX + (lockupW - tagW) / 2 - tag.bbox.x1);
  const tagBaselineY = 24; // below the wordmark baseline (lockup baseline ≈ y=0)
  const tagY = tagBaselineY;

  const pad = 1;
  const minX = Math.min(bbox.minX, tag.bbox.x1 + tagX);
  const maxX = Math.max(bbox.maxX, tag.bbox.x2 + tagX);
  const minY = bbox.minY;
  const maxY = Math.max(bbox.maxY, tag.bbox.y2 + tagY);
  const vb = `${r2(minX - pad)} ${r2(minY - pad)} ${r2(maxX - minX + pad * 2)} ${r2(maxY - minY + pad * 2)}`;

  return [
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${vb}" role="img" aria-label="Scoria — AI ops for Phoenix apps." data-variant="LK-B" data-integrated="true">`,
    `  <title>Scoria — AI ops for Phoenix apps.</title>`,
    `  <path fill="${COLORWAY.whiteHot}" fill-rule="evenodd" d="${art.letterD}"/>`,
    `  <g transform="${art.markTransform}">`,
    `    <path fill="${COLORWAY.ember500}" fill-rule="evenodd" d="${art.markD}"/>`,
    `  </g>`,
    `  <path fill="${COLORWAY.whiteHot}" fill-rule="evenodd" d="${tag.d}" transform="translate(${tagX},${tagY})"/>`,
    `</svg>`,
  ].join('\n');
}

// --- 7. favicon.svg ----------------------------------------------------------
/**
 * The TV-1 holes16 3-hole simplification, pixel-grid SNAPPED to even integers on
 * a 16-unit grid. We re-emit the outer silhouette VERBATIM from candidates/
 * TV-1-fav.svg (frozen geometry) and replace ONLY the three hole subpaths with
 * snapped circles built from TV_1.holes16 (centers/radii rounded to even values).
 * Each hole ≥1.5px radius at 16px render (verified in variant-spec.md). Minimal
 * markup (aria-label only, no <title>/<desc>) to stay ≤1KB on disk.
 */
export function favicon() {
  const fav = readFileSync(join(CANDIDATES, 'TV-1-fav.svg'), 'utf8');
  const vb = fav.match(/viewBox="([^"]+)"/)[1];
  const dFull = fav.match(/<path[^>]*\sd="([^"]+)"/)[1];
  // Outer silhouette = everything up to (not incl.) the first hole subpath after
  // the silhouette's own Z. The compound path is: <silhouette ...Z> <hole1 M...Z>
  // <hole2 M...Z> <hole3 M...Z>. Keep the silhouette verbatim, drop the holes.
  const firstHoleIdx = dFull.indexOf('M', dFull.indexOf('Z') + 1);
  const silhouette = dFull.slice(0, firstHoleIdx);

  // Snap holes16 to even integers on the 16-grid (centers AND radii even).
  const snap2 = (n) => Math.round(n / 2) * 2;
  const snapped = TV_1.holes16.map((h) => ({
    cx: snap2(h.cx),
    cy: snap2(h.cy),
    r: snap2(h.r),
  }));
  const holesD = vesicleHoles(snapped);

  const d = silhouette + holesD;
  return [
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${vb}" role="img" aria-label="Scoria favicon">`,
    `<path fill="${COLORWAY.ember500}" fill-rule="evenodd" d="${d}"/>`,
    `</svg>`,
  ].join('\n');
}

// --- 8. social-card.svg ------------------------------------------------------
/**
 * 1280×640 bounded card artwork. The ONLY root SVG with a <rect> (the card-ground
 * — documented exemption: the card IS a bounded artwork, not a logo background).
 * Composes the frozen LK-B lockup (white-hot letters, ember 'o') + the tagline +
 * a calm repo hint line, all outlined to paths, centered on the Basalt-950 ground.
 */
export async function socialCard() {
  const art = lkbArtwork();
  const { bbox } = lockupViewBox(art, 0);

  const W = 1280;
  const H = 640;

  // Scale the lockup to ~46% of card width, centered.
  const lockupW = bbox.maxX - bbox.minX;
  const lockupH = bbox.maxY - bbox.minY;
  const targetW = W * 0.46;
  const s = r2(targetW / lockupW);
  const drawW = lockupW * s;
  const drawH = lockupH * s;
  // Center the lockup a little above the vertical middle to leave room for text.
  const lockX = r2((W - drawW) / 2 - bbox.minX * s);
  const lockY = r2(H * 0.42 - bbox.minY * s - drawH / 2 + drawH / 2);
  // Place lockup so its bbox top sits at ~38% height.
  const lockTy = r2(H * 0.30 - bbox.minY * s);
  const lockTx = r2((W - drawW) / 2 - bbox.minX * s);

  // Tagline outlined, centered below the lockup.
  const TAGLINE = 'AI ops for Phoenix apps.';
  const tagSize = 40;
  const tag = await wordmarkPath(TAGLINE, { fontSize: tagSize, tracking: 0.03 });
  const tagW = tag.bbox.x2 - tag.bbox.x1;
  const tagTx = r2((W - tagW) / 2 - tag.bbox.x1);
  const tagBaseline = r2(H * 0.30 + drawH + 78);
  const tagTy = tagBaseline;

  // Repo hint line (calm, evidence-not-hype voice), smaller + dimmer.
  const HINT = 'Open source on GitHub';
  const hintSize = 26;
  const hint = await wordmarkPath(HINT, { fontSize: hintSize, tracking: 0.02 });
  const hintW = hint.bbox.x2 - hint.bbox.x1;
  const hintTx = r2((W - hintW) / 2 - hint.bbox.x1);
  const hintTy = r2(tagBaseline + 52);

  return [
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${H}" role="img" aria-label="Scoria — AI ops for Phoenix apps. Open source on GitHub.">`,
    `  <title>Scoria — AI ops for Phoenix apps.</title>`,
    // The ONLY permitted root <rect>: the card ground (documented exemption,
    // 20-CONTEXT "the card IS a bounded artwork, not a logo background").
    `  <rect width="${W}" height="${H}" fill="${COLORWAY.basalt950}"/>`,
    `  <g transform="translate(${lockTx},${lockTy}) scale(${s})">`,
    `    <path fill="${COLORWAY.whiteHot}" fill-rule="evenodd" d="${art.letterD}"/>`,
    `    <g transform="${art.markTransform}">`,
    `      <path fill="${COLORWAY.ember500}" fill-rule="evenodd" d="${art.markD}"/>`,
    `    </g>`,
    `  </g>`,
    `  <path fill="${COLORWAY.whiteHot}" fill-rule="evenodd" d="${tag.d}" transform="translate(${tagTx},${tagTy})"/>`,
    `  <path fill="${COLORWAY.scoria600}" fill-rule="evenodd" d="${hint.d}" transform="translate(${hintTx},${hintTy})"/>`,
    `</svg>`,
  ].join('\n');
}
