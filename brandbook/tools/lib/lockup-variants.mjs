/**
 * lockup-variants.mjs — Round-2 mark↔wordmark relationship studies (Phase 19-02b)
 *
 * Gate #2 escape (#2) fired: direction LOCKED to TV-1 "Span rail", but the
 * mark↔wordmark RELATIONSHIP needs divergence (the user asked to "consider
 * different variations on the lockup between the image and text"), and the two
 * integrated typemarks (TYPE-1 ring 'o', TYPE-2 porous 'a') were REJECTED.
 *
 * Every composer here builds on the LOCKED TV-1 mark geometry (imported from
 * presets.mjs, untouched) — only placement/scale/relationship changes. The one
 * exception is LK-B "Mark-as-o", which applies a single DOCUMENTED optical
 * micro-tune (root hole r 13→14.6) so the mark's ink density at glyph scale
 * matches the surrounding letters' (0.567); the standalone TV-1-mark.svg file
 * is never modified.
 *
 * All output obeys: evenodd punching only, no <rect>, no strokes, no subtitle,
 * coordinates ≤2 decimals, viewBox hugs the artwork.
 *
 * Public API (each returns an SVG string):
 *   classicTight(opts)   → LK-A  mark left of wordmark (baseline reference)
 *   markAsO(opts)        → LK-B  TV-1 mark scaled AS the 'o' glyph of "Scoria"
 *   stacked(opts)        → LK-C  mark centered above the wordmark
 *   overlap(opts)        → LK-D  mark notching INTO the leading 'S'
 *   counterPunch(opts)   → LK-E  trace-tree punched THROUGH the capital 'S'
 *   markAsDot(opts)      → LK-F  mark AS the tittle of the 'i' (micro-integration)
 */

import { markPath, pathBBox } from './geometry.mjs';
import { TV_1 } from '../presets.mjs';
import { loadFont, wordmarkPath } from './wordmark.mjs';

/** Round to ≤2 decimals. */
function r2(x) {
  return Math.round(x * 100) / 100;
}

/** Tight viewBox over an array of bboxes {minX,minY,maxX,maxY}. */
function viewBoxOf(bboxes, pad = 1) {
  const minX = Math.min(...bboxes.map((b) => b.minX));
  const minY = Math.min(...bboxes.map((b) => b.minY));
  const maxX = Math.max(...bboxes.map((b) => b.maxX));
  const maxY = Math.max(...bboxes.map((b) => b.maxY));
  return `${r2(minX - pad)} ${r2(minY - pad)} ${r2(maxX - minX + pad * 2)} ${r2(maxY - minY + pad * 2)}`;
}

/** Translate a bbox by (dx,dy). */
function shiftBBox(b, dx, dy) {
  return { minX: b.minX + dx, minY: b.minY + dy, maxX: b.maxX + dx, maxY: b.maxY + dy };
}

/** Scale+translate a bbox: first scale about origin, then translate. */
function scaleShiftBBox(b, s, dx, dy) {
  return {
    minX: b.minX * s + dx,
    minY: b.minY * s + dy,
    maxX: b.maxX * s + dx,
    maxY: b.maxY * s + dy,
  };
}

/** The locked TV-1 mark path + its bbox (geometry never mutated). */
function tv1Mark() {
  const d = markPath({
    anchors: TV_1.anchors,
    baseRadius: TV_1.baseRadius,
    radiusVariance: TV_1.radiusVariance,
    flatFacets: TV_1.flatFacets,
    rounding: TV_1.rounding,
    seed: TV_1.seed,
    holes: TV_1.holes,
  });
  return { d, box: pathBBox(d) };
}

/**
 * LK-B optical micro-tune: TV-1 with the root hole r 13→14.6 so the mark's
 * ink density at glyph scale lands near the 'o'-letter density (0.567) instead
 * of running 11% bolder. Documented, scoped to this lockup only.
 */
