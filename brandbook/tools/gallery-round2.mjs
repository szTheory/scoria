#!/usr/bin/env node
/**
 * gallery-round2.mjs — Standalone gate-#2b gallery (Phase 19-02b)
 *
 * Second round after gate #2 escape (#2): TV-1 "Span rail" is the LOCKED
 * direction; this round diverges the MARK↔WORDMARK RELATIONSHIP and replaces
 * the rejected integrated typemarks (TYPE-1 ring 'o', TYPE-2 porous 'a').
 *
 * Emits a single self-contained options-gallery-round2.html:
 *   - NO network references (inline SVG only)
 *   - a "why the round-1 typemarks were rejected" diagnosis block
 *   - both grounds (Basalt-950 dark + Ash-50 light)
 *   - per option (LK-A..LK-F): design-intent caption, full + small sizes,
 *     monochrome row, favicon/sidebar context where relevant
 *   - a ranked recommendation block + a "none → third round" escape note
 *
 * Run after generate-round2.mjs. Exits 0.
 */

import { readFileSync, writeFileSync, existsSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __dir = dirname(fileURLToPath(import.meta.url));
const CANDIDATES = join(__dir, 'candidates');
const OUT = join(__dir, 'options-gallery-round2.html');

const C = {
  basalt950: '#11100F',
  char850: '#1C1A18',
  ash50: '#FAF5EF',
  ash100: '#EFE7DC',
  ember500: '#E65A32',
  molten400: '#FF7A4D',
  scoria600: '#B94F31',
  pumice500: '#8A8178',
  textDark: '#FAF5EF',
  textLight: '#1C1A18',
};

function raw(name) {
  const p = join(CANDIDATES, name);
  return existsSync(p) ? readFileSync(p, 'utf8').trim() : null;
}

/** Inline an SVG at a fixed HEIGHT (lockups are wide), color via `color:`. */
function svgH(name, h, color) {
  const s = raw(name);
  if (!s) return `<span class="missing">[${name} missing]</span>`;
  // Strip the brand-hex fill to currentColor when a mono color is requested.
  let out = s;
  if (color === 'mono') {
    out = out.replace(/fill="#[0-9A-Fa-f]{6}"/g, 'fill="currentColor"');
  }
  return out.replace(/<svg /, `<svg height="${h}" style="color:inherit" `);
}

const OPTIONS = [
  {
    id: 'LK-A',
    name: 'Classic tight',
    tag: 'baseline reference',
    file: 'LK-A-lockup.svg',
    intent:
      "The current mark-left lockup, kept UNCHANGED as the fixed point of comparison. " +
      "Mark scaled to cap height, optically-tight gap (0.4× cap height). Everything below " +
      "is measured against this baseline — it is here to compare, not to win.",
    answers: 'Baseline. The relationship the user already saw; shown so the new relationships have a reference.',
  },
  {
    id: 'LK-B',
    name: 'Mark-as-o',
    tag: 'fully integrated — recommended',
    file: 'LK-B-lockup.svg',
    intent:
      "The TV-1 mark IS the 'o' of Scoria. Scaled to the x-height band, it drops into the 'o' " +
      "advance slot — and the geometry is uncanny: at x-height the mark is 56.7u wide vs the 'o' " +
      "advance of 56.3u, a 0.4u difference, so kerning is undisturbed. The mark's vesicle holes " +
      "literally become the letter's counter. One object, mark and wordmark fused. The root hole is " +
      "micro-tuned (r 13→14.6) so the mark's ink density (0.61) sits near the surrounding letters' " +
      "(0.57) — it does NOT read bolder. This is the honest answer to 'fully integrated type treatment'.",
    answers:
      "Replaces the rejected ring-'o'. Instead of a fake geometric ring (which read as a degree symbol), " +
      "the REAL mark becomes the letter — the integration the ring was reaching for, done with the locked mark itself.",
    mono: true, favicon: false,
  },
  {
    id: 'LK-C',
    name: 'Stacked',
    tag: 'vertical lockup',
    file: 'LK-C-lockup.svg',
    intent:
      "Mark centered ABOVE the wordmark — the square/social/app-icon reading. Mark sized to ~1.9× " +
      "cap height (a confident cap), gap to the word = 0.5× cap height. This is the lockup the " +
      "horizontal forms can't give you: it fills a square avatar, a splash screen, an app tile.",
    answers:
      "A genuinely different mark↔word RELATIONSHIP (vertical, not side-by-side) — directly answering " +
      "'consider different variations on the lockup between image and text'.",
    mono: true,
  },
  {
    id: 'LK-D',
    name: 'Overlap',
    tag: 'boundary-breaking',
    file: 'LK-D-lockup.svg',
    intent:
      "The mark notches a controlled 0.12× of its width BEHIND the leading 'S'. The wordmark draws " +
      "on top, so the 'S' occludes the mark in the overlap zone and stays fully legible — but the " +
      "two elements now interlock instead of sitting politely apart. Honors the 'we like somewhat " +
      "breaking the boundaries' taste without sacrificing the word.",
    answers:
      "A RELATIONSHIP with tension: the mark and word overlap rather than abut. Different energy from " +
      "the tidy baseline, still legible.",
    mono: true,
  },
  {
    id: 'LK-E',
    name: 'Counter-punch',
    tag: 'motif in the capital',
    file: 'LK-E-lockup.svg',
    intent:
      "No separate mark at all — the TV-1 trace tree is punched THROUGH the capital 'S'. Three nodes " +
      "sit ON the S spine (verified fully on-ink), tracing the S's own diagonal flow upper-left → " +
      "waist → lower-right, which is exactly TV-1's root→leaf diagonal. Hole diameters are clamped to " +
      "[stem×0.55, stem×0.8] = [7.0, 10.2]u so they read at small sizes without collapsing the 12.8u " +
      "stroke. The rest of the word stays clean.",
    answers:
      "Replaces the rejected porous-'a'. Those tiny bowl specks read as dirt; here the motif is carried " +
      "deliberately by ONE capital, sized to be read as intent, not noise.",
    mono: true,
  },
  {
    id: 'LK-F',
    name: 'Mark-as-tittle',
    tag: 'micro-integration',
    file: 'LK-F-lockup.svg',
    intent:
      "The round dot (tittle) of the 'i' is replaced by a tiny TV-1 mark. The wordmark stays 100% " +
      "legible — nothing is deformed — but the motif is planted as a single deliberate jewel where a " +
      "dot already lived. Unlike the rejected ring-'o' (which broke a letter into a typo), this ADDS " +
      "the mark in the one spot the eye already expects an accent.",
    answers:
      "A third integration route: the mark appears INSIDE the word without distorting any letterform — " +
      "the lightest-touch answer to 'integrated', and the safest at small sizes.",
    mono: true,
  },
];

function rejectionBlock() {
  return `
  <section class="diagnosis">
    <h2>Why the round-1 integrated typemarks were rejected — diagnosed</h2>
    <p>You said TYPE-1 (ring&nbsp;'o') and TYPE-2 (porous&nbsp;'a') "look bad." Before redesigning, here is the
       numeric diagnosis of <em>why</em> — so the replacements fix the actual cause, not a guess:</p>
    <ul>
      <li><strong>TYPE-1 ring&nbsp;'o' read as a degree symbol / typo.</strong> The replacement was a
        <em>perfect circle</em> (radius = half the 'o' width = 24.25u). But IBM&nbsp;Plex's humanist 'o' is
        <em>taller than wide</em> — 54.6u tall × 48.5u wide. So the ring sat <strong>6.1u shorter</strong> than
        every neighbouring x-height letter: it under-filled the x-height band and floated, reading as an
        undersized geometric circle dropped into humanist type. A mechanical, evenly-weighted ring (12u all
        around) next to Plex's modulated strokes (thin sides, thicker top/bottom) compounds the "foreign object"
        effect.</li>
      <li><strong>TYPE-2 porous&nbsp;'a' read as rendering noise.</strong> The bowl punches were r&nbsp;3.2 and
        r&nbsp;2.4 dropped into an 18×14u bowl counter — specks too small to register as intent. At any real size
        they read as dirt or a compression artifact, not as the cinder motif.</li>
    </ul>
    <p class="fix">The fixes below attack the root cause: <strong>LK-B</strong> uses the REAL mark as the 'o'
       (no fake ring), sized to the actual glyph band and weight-matched; <strong>LK-E</strong> carries the motif
       in ONE capital at a size tuned to read; <strong>LK-F</strong> places the mark where an accent already lives,
       deforming nothing.</p>
  </section>`;
}

function recommendationBlock() {
  return `
  <section class="recommend">
    <h2>Recommended: LK-B — "Mark-as-o"</h2>
    <ol class="rank">
      <li><strong>#1 LK-B "Mark-as-o"</strong> — the strongest, and the most genuinely integrated. The mark
        becoming the 'o' is the rare case where the metaphor and the typography agree: the mark's holes are the
        letter's counter, and the width math is a near-perfect coincidence (56.7u vs 56.3u advance). It reads as
        one designed object, scales down legibly (the 'o' is mid-word so it never carries small-size load alone),
        and it's the honest version of what the rejected ring-'o' was attempting.</li>
      <li><strong>#2 LK-C "Stacked"</strong> — not a rival to LK-B but a COMPANION: you'll want a vertical lockup
        for avatars/app tiles regardless of which horizontal form wins. Recommend adopting it alongside the pick.</li>
      <li><strong>#3 LK-F "Mark-as-tittle"</strong> — the safe, charming micro-integration. If LK-B ever feels too
        bold for a dense UI, this keeps the motif with zero legibility risk.</li>
      <li><strong>LK-E "Counter-punch"</strong> — distinctive and on-concept, but the most contextual: the punched
        'S' wants size to read. Strong for a hero/wordmark-only treatment, less so at 16px.</li>
      <li><strong>LK-D "Overlap"</strong> — good energy, but the overlap is a styling choice that can fight tight
        layouts; keep as an alternate, not the primary.</li>
      <li><strong>LK-A "Classic tight"</strong> — the baseline. Still perfectly usable; it is here for comparison.</li>
    </ol>
    <p class="my-pick"><strong>My pick: LK-B "Mark-as-o" as the primary, with LK-C "Stacked" adopted as the
      square/social companion.</strong> Together they cover the horizontal and vertical contexts with one fused
      identity, and they directly answer both halves of your note — a different image↔text relationship, and an
      integration that actually looks designed.</p>
    <p class="escape"><strong>None of these?</strong> Still a valid answer. Choosing "none — third round" sends the
      lockup relationship back for another iteration with your notes; the TV-1 mark stays locked either way.</p>
  </section>`;
}

function optionCard(opt, color, groundName) {
  const monoRow = opt.mono
    ? `<div class="mono-row"><span class="lbl">monochrome</span>${svgH(opt.file, 28, 'mono')}${svgH(opt.file, 18, 'mono')}</div>`
    : '';
  return `
  <article class="card" id="${opt.id}-${groundName}">
    <header class="card-head">
      <h3><span class="oid">${opt.id}</span> ${opt.name}</h3>
      <span class="tag">${opt.tag}</span>
    </header>
    <p class="intent">${opt.intent}</p>
    <div class="ramp">
      <figure><div class="art">${svgH(opt.file, 64, color)}</div><figcaption>64px tall</figcaption></figure>
      <figure><div class="art">${svgH(opt.file, 36, color)}</div><figcaption>36px</figcaption></figure>
      <figure><div class="art">${svgH(opt.file, 22, color)}</div><figcaption>22px (small)</figcaption></figure>
    </div>
    ${monoRow}
    <p class="answers"><strong>Why it answers your critique:</strong> ${opt.answers}</p>
  </article>`;
}

function groundSection(groundName, ground, color) {
  const cards = OPTIONS.map((o) => optionCard(o, color, groundName)).join('\n');
  return `
  <section class="ground ${groundName}" style="background:${ground};color:${color}">
    <h2 class="ground-title">${groundName === 'dark' ? 'On dark ground — Basalt-950 ' + C.basalt950 : 'On light ground — Ash-50 ' + C.ash50}</h2>
    <div class="cards">${cards}</div>
  </section>`;
}

function buildHtml() {
  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Scoria logo — round 2 (gate #2b): lockup relationships</title>
<style>
  :root { font-family: "IBM Plex Sans", system-ui, -apple-system, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; }
  * { box-sizing: border-box; }
  body { margin: 0; background: ${C.basalt950}; color: ${C.textDark}; line-height: 1.5; }
  h1,h2,h3 { font-weight: 600; letter-spacing: -.01em; margin: 0 0 .4em; }
  .page-head { padding: 32px 40px 8px; background: ${C.char850}; }
  .page-head h1 { font-size: 27px; }
  .page-head p { color: ${C.pumice500}; max-width: 78ch; margin: .3em 0; }
  .locked { color: ${C.molten400}; font-weight: 600; }
  .diagnosis { padding: 22px 40px; background: ${C.char850}; border-top: 1px solid rgba(255,255,255,.06); }
  .diagnosis h2 { font-size: 19px; }
  .diagnosis ul { max-width: 92ch; padding-left: 1.1em; }
  .diagnosis li { margin: .6em 0; }
  .diagnosis em { color: ${C.molten400}; font-style: normal; }
  .diagnosis .fix { background: rgba(230,90,50,.12); border-left: 3px solid ${C.ember500}; padding: 12px 16px; max-width: 92ch; }
  .recommend { padding: 22px 40px 30px; background: ${C.char850}; }
  .recommend h2 { font-size: 20px; color: ${C.molten400}; }
  .rank { margin: 0 0 1em; padding-left: 1.2em; max-width: 92ch; }
  .rank li { margin: .5em 0; }
  .my-pick { background: rgba(230,90,50,.16); border-left: 3px solid ${C.ember500}; padding: 12px 16px; max-width: 92ch; }
  .escape { background: rgba(138,129,120,.16); border-left: 3px solid ${C.pumice500}; padding: 12px 16px; max-width: 92ch; }
  .ground { padding: 28px 40px 48px; }
  .ground-title { font-size: 18px; opacity: .8; }
  .cards { display: grid; grid-template-columns: repeat(auto-fill, minmax(440px, 1fr)); gap: 22px; }
  .card { border: 1px solid currentColor; border-radius: 10px; padding: 18px; background: rgba(127,127,127,.05); }
  .card-head { display: flex; align-items: baseline; justify-content: space-between; gap: 12px; }
  .card-head h3 { font-size: 17px; }
  .oid { font-family: ui-monospace, Menlo, monospace; font-size: 13px; padding: 2px 6px; border: 1px solid currentColor; border-radius: 5px; margin-right: 6px; opacity: .9; }
  .tag { font-size: 12px; opacity: .7; white-space: nowrap; }
  .intent { font-size: 13.5px; opacity: .94; margin: .5em 0 1em; }
  .ramp { display: flex; align-items: flex-end; gap: 26px; flex-wrap: wrap; margin-bottom: 10px; padding-bottom: 10px; border-bottom: 1px dashed currentColor; }
  .ramp figure { margin: 0; text-align: left; }
  .ramp .art { display: flex; align-items: center; min-height: 64px; }
  .ramp figcaption { font-size: 11px; opacity: .6; margin-top: 4px; font-family: ui-monospace, monospace; }
  .mono-row { display: flex; align-items: center; gap: 18px; padding: 8px 0; }
  .mono-row .lbl { font-size: 11px; opacity: .6; font-family: ui-monospace, monospace; min-width: 84px; }
  .answers { font-size: 12.5px; opacity: .9; margin: .6em 0 0; }
  .missing { color: #c0392b; font-family: monospace; font-size: 12px; }
  svg { display: inline-block; vertical-align: middle; }
</style>
</head>
<body>
  <header class="page-head">
    <h1>Scoria logo — round&nbsp;2: lockup relationships</h1>
    <p>Direction is <span class="locked">LOCKED to TV-1&nbsp;"Span&nbsp;rail"</span> — its geometry is unchanged
       below. This round explores six different <strong>relationships between the mark and the wordmark</strong>
       (not new marks), and replaces the two rejected integrated typemarks with integrations that fix the actual
       defect. Each option is shown on both grounds, at full and small sizes, in monochrome, with a per-option
       design intent and a note on how it answers your critique.</p>
    <p>Standalone file:// page · inline SVG · no network · IBM&nbsp;Plex&nbsp;Sans system-fallback.</p>
  </header>
  ${rejectionBlock()}
  ${recommendationBlock()}
  ${groundSection('dark', C.basalt950, C.textDark)}
  ${groundSection('light', C.ash50, C.textLight)}
</body>
</html>
`;
}

const html = buildHtml();
writeFileSync(OUT, html, 'utf8');
console.log(`gallery-round2.mjs: wrote options-gallery-round2.html (${html.split('\n').length} lines)`);
