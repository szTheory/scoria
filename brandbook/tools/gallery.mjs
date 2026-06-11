#!/usr/bin/env node
/**
 * gallery.mjs — Build the standalone gate-#2 options gallery (Phase 19-02)
 *
 * Reads every candidate SVG from candidates/ and emits a single self-contained
 * brandbook/tools/options-gallery.html:
 *   - NO network references (inline SVG, no <img>, no external fonts/CSS/JS)
 *   - two ground sections: Basalt-950 #11100F (dark) + Ash-50 #FAF5EF (light)
 *   - per mark option: stable ID + design-intent caption, lockup + mark at
 *     256/64/32/16px, a monochrome row, a browser-tab favicon strip, a 24px
 *     dashboard-sidebar mock, and a README header band mock
 *   - integrated typemark studies at full width + small sizes
 *   - a ranked recommendation block at the top (Trace Vesicle #1, Cinder #2,
 *     Aperture #3 study, per §8) and a "none of these → second round" escape note
 *   - IBM Plex Sans system-fallback stack (no webfont loads)
 *
 * Run after generate.mjs. Exits 0.
 */

import { readFileSync, writeFileSync, readdirSync, existsSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

import { markPresets, typemarkPresets } from './presets.mjs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const CANDIDATES_DIR = join(__dirname, 'candidates');
const OUT = join(__dirname, 'options-gallery.html');

// Brand palette (CONTEXT §decisions).
const C = {
  basalt950: '#11100F', // dark ground
  char850: '#1C1A18',
  ash50: '#FAF5EF', // light ground
  ash100: '#EFE7DC',
  ember500: '#E65A32',
  molten400: '#FF7A4D',
  scoria600: '#B94F31',
  pumice500: '#8A8178',
  textDark: '#FAF5EF', // text on dark ground
  textLight: '#1C1A18', // text on light ground
};

if (!existsSync(CANDIDATES_DIR)) {
  console.error('gallery.mjs: candidates/ not found — run generate.mjs first.');
  process.exit(1);
}

/** Read a candidate SVG by filename (without the wrapping newline). */
function svg(name) {
  const p = join(CANDIDATES_DIR, name);
  if (!existsSync(p)) return null;
  return readFileSync(p, 'utf8').trim();
}

/**
 * Inline an SVG at a fixed pixel size with a given color via `color:` (so
 * currentColor-filled monochrome SVGs inherit it). Brand-hex SVGs ignore color.
 */
function svgAt(name, px, color) {
  const raw = svg(name);
  if (!raw) return `<span class="missing">[${name} missing]</span>`;
  // Force width/height on the root <svg> for crisp fixed-size rendering.
  const sized = raw.replace(
    /<svg /,
    `<svg width="${px}" height="${px}" style="color:${color ?? 'inherit'}" `
  );
  return sized;
}

/** Pull the one-line design-intent summary (first sentence) for a preset. */
function intentLine(preset) {
  // Hand-curated captions so the user reads the *distinction*, not the params.
  const map = {
    'TV-1': 'Span rail — the quiet, disciplined Trace Vesicle. Tight vertical span tree, fully closed silhouette. The favicon-safest of the three.',
    'TV-2': 'Open branch — dynamic and asymmetric. The trace tree forks into two leaves and one vesicle bleeds through the right edge as a notch.',
    'TV-3': 'Cross rail — a horizontal reading of the trace tree. Root left, children marching right; chiselled, almost arrow-like chunk.',
    'CM-1': 'Field sample — the classic cinder chunk. Five scattered holes, one dominant core, a flat facet at the base so it sits. No diagram logic — pure porous rock.',
    'CM-2': 'Tumbled — the softer cinder sibling. Rounder, seven smaller even holes (higher porosity), flat facet upper-left. A weathered, rolled stone.',
    'AP-1': 'Aperture study (STUDY ONLY) — central cavity + four radial satellites. Included so you can see and reject the aperture/eye risk with evidence.',
    'TYPE-1': "Ring o — the clean integrated typemark. Only the 'o' becomes a vesicle ring (weight ≈ the 'S' stem, advance + x-height preserved).",
    'TYPE-2': "Porous a — same ring 'o' plus 1-2 tiny vesicles punched into the 'a' bowl. Subtle porosity ties the whole word to the cinder motif.",
  };
  return map[preset.id] ?? preset.name;
}

const DIRECTION_LABEL = {
  'trace-vesicle': 'Trace Vesicle (#1 — primary)',
  cinder: 'Cinder (#2 — strong fallback)',
  aperture: 'Aperture (#3 — study only)',
};

/** A size-ramp row: lockup + mark at 256/64/32/16, plus the favicon variant. */
function sizeRamp(preset, color) {
  const hasFav = preset.holes16 && preset.holes16.length > 0;
  return `
    <div class="ramp">
      <figure><div class="art lockup">${svgAt(`${preset.id}-lockup.svg`, 256, color).replace(/width="256" height="256"/, 'height="64"')}</div><figcaption>lockup</figcaption></figure>
      <figure><div class="art">${svgAt(`${preset.id}-mark.svg`, 256, color)}</div><figcaption>256px</figcaption></figure>
      <figure><div class="art">${svgAt(`${preset.id}-mark.svg`, 64, color)}</div><figcaption>64px</figcaption></figure>
      <figure><div class="art">${svgAt(`${preset.id}-mark.svg`, 32, color)}</div><figcaption>32px</figcaption></figure>
      <figure><div class="art">${svgAt(`${hasFav ? preset.id + '-fav' : preset.id + '-mark'}.svg`, 16, color)}</div><figcaption>16px${hasFav ? ' (simplified)' : ''}</figcaption></figure>
    </div>`;
}

/** Monochrome row — currentColor SVG inheriting a flipped text color. */
function monoRow(preset, color) {
  return `
    <div class="mono-row">
      <span class="mono-label">monochrome</span>
      ${svgAt(`${preset.id}-mono.svg`, 48, color)}
      ${svgAt(`${preset.id}-mono.svg`, 24, color)}
      ${svgAt(`${preset.id}-mono.svg`, 16, color)}
    </div>`;
}

/** Simulated browser-tab favicon strip. */
function faviconStrip(preset, color) {
  const fav = preset.holes16 ? `${preset.id}-fav.svg` : `${preset.id}-mark.svg`;
  return `
    <div class="tabstrip">
      <div class="tab active">${svgAt(fav, 16, color)}<span>Scoria · Traces</span></div>
      <div class="tab">${svgAt(fav, 16, color)}<span>Evals</span></div>
      <div class="tab">${svgAt(fav, 16, color)}<span>Prompts</span></div>
    </div>`;
}

/** 24px dashboard-sidebar mock row. */
function sidebarMock(preset, color) {
  const mark = preset.holes16 ? `${preset.id}-fav.svg` : `${preset.id}-mark.svg`;
  return `
    <div class="sidebar-mock">
      <div class="sb-rail">
        <div class="sb-logo">${svgAt(mark, 24, color)}</div>
        <div class="sb-dot"></div><div class="sb-dot"></div><div class="sb-dot"></div>
      </div>
      <span class="mock-label">24px sidebar</span>
    </div>`;
}

/** README header band mock (lockup on a band). */
function readmeBand(preset, color, ground) {
  return `
    <div class="readme-band" style="background:${ground}">
      <div class="rb-lockup">${svgAt(`${preset.id}-lockup.svg`, 256, color).replace(/width="256" height="256"/, 'height="40"')}</div>
      <span class="rb-badges">
        <span class="badge">hex.pm v2.17</span><span class="badge">CI passing</span><span class="badge">Apache-2.0</span>
      </span>
    </div>`;
}

/** A full option card on a given ground. */
function optionCard(preset, ground, color, groundName) {
  return `
  <article class="card" id="${preset.id}-${groundName}">
    <header class="card-head">
      <h3><span class="oid">${preset.id}</span> ${preset.name}</h3>
      <span class="dir">${DIRECTION_LABEL[preset.direction] ?? preset.direction}</span>
    </header>
    <p class="intent">${intentLine(preset)}</p>
    ${sizeRamp(preset, color)}
    ${monoRow(preset, color)}
    ${faviconStrip(preset, color)}
    ${sidebarMock(preset, color)}
    ${readmeBand(preset, color, ground === C.basalt950 ? C.char850 : C.ash100)}
  </article>`;
}

/** A typemark card (full width + small). */
function typemarkCard(preset, color) {
  return `
  <article class="card type-card" id="${preset.id}">
    <header class="card-head">
      <h3><span class="oid">${preset.id}</span> ${preset.name}</h3>
      <span class="dir">Integrated typemark (LOGO-05)</span>
    </header>
    <p class="intent">${intentLine(preset)}</p>
    <div class="type-ramp">
      <div class="art type-full">${svgAt(`${preset.id}.svg`, 256, color).replace(/width="256" height="256"/, 'height="72"')}</div>
      <div class="art type-mid">${svgAt(`${preset.id}.svg`, 256, color).replace(/width="256" height="256"/, 'height="36"')}</div>
      <div class="art type-small">${svgAt(`${preset.id}.svg`, 256, color).replace(/width="256" height="256"/, 'height="20"')}</div>
    </div>
  </article>`;
}

function recommendationBlock() {
  return `
  <section class="recommend">
    <h2>Ranked recommendation</h2>
    <ol class="rank">
      <li><strong>#1 Trace Vesicle (TV-1 / TV-2 / TV-3)</strong> — PRIMARY. The holes trace a
        readable node hierarchy (root → child → leaf), so the mark has internal logic that
        survives monochrome and simplifies cleanly to exactly 3 holes at 16px. Genuinely
        distinct from devtools competitors (abstract nodes / colorful blobs) and orthogonal to
        Threadline's line motif. Of the three, <strong>TV-1 "Span rail"</strong> is the
        favicon-safest; <strong>TV-2 "Open branch"</strong> is the most distinctive (the
        edge-notch breaks the closed-blob feel); TV-3 offers a horizontal reading.</li>
      <li><strong>#2 Cinder (CM-1 / CM-2)</strong> — strong fallback. Simpler geometry = excellent
        favicon survival, but no internal logic — it reads as porous rock, not a trace. Pick this
        if the Trace Vesicle feels too busy at small sizes.</li>
      <li><strong>#3 Aperture (AP-1)</strong> — STUDY ONLY. Shown so the camera/eye risk is
        visible and rejectable with evidence; not recommended as the primary.</li>
      <li><strong>Integrated typemarks (TYPE-1 / TYPE-2)</strong> — first-class variants, not
        fallbacks. Wanted alongside the chosen mark for narrow contexts.</li>
    </ol>
    <p class="my-pick"><strong>My pick: TV-1 "Span rail."</strong> It is the only option that
      passes every hard test cleanly — its 16px favicon keeps 3 well-separated holes (each
      ≥1.5px rendered, verified by geometry), it reads as a deliberate trace hierarchy in
      monochrome, and its tight ~1:1 silhouette never starves the sidebar/favicon slots. TV-2 is
      the close runner-up if you want more energy from the edge-notch.</p>
    <p class="escape"><strong>None of these?</strong> That is a valid answer. Choosing
      "none — second round" sends the direction back for another iteration with your notes,
      rather than forcing a compromise pick.</p>
  </section>`;
}

function groundSection(groundName, ground, color) {
  const marks = markPresets
    .map((p) => optionCard(p, ground, color, groundName))
    .join('\n');
  const types = typemarkPresets.map((p) => typemarkCard(p, color)).join('\n');
  return `
  <section class="ground ${groundName}" style="background:${ground};color:${color}">
    <h2 class="ground-title">${groundName === 'dark' ? 'On dark ground — Basalt-950 ' + C.basalt950 : 'On light ground — Ash-50 ' + C.ash50}</h2>
    <div class="cards">
      ${marks}
    </div>
    <h2 class="ground-title">Integrated typemark studies</h2>
    <div class="cards">
      ${types}
    </div>
  </section>`;
}

function buildHtml() {
  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Scoria logo options — gate #2 gallery</title>
<style>
  :root { font-family: "IBM Plex Sans", system-ui, -apple-system, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; }
  * { box-sizing: border-box; }
  body { margin: 0; background: ${C.basalt950}; color: ${C.textDark}; line-height: 1.45; }
  h1, h2, h3 { font-weight: 600; letter-spacing: -0.01em; margin: 0 0 .4em; }
  .page-head { padding: 32px 40px 8px; background: ${C.char850}; color: ${C.textDark}; }
  .page-head h1 { font-size: 28px; }
  .page-head p { color: ${C.pumice500}; max-width: 70ch; margin: .3em 0; }
  .recommend { padding: 24px 40px 32px; background: ${C.char850}; color: ${C.textDark}; }
  .recommend h2 { font-size: 20px; }
  .rank { margin: 0 0 1em; padding-left: 1.2em; max-width: 90ch; }
  .rank li { margin: .5em 0; }
  .my-pick { background: rgba(230,90,50,.14); border-left: 3px solid ${C.ember500}; padding: 12px 16px; max-width: 90ch; }
  .escape { background: rgba(138,129,120,.14); border-left: 3px solid ${C.pumice500}; padding: 12px 16px; max-width: 90ch; }
  .ground { padding: 28px 40px 48px; }
  .ground-title { font-size: 18px; opacity: .8; margin-top: 1.4em; }
  .cards { display: grid; grid-template-columns: repeat(auto-fill, minmax(420px, 1fr)); gap: 24px; }
  .card { border: 1px solid currentColor; border-radius: 10px; padding: 18px; background: rgba(127,127,127,.04); }
  .card-head { display: flex; align-items: baseline; justify-content: space-between; gap: 12px; }
  .card-head h3 { font-size: 17px; }
  .oid { font-family: ui-monospace, "JetBrains Mono", Menlo, monospace; font-size: 13px; padding: 2px 6px; border: 1px solid currentColor; border-radius: 5px; margin-right: 6px; opacity: .9; }
  .dir { font-size: 12px; opacity: .7; white-space: nowrap; }
  .intent { font-size: 13.5px; opacity: .92; margin: .5em 0 1em; }
  .ramp { display: flex; align-items: flex-end; gap: 18px; flex-wrap: wrap; margin-bottom: 14px; }
  .ramp figure { margin: 0; text-align: center; }
  .ramp .art { display: flex; align-items: center; justify-content: center; min-height: 64px; }
  .ramp figcaption { font-size: 11px; opacity: .6; margin-top: 4px; font-family: ui-monospace, monospace; }
  .mono-row { display: flex; align-items: center; gap: 14px; padding: 10px 0; border-top: 1px dashed currentColor; opacity: .95; }
  .mono-label, .mock-label { font-size: 11px; opacity: .6; font-family: ui-monospace, monospace; min-width: 84px; }
  .tabstrip { display: flex; gap: 4px; margin: 10px 0; }
  .tab { display: flex; align-items: center; gap: 6px; font-size: 12px; padding: 5px 10px; border-radius: 7px 7px 0 0; background: rgba(127,127,127,.16); opacity: .7; }
  .tab.active { opacity: 1; background: rgba(127,127,127,.28); }
  .tab span { white-space: nowrap; }
  .sidebar-mock { display: flex; align-items: center; gap: 14px; margin: 10px 0; }
  .sb-rail { display: flex; flex-direction: column; align-items: center; gap: 10px; width: 44px; padding: 10px 0; border-radius: 10px; background: rgba(127,127,127,.16); }
  .sb-dot { width: 18px; height: 18px; border-radius: 5px; background: currentColor; opacity: .22; }
  .readme-band { display: flex; align-items: center; justify-content: space-between; gap: 16px; padding: 14px 18px; border-radius: 8px; margin-top: 10px; }
  .rb-badges { display: flex; gap: 6px; flex-wrap: wrap; }
  .badge { font-size: 11px; font-family: ui-monospace, monospace; padding: 3px 7px; border: 1px solid currentColor; border-radius: 4px; opacity: .7; }
  .type-card { grid-column: 1 / -1; }
  .type-ramp { display: flex; align-items: flex-end; gap: 32px; flex-wrap: wrap; }
  .missing { color: #c0392b; font-family: monospace; font-size: 12px; }
  svg { display: inline-block; vertical-align: middle; }
</style>
</head>
<body>
  <header class="page-head">
    <h1>Scoria logo options — gate&nbsp;#2</h1>
    <p>Six hand-tuned marks (each with a combination lockup) across three directions, plus two
      integrated typemark studies. Every option is shown on both grounds at 256 / 64 / 32 / 16&nbsp;px,
      in monochrome, as a browser-tab favicon, a 24&nbsp;px sidebar, and a README header band.
      Pick a direction — or send it back for a second round.</p>
    <p>Standalone file:// page · inline SVG · no network · IBM&nbsp;Plex&nbsp;Sans system-fallback.</p>
  </header>
  ${recommendationBlock()}
  ${groundSection('dark', C.basalt950, C.textDark)}
  ${groundSection('light', C.ash50, C.textLight)}
</body>
</html>
`;
}

const html = buildHtml();
writeFileSync(OUT, html, 'utf8');
const lines = html.split('\n').length;
console.log(`gallery.mjs: wrote options-gallery.html (${lines} lines)`);