function tv1MarkOTuned() {
  const holes = TV_1.holes.map((h, i) => (i === 0 ? { ...h, r: 14.6 } : h));
  const d = markPath({
    anchors: TV_1.anchors,
    baseRadius: TV_1.baseRadius,
    radiusVariance: TV_1.radiusVariance,
    flatFacets: TV_1.flatFacets,
    rounding: TV_1.rounding,
    seed: TV_1.seed,
    holes,
  });
  return { d, box: pathBBox(d) };
}

const FONT_SIZE = 100;
const TRACKING = -0.005;

/** Per-glyph metrics for "Scoria" at FONT_SIZE/TRACKING (advance origins + bboxes). */
async function scoriaGlyphs() {
  const font = await loadFont();
  const scale = FONT_SIZE / font.unitsPerEm;
  const trackingPx = TRACKING * FONT_SIZE;
  const text = 'Scoria';
  let x = 0;
  const glyphs = [];
  for (const ch of text) {
    const g = font.charToGlyph(ch);
    const bb = g.getPath(x, 0, FONT_SIZE).getBoundingBox();
    glyphs.push({
      ch,
      advX: x,
      adv: r2(g.advanceWidth * scale),
      bbox: { x1: r2(bb.x1), y1: r2(bb.y1), x2: r2(bb.x2), y2: r2(bb.y2) },
    });
    x += g.advanceWidth * scale + trackingPx;
  }
  const capHeight = r2((font.tables?.os2?.sCapHeight ?? 700) * scale);
  return { glyphs, totalAdvance: r2(x), capHeight };
}

// ── LK-A: Classic tight (baseline reference) ────────────────────────────────
/**
 * Mark left of wordmark at a LOGO-03 gap. This reproduces the gate-#2 default
 * lockup so round-2 has a fixed point of comparison. Labelled "baseline" in the
 * gallery. Mark height matched to cap height; gap = 0.4 × cap height.
 */
async function classicTight() {
  const { d: markD, box } = tv1Mark();
  const wm = await wordmarkPath('Scoria', { fontSize: FONT_SIZE, tracking: TRACKING });
  const capHeight = wm.capHeight;
  const markH = box.maxY - box.minY;
  const s = r2(capHeight / markH);
  const scaledMarkW = r2((box.maxX - box.minX) * s);
  const gap = r2(0.4 * capHeight);

  const markTx = r2(-box.minX * s);
  const markTy = r2(-box.minY * s);
  const wmX = r2(scaledMarkW + gap - wm.bbox.x1);
  const wmY = r2(-wm.bbox.y1);

  const markBB = { minX: 0, minY: 0, maxX: scaledMarkW, maxY: r2(markH * s) };
  const wmBB = {
    minX: r2(wm.bbox.x1 + wmX),
    minY: r2(wm.bbox.y1 + wmY),
    maxX: r2(wm.bbox.x2 + wmX),
    maxY: r2(wm.bbox.y2 + wmY),
  };
  const vb = viewBoxOf([markBB, wmBB]);

  return [
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${vb}" role="img" aria-label="Scoria — LK-A classic tight" data-gap-ratio="0.4" data-variant="LK-A">`,
    `  <title>Scoria — LK-A classic tight (baseline)</title>`,
    `  <g transform="translate(${markTx},${markTy}) scale(${s})">`,
    `    <path fill="${TV_1.fill}" fill-rule="evenodd" d="${markD}"/>`,
    `  </g>`,
    `  <path fill="${TV_1.fill}" fill-rule="evenodd" d="${wm.d}" transform="translate(${wmX},${wmY})"/>`,
    `</svg>`,
  ].join('\n');
}

