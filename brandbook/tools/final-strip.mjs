#!/usr/bin/env node
/**
 * final-strip.mjs — Standalone Phase 20 confirm strip generator
 *
 * Reads the 8 root SVGs from brandbook/ root via readFileSync and inlines
 * them into a small standalone final-variants.html showing all 8 variants
 * on both dark (#11100F) and light (#FAF5EF) grounds at realistic sizes.
 *
 * Standalone rule (T-20-04): zero external http(s) refs (xmlns excepted),
 * zero <img> tags — SVG markup is inlined directly.
 *
 * Usage: node brandbook/tools/final-strip.mjs
 *        (or: cd brandbook/tools && node final-strip.mjs)
 */

import { readFileSync, writeFileSync } from 'fs';
import { join, dirname, resolve } from 'path';
import { fileURLToPath } from 'url';

const __dir = dirname(fileURLToPath(import.meta.url));
const BRANDBOOK_DIR = resolve(__dir, '..');
const OUT = resolve(__dir, 'final-variants.html');

// The 8 census root SVGs in display order
const ROOT_SVGS = [
  { file: 'logo-primary.svg',          label: 'logo-primary.svg',          width: 240,  note: 'dark-surface lockup, two-tone ember \'o\'' },
  { file: 'logo-primary-light.svg',    label: 'logo-primary-light.svg',    width: 240,  note: 'light-surface lockup, scoria \'o\' accent' },
  { file: 'logo-mark.svg',             label: 'logo-mark.svg',             width: 48,   note: 'TV-1 span-rail mark, ember fill' },
  { file: 'logo-monochrome.svg',       label: 'logo-monochrome.svg',       width: 240,  note: 'single currentColor fill, holes intact' },
  { file: 'logo-lockup-subtitle.svg',  label: 'logo-lockup-subtitle.svg',  width: 240,  note: 'with tagline — only variant carrying subtitle' },
  { file: 'logotype-integrated.svg',   label: 'logotype-integrated.svg',   width: 240,  note: 'integrated typemark (≡ monochrome, currentColor)' },
  { file: 'favicon.svg',               label: 'favicon.svg',               width: 32,   note: '16px & 32px side-by-side — 3-hole pixel-snapped' },
  { file: 'social-card.svg',           label: 'social-card.svg',           width: 320,  note: '1280×640 card — scaled to fit' },
];

function readSvg(filename) {
  return readFileSync(join(BRANDBOOK_DIR, filename), 'utf8').trim();
}

// Build one tile: label, svg inline, note
function tile(svgFile, width, label, note, ground) {
  const svg = readSvg(svgFile);
  const isDark = ground === 'dark';

  // For monochrome/logotype-integrated, inject currentColor context via a wrapper div
  // so the SVG renders visibly on the given ground.
  const needsCurrentColor = svg.includes('currentColor');
  const ccColor = isDark ? '#FFF9F3' : '#11100F';

  // Favicon gets 16px AND 32px side-by-side
  const isFavicon = svgFile === 'favicon.svg';

  const labelColor = isDark ? '#88786D' : '#5A4D48';
  const noteColor  = isDark ? '#5A4D48' : '#88786D';

  let svgBlock;
  if (isFavicon) {
    const svg16 = svg.replace(/(<svg[^>]*)>/, '$1 width="16" height="16">');
    const svg32 = svg.replace(/(<svg[^>]*)>/, '$1 width="32" height="32">');
    svgBlock = `<div style="display:flex;align-items:center;gap:12px">
        <span style="color:${labelColor};font-size:10px">16px</span>${svg16}
        <span style="color:${labelColor};font-size:10px">32px</span>${svg32}
      </div>`;
  } else {
    const svgStyled = svg.replace(/(<svg[^>]*)>/, `$1 style="width:${width}px;height:auto;display:block">`);
    svgBlock = needsCurrentColor
      ? `<div style="color:${ccColor}">${svgStyled}</div>`
      : svgStyled;
  }

  return `<div style="margin-bottom:20px">
      <div style="font:11px/1.4 'JetBrains Mono',ui-monospace,monospace;color:${labelColor};margin-bottom:4px">${label}</div>
      ${svgBlock}
      <div style="font:10px/1.4 'JetBrains Mono',ui-monospace,monospace;color:${noteColor};margin-top:4px">${note}</div>
    </div>`;
}

// Build one ground section
function section(ground) {
  const bg    = ground === 'dark' ? '#11100F' : '#FAF5EF';
  const title = ground === 'dark'
    ? 'Dark ground — #11100F (Basalt 950)'
    : 'Light ground — #FAF5EF (Cream 50)';
  const titleColor = ground === 'dark' ? '#FFF9F3' : '#11100F';

  const tiles = ROOT_SVGS.map(({ file, label, width, note }) =>
    tile(file, width, label, note, ground)
  ).join('\n    ');

  return `<section style="background:${bg};padding:32px 40px;margin-bottom:2px">
  <h2 style="font:600 12px/1 'IBM Plex Sans',system-ui,sans-serif;color:${titleColor};letter-spacing:.08em;text-transform:uppercase;margin:0 0 24px 0">${title}</h2>
  <div style="display:flex;flex-wrap:wrap;gap:32px;align-items:flex-start">
    ${tiles}
  </div>
</section>`;
}

const html = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Scoria — Phase 20 final variant confirm strip</title>
<style>
  *, *::before, *::after { box-sizing: border-box; }
  body { margin: 0; font-family: 'IBM Plex Sans', system-ui, sans-serif; }
  h1 { font: 700 14px/1.4 'IBM Plex Sans', system-ui, sans-serif;
       background: #1e1b18; color: #FFF9F3;
       margin: 0; padding: 20px 40px;
       border-bottom: 1px solid #33302D; }
  h1 span { color: #88786D; font-weight: 400; }
</style>
</head>
<body>
<h1>Phase 20 final variant confirm strip <span>— ship it or adjust?</span></h1>
${section('dark')}
${section('light')}
</body>
</html>`;

writeFileSync(OUT, html, 'utf8');
console.log(`Written: ${OUT}`);
