#!/usr/bin/env node
/**
 * generate.mjs — Candidate SVG orchestrator (Phase 19-02)
 *
 * Imports the hand-authored presets (presets.mjs) and the 19-01 libraries, then
 * renders every candidate SVG into brandbook/tools/candidates/:
 *
 *   For each mark preset (TV-1, TV-2, TV-3, CM-1, CM-2, AP-1):
 *     <id>-mark.svg     single evenodd path, brand-hex fill   (LOGO-01/02)
 *     <id>-mono.svg     single evenodd path, currentColor fill (LOGO-07)
 *     <id>-lockup.svg   mark + "Scoria" wordmark, no subtitle  (LOGO-03/04)
 *   For each Trace Vesicle preset additionally:
 *     <id>-fav.svg      16px-simplified 3-hole favicon mark    (LOGO-06)
 *   For each typemark preset (TYPE-1, TYPE-2):
 *     <id>.svg          integrated-typemark full wordmark      (LOGO-05)
 *
 * Every emitted SVG uses a brand hex or currentColor — NO hardcoded background
 * (grounds belong to the gallery page). Coordinates are rounded to ≤2 decimals
 * inside the libraries. Nothing is written under brandbook/ root.
 *
 * Exits 0 and prints a count of files written.
 */

import { mkdirSync, writeFileSync, rmSync, existsSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

import { markPath, pathBBox, vesicleHoles } from './lib/geometry.mjs';
import { svgDocument } from './lib/svg.mjs';
import { wordmarkPath, integratedTypemark } from './lib/wordmark.mjs';
import { composeLockup } from './lib/lockup.mjs';
import { markPresets, typemarkPresets } from './presets.mjs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const CANDIDATES_DIR = join(__dirname, 'candidates');

/** Build the preset object the geometry library consumes from a mark preset. */
function geometryInput(preset, holesOverride) {
  return {
    anchors: preset.anchors,
    baseRadius: preset.baseRadius,
    radiusVariance: preset.radiusVariance,
    flatFacets: preset.flatFacets,
    rounding: preset.rounding,
    seed: preset.seed,
    edgeNotch: preset.edgeNotch,
    holes: holesOverride ?? preset.holes,
  };
}

/** Render the four-or-five SVGs for a single mark preset. Returns [filename, svg][]. */
function renderMark(preset) {
  const out = [];

  // Full mark — single evenodd compound path, brand-hex fill.
  const markD = markPath(geometryInput(preset));
  out.push([
    `${preset.id}-mark.svg`,
    svgDocument({
      pathD: markD,
      fill: preset.fill,
      title: `Scoria mark — ${preset.id} ${preset.name}`,
    }),
  ]);

  // Monochrome mark — same geometry, currentColor (LOGO-07 evidence).
  out.push([
    `${preset.id}-mono.svg`,
    svgDocument({
      pathD: markD,
      fill: 'currentColor',
      title: `Scoria mark monochrome — ${preset.id}`,
    }),
  ]);

  // 16px favicon simplification — Trace Vesicle presets only (LOGO-06).
  if (preset.holes16 && preset.holes16.length > 0) {
    const favD = markPath(geometryInput(preset, preset.holes16));
    out.push([
      `${preset.id}-fav.svg`,
      svgDocument({
        pathD: favD,
        fill: preset.fill,
        title: `Scoria favicon 16px — ${preset.id}`,
      }),
    ]);
  }

  return { out, markD };
}

/** Render the no-subtitle combination lockup for a mark preset (LOGO-03/04). */
async function renderLockup(preset, markD) {
  const markBox = pathBBox(markD);
  const wm = await wordmarkPath('Scoria', { fontSize: 100, tracking: -0.005 });
  const svg = composeLockup({
    markD,
    markBox,
    wordmarkD: wm.d,
    wordmarkBbox: wm.bbox,
    capHeight: wm.capHeight,
    fill: preset.fill,
    markFill: preset.fill,
    title: `Scoria — ${preset.id} lockup`,
  });
  return [`${preset.id}-lockup.svg`, svg];
}

/**
 * Punch 1–2 tiny vesicles into the 'a' bowl for TYPE-2 (extraPunches).
 * The 'a' bowl center sits near x≈262, y≈-15 at fontSize 100 (baseline y=0).
 * Punches are small (r≈3) so they read as texture, not a second focal point.
 * Appending evenodd hole sub-paths to the compound typemark path punches them.
 */
function aBowlPunches(d) {
  const punches = vesicleHoles([
    { cx: 259, cy: -11, r: 3.2 },
    { cx: 268, cy: -20, r: 2.4 },
  ]);
  return d + punches;
}

/** Render a full-width integrated typemark SVG (LOGO-05). */
async function renderTypemark(preset) {
  const it = await integratedTypemark(preset.text, {
    fontSize: preset.fontSize,
    tracking: preset.tracking,
    oReplacement: preset.oReplacement,
  });
  const d = preset.extraPunches ? aBowlPunches(it.d) : it.d;
  const svg = svgDocument({
    pathD: d,
    fill: preset.fill,
    title: `Scoria integrated typemark — ${preset.id} ${preset.name}`,
  });
  return [`${preset.id}.svg`, svg];
}

async function main() {
  // Fresh candidates dir each run (reproducible; losers pruned in Phase 20).
  if (existsSync(CANDIDATES_DIR)) {
    rmSync(CANDIDATES_DIR, { recursive: true, force: true });
  }
  mkdirSync(CANDIDATES_DIR, { recursive: true });

  const files = [];

  for (const preset of markPresets) {
    const { out, markD } = renderMark(preset);
    for (const f of out) files.push(f);
    files.push(await renderLockup(preset, markD));
  }

  for (const preset of typemarkPresets) {
    files.push(await renderTypemark(preset));
  }

  for (const [name, svg] of files) {
    writeFileSync(join(CANDIDATES_DIR, name), svg + '\n', 'utf8');
  }

  console.log(`generate.mjs: wrote ${files.length} candidate SVG(s) to candidates/`);
}

main().catch((err) => {
  console.error('generate.mjs failed:', err);
  process.exit(1);
});