// ── LK-B: Mark-as-o ─────────────────────────────────────────────────────────
/**
 * The TV-1 mark IS the 'o' of "Scoria". The mark is scaled to the x-height band
 * and dropped into the 'o' advance slot; S, c, r, i, a are set normally around
 * it. Geometry math (diagnostics): at x-height scale the mark's width (56.68)
 * matches the 'o' advance (56.30) to within 0.4u, so kerning is undisturbed.
 * The root hole is micro-tuned (r 13→14.6) so ink density (0.614) approaches
 * the 'o'-letter density (0.567) — the mark does not read bolder than its
 * neighbours. The mark's holes literally become the letter's counter, unifying
 * mark and wordmark into ONE object — the honest answer to "fully integrated".
 */
async function markAsO() {
  const { d: markD, box } = tv1MarkOTuned();
  const { glyphs } = await scoriaGlyphs();
  const font = await loadFont();

  // x-height band from the actual 'o' glyph bbox (incl. overshoot).
  const o = glyphs.find((g) => g.ch === 'o');
  const xhTop = o.bbox.y1; // -53.40
  const xhBot = o.bbox.y2; // 1.20
  const xh = xhBot - xhTop;

  const markH = box.maxY - box.minY;
  const s = r2(xh / markH);
  const mcx = (box.minX + box.maxX) / 2;
  const mcy = (box.minY + box.maxY) / 2;

  // Center mark in the 'o' advance box horizontally, x-height band vertically.
  const advCx = o.advX + o.adv / 2;
  const cyBand = (xhTop + xhBot) / 2;
  const tx = r2(advCx - mcx * s);
  const ty = r2(cyBand - mcy * s);

  // Build the wordmark WITHOUT the 'o' (replace with the mark group).
  let dRest = '';
  for (const g of glyphs) {
    if (g.ch === 'o') continue;
    const glyph = font.charToGlyph(g.ch);
    const p = glyph.getPath(g.advX, 0, FONT_SIZE);
    dRest += pathToD(p);
  }

  // bboxes
  const markBB = scaleShiftBBox(box, s, tx, ty);
  const last = glyphs[glyphs.length - 1];
  const first = glyphs[0];
  const wmBB = {
    minX: first.bbox.x1,
    minY: Math.min(...glyphs.filter((g) => g.ch !== 'o').map((g) => g.bbox.y1)),
    maxX: last.bbox.x2,
    maxY: Math.max(...glyphs.filter((g) => g.ch !== 'o').map((g) => g.bbox.y2)),
  };
  const vb = viewBoxOf([markBB, wmBB]);

  return [
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${vb}" role="img" aria-label="Scoria — LK-B mark-as-o" data-variant="LK-B" data-integrated="true">`,
    `  <title>Scoria — LK-B mark-as-o (integrated)</title>`,
    `  <path fill="${TV_1.fill}" fill-rule="evenodd" d="${dRest}"/>`,
    `  <g transform="translate(${tx},${ty}) scale(${s})">`,
    `    <path fill="${TV_1.fill}" fill-rule="evenodd" d="${markD}"/>`,
    `  </g>`,
    `</svg>`,
  ].join('\n');
}

// ── LK-C: Stacked ───────────────────────────────────────────────────────────
/**
 * Mark centered ABOVE the wordmark — the vertical lockup for square/social/app
 * contexts. Mark scaled so its width ≈ 0.5× the wordmark width (a confident but
 * not dominant cap above the word). Gap between mark base and wordmark cap-top =
 * 0.5 × cap height (LOGO-03 vertical reading). Centered on the wordmark's
 * horizontal midpoint.
 */
async function stacked() {
  const { d: markD, box } = tv1Mark();
  const wm = await wordmarkPath('Scoria', { fontSize: FONT_SIZE, tracking: TRACKING });
  const capHeight = wm.capHeight;
  const wmW = wm.bbox.x2 - wm.bbox.x1;

  // Mark scaled to ~1.9× cap height tall (a presence above the word).
  const markH = box.maxY - box.minY;
  const targetMarkH = r2(capHeight * 1.9);
  const s = r2(targetMarkH / markH);
  const scaledMarkW = r2((box.maxX - box.minX) * s);

  const gap = r2(0.5 * capHeight);

  // Wordmark sits with baseline at y=0; cap-top at y = -capHeight.
  // Place mark above: mark base at (wordmark cap-top) - gap.
  const wmCapTop = wm.bbox.y1; // negative
  const markBaseY = r2(wmCapTop - gap);
  const markTopY = r2(markBaseY - targetMarkH);

  // Horizontal center: wordmark center x.
  const wmCx = r2(wm.bbox.x1 + wmW / 2);
  const markTx = r2(wmCx - scaledMarkW / 2 - box.minX * s);
  const markTy = r2(markTopY - box.minY * s);

  const markBB = {
    minX: r2(wmCx - scaledMarkW / 2),
    minY: markTopY,
    maxX: r2(wmCx + scaledMarkW / 2),
    maxY: markBaseY,
  };
  const wmBB = { minX: wm.bbox.x1, minY: wm.bbox.y1, maxX: wm.bbox.x2, maxY: wm.bbox.y2 };
  const vb = viewBoxOf([markBB, wmBB]);

  return [
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${vb}" role="img" aria-label="Scoria — LK-C stacked" data-variant="LK-C" data-gap-exempt="stack">`,
    `  <title>Scoria — LK-C stacked (vertical lockup)</title>`,
    `  <g transform="translate(${markTx},${markTy}) scale(${s})">`,
    `    <path fill="${TV_1.fill}" fill-rule="evenodd" d="${markD}"/>`,
    `  </g>`,
    `  <path fill="${TV_1.fill}" fill-rule="evenodd" d="${wm.d}"/>`,
    `</svg>`,
  ].join('\n');
}

// ── LK-D: Overlap ───────────────────────────────────────────────────────────
/**
 * Mark partially overlapping/notching INTO the leading 'S'. The mark is scaled
 * to cap height and positioned so its right edge tucks a small amount (≈0.18×
 * mark width) BEHIND the 'S' — boundary-breaking energy, but the overlap is
 * small so the 'S' stays fully legible. The 'S' is drawn AFTER (on top of) the
 * mark so the letter wins the overlap zone. Gap is intentionally negative
 * (overlap), so this variant documents an exemption from LOGO-03's positive-gap
 * rule (the relationship IS the overlap).
 */
async function overlap() {
  const { d: markD, box } = tv1Mark();
  const wm = await wordmarkPath('Scoria', { fontSize: FONT_SIZE, tracking: TRACKING });
  const capHeight = wm.capHeight;
  const markH = box.maxY - box.minY;
  const s = r2(capHeight / markH);
  const scaledMarkW = r2((box.maxX - box.minX) * s);

  // Overlap: mark's right edge sits 0.12×markW into the wordmark left edge — a
  // controlled notch (the wordmark draws on top, so the 'S' occludes the mark in
  // the overlap zone and stays fully legible).
  const overlapAmt = r2(0.12 * scaledMarkW);
  const wmLeft = wm.bbox.x1;

  // mark right edge target = wmLeft + overlapAmt → mark scaled-left = that - scaledMarkW
  const markScaledLeft = r2(wmLeft + overlapAmt - scaledMarkW);
  // Vertically center mark on the cap band: cap band y wm.bbox.y1..0.
  const capMid = r2((wm.bbox.y1) / 2);
  const markTyCentered = r2(capMid - ((box.minY + box.maxY) / 2) * s);

  const markBB = scaleShiftBBox(box, s, r2(-box.minX * s + markScaledLeft), markTyCentered);
  const wmBB = { minX: wm.bbox.x1, minY: wm.bbox.y1, maxX: wm.bbox.x2, maxY: wm.bbox.y2 };
  const vb = viewBoxOf([markBB, wmBB]);

  return [
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${vb}" role="img" aria-label="Scoria — LK-D overlap" data-variant="LK-D" data-gap-exempt="overlap">`,
    `  <title>Scoria — LK-D overlap (mark notches the S)</title>`,
    `  <g transform="translate(${r2(-box.minX * s + markScaledLeft)},${markTyCentered}) scale(${s})">`,
    `    <path fill="${TV_1.fill}" fill-rule="evenodd" d="${markD}"/>`,
    `  </g>`,
    `  <path fill="${TV_1.fill}" fill-rule="evenodd" d="${wm.d}"/>`,
    `</svg>`,
  ].join('\n');
}

// ── LK-E: Counter-punch ─────────────────────────────────────────────────────
/**
 * The wordmark, where the TV-1 trace-tree holes are punched THROUGH the capital
 * 'S' itself — the cap carries the motif, the rest of the word stays clean. The
 * three strongest trace nodes are placed on the 'S' SPINE (top bowl, waist,
 * bottom bowl), NOT its bbox, so each hole lands on ink rather than in the open
 * counters. Hole DIAMETER is clamped to the 'S' stem width (12.8): each
 * diameter in [stem*0.55, stem*0.8] = [7.04, 10.24], i.e. radius [3.52, 5.12],
 * so the holes read at small sizes WITHOUT collapsing the 12.8u stroke. Hole
 * size descends top→bottom, preserving TV-1's root→leaf hierarchy. evenodd
 * punching appends the holes to the 'S' contour. NO ring 'o', NO bowl specks —
 * the rejected motifs are gone; the trace tree lives in the one capital instead.
 */
async function counterPunch() {
  const { glyphs } = await scoriaGlyphs();
  const font = await loadFont();

  const S = glyphs.find((g) => g.ch === 'S');
  const sb = S.bbox; // x1 3.90 y1 -71.00 x2 56.10 y2 1.20
  const sW = sb.x2 - sb.x1;
  const sH = sb.y2 - sb.y1;
  const stem = 12.8; // measured 'i' stem at fontSize 100

  // Diameter clamp per craft rule: diameter in [stem*0.55, stem*0.8].
  const dMin = stem * 0.55, dMax = stem * 0.8; // 7.04 .. 10.24

  // Three nodes ON the S spine, at ink-x-centers found by scanning the flattened
  // 'S' contour (diagnostic _probe): the holes trace the S's own diagonal flow —
  // upper-left bowl stroke → center waist → lower-right bowl stroke — which is
  // exactly TV-1's root→leaf down-right diagonal, now carried by the letter.
  // Coordinates are absolute glyph-space (the 'S' sits at advX 0). Sizes descend
  // top→bottom; diameters clamped to [dMin, dMax].
  void sW; void sH;
  const spine = [
    { cx: 13.4, cy: -55.1, d: dMax },              // root (upper-left bowl stroke)
    { cx: 32.1, cy: -34.9, d: (dMin + dMax) / 2 }, // waist (center diagonal)
    { cx: 48.1, cy: -14.7, d: dMin },              // leaf (lower-right bowl stroke)
  ];
  // 'S' is the first glyph (advX 0) so spine coords are already absolute.
  const holes = spine.map((p) => ({ cx: r2(p.cx), cy: r2(p.cy), r: r2(p.d / 2) }));

  // 'S' contour + punched holes (evenodd). Rest of the word: plain glyphs.
  const sPathD = pathToD(font.charToGlyph('S').getPath(S.advX, 0, FONT_SIZE));
  const holesD = vesicleHolesLocal(holes);
  const sPunched = sPathD + holesD;

  let dRest = '';
  for (const g of glyphs) {
    if (g.ch === 'S') continue;
    dRest += pathToD(font.charToGlyph(g.ch).getPath(g.advX, 0, FONT_SIZE));
  }

  const wmBB = {
    minX: glyphs[0].bbox.x1,
    minY: Math.min(...glyphs.map((g) => g.bbox.y1)),
    maxX: glyphs[glyphs.length - 1].bbox.x2,
    maxY: Math.max(...glyphs.map((g) => g.bbox.y2)),
  };
  const vb = viewBoxOf([wmBB]);

  return [
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${vb}" role="img" aria-label="Scoria — LK-E counter-punch" data-variant="LK-E" data-integrated="true">`,
    `  <title>Scoria — LK-E counter-punch (trace tree through the S)</title>`,
    `  <path fill="${TV_1.fill}" fill-rule="evenodd" d="${sPunched}"/>`,
    `  <path fill="${TV_1.fill}" fill-rule="evenodd" d="${dRest}"/>`,
    `</svg>`,
  ].join('\n');
}

// ── LK-F: Mark-as-tittle (the invented sixth) ───────────────────────────────
/**
 * Replaces the round tittle (dot) of the 'i' with a TINY TV-1 mark — a
 * micro-integration that keeps the wordmark 100% legible while planting the
 * motif as a single deliberate jewel. Unlike the rejected ring-'o' (which
 * deformed a letter into a typo), this ADDS the mark where a dot already lives,
 * so nothing reads as broken. The mark is scaled to the tittle's width and sits
 * at the tittle's center; the original dot is removed and the mark group takes
 * its place. Chosen over a sixth boundary study because it answers the critique
 * directly: an integration that reads as INTENT, not noise.
 */
async function markAsDot() {
  const { d: markD, box } = tv1Mark();
  const { glyphs } = await scoriaGlyphs();
  const font = await loadFont();

  const I = glyphs.find((g) => g.ch === 'i');
  // 'i' = two contours: tittle (top, h≈14.8) + stem (h≈52.2). The tittle is the
  // upper contour. Compute its bbox by splitting the 'i' path into contours.
  const iPath = font.charToGlyph('i').getPath(I.advX, 0, FONT_SIZE);
  const contours = splitContours(iPath);
  // Tittle = the contour with the higher (more negative) top and small height.
  const tittle = contours.reduce((a, b) =>
    (b.maxY - b.minY) < (a.maxY - a.minY) ? b : a
  );
  const tW = tittle.maxX - tittle.minX;
  const tCx = (tittle.minX + tittle.maxX) / 2;
  const tCy = (tittle.minY + tittle.maxY) / 2;

  // Scale mark so its width ≈ 1.45× the tittle width (a touch larger so the
  // detail reads), centered on the tittle.
  const markW = box.maxX - box.minX;
  const s = r2((tW * 1.45) / markW);
  const mcx = (box.minX + box.maxX) / 2;
  const mcy = (box.minY + box.maxY) / 2;
  const tx = r2(tCx - mcx * s);
  const ty = r2(tCy - mcy * s);

  // Wordmark WITHOUT the tittle: draw the stem contour + every other glyph.
  let dRest = '';
  for (const g of glyphs) {
    if (g.ch === 'i') {
      // keep only the stem contour(s) — drop the tittle.
      const iContours = splitContours(font.charToGlyph('i').getPath(g.advX, 0, FONT_SIZE));
      for (const c of iContours) {
        if (c === iContours.reduce((a, b) => (b.maxY - b.minY) < (a.maxY - a.minY) ? b : a)) continue;
        dRest += c.d;
      }
      continue;
    }
    dRest += pathToD(font.charToGlyph(g.ch).getPath(g.advX, 0, FONT_SIZE));
  }

  const markBB = scaleShiftBBox(box, s, tx, ty);
  const wmBB = {
    minX: glyphs[0].bbox.x1,
    minY: Math.min(...glyphs.map((g) => g.bbox.y1)),
    maxX: glyphs[glyphs.length - 1].bbox.x2,
    maxY: Math.max(...glyphs.map((g) => g.bbox.y2)),
  };
  const vb = viewBoxOf([markBB, wmBB]);

  return [
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${vb}" role="img" aria-label="Scoria — LK-F mark-as-tittle" data-variant="LK-F" data-integrated="true">`,
    `  <title>Scoria — LK-F mark-as-tittle (mark replaces the i dot)</title>`,
    `  <path fill="${TV_1.fill}" fill-rule="evenodd" d="${dRest}"/>`,
    `  <g transform="translate(${tx},${ty}) scale(${s})">`,
    `    <path fill="${TV_1.fill}" fill-rule="evenodd" d="${markD}"/>`,
    `  </g>`,
    `</svg>`,
  ].join('\n');
}

// ── local helpers (kept here to avoid touching shared libs) ─────────────────

/** Stringify an opentype Path to a ≤2-decimal SVG d string. */
function pathToD(path) {
  const parts = [];
  for (const cmd of path.commands) {
    switch (cmd.type) {
      case 'M': parts.push(`M${r2(cmd.x)},${r2(cmd.y)}`); break;
      case 'L': parts.push(`L${r2(cmd.x)},${r2(cmd.y)}`); break;
      case 'C': parts.push(`C${r2(cmd.x1)},${r2(cmd.y1)},${r2(cmd.x2)},${r2(cmd.y2)},${r2(cmd.x)},${r2(cmd.y)}`); break;
      case 'Q': parts.push(`Q${r2(cmd.x1)},${r2(cmd.y1)},${r2(cmd.x)},${r2(cmd.y)}`); break;
      case 'Z': parts.push('Z'); break;
    }
  }
  return parts.join('');
}

/** Split an opentype Path into per-contour {d, minX,minY,maxX,maxY}. */
function splitContours(path) {
  const contours = [];
  let cur = null;
  const flush = () => { if (cur) contours.push(cur); };
  for (const cmd of path.commands) {
    if (cmd.type === 'M') {
      flush();
      cur = { d: '', minX: Infinity, minY: Infinity, maxX: -Infinity, maxY: -Infinity };
    }
    if (!cur) continue;
    // accumulate d
    switch (cmd.type) {
      case 'M': cur.d += `M${r2(cmd.x)},${r2(cmd.y)}`; break;
      case 'L': cur.d += `L${r2(cmd.x)},${r2(cmd.y)}`; break;
      case 'C': cur.d += `C${r2(cmd.x1)},${r2(cmd.y1)},${r2(cmd.x2)},${r2(cmd.y2)},${r2(cmd.x)},${r2(cmd.y)}`; break;
      case 'Q': cur.d += `Q${r2(cmd.x1)},${r2(cmd.y1)},${r2(cmd.x)},${r2(cmd.y)}`; break;
      case 'Z': cur.d += 'Z'; break;
    }
    for (const k of [['x', 'y'], ['x1', 'y1'], ['x2', 'y2']]) {
      if (cmd[k[0]] !== undefined) {
        cur.minX = Math.min(cur.minX, cmd[k[0]]); cur.maxX = Math.max(cur.maxX, cmd[k[0]]);
        cur.minY = Math.min(cur.minY, cmd[k[1]]); cur.maxY = Math.max(cur.maxY, cmd[k[1]]);
      }
    }
  }
  flush();
  return contours;
}

/** Local circle-as-4-bezier hole subpaths (≤2 decimals). */
function vesicleHolesLocal(holes) {
  return holes.map(({ cx, cy, r }) => {
    const k = r2(r * 0.5523);
    const rx = r2(cx), ry = r2(cy), rr = r2(r);
    return [
      `M${r2(rx + rr)},${ry}`,
      `C${r2(rx + rr)},${r2(ry - k)},${r2(rx + k)},${r2(ry - rr)},${rx},${r2(ry - rr)}`,
      `C${r2(rx - k)},${r2(ry - rr)},${r2(rx - rr)},${r2(ry - k)},${r2(rx - rr)},${ry}`,
      `C${r2(rx - rr)},${r2(ry + k)},${r2(rx - k)},${r2(ry + rr)},${rx},${r2(ry + rr)}`,
      `C${r2(rx + k)},${r2(ry + rr)},${r2(rx + rr)},${r2(ry + k)},${r2(rx + rr)},${ry}`,
      'Z',
    ].join('');
  }).join('');
}

export { classicTight, markAsO, stacked, overlap, counterPunch, markAsDot };
