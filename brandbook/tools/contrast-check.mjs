#!/usr/bin/env node
/**
 * Scoria WCAG 2.1 Contrast Checker
 *
 * Zero external dependencies. Run via:
 *   node brandbook/tools/contrast-check.mjs
 *
 * Implements WCAG 2.1 relative luminance (IEC 61966-2-1 sRGB linearization):
 *   channel: c/255 -> if <= 0.03928 then c/12.92 else ((c+0.055)/1.055)^2.4
 *   L = 0.2126*R + 0.7152*G + 0.0722*B
 *   ratio = (Llighter + 0.05) / (Ldarker + 0.05)
 *
 * Thresholds:
 *   PASS-AA    >= 4.5:1  (normal text AA)
 *   PASS-LARGE >= 3.0:1  (large text / UI components AA)
 *   FAIL       < 3.0:1
 */

// ---------------------------------------------------------------------------
// Core WCAG math
// ---------------------------------------------------------------------------

function hexToRgb(hex) {
  const h = hex.replace('#', '');
  if (h.length !== 6) throw new Error(`Bad hex: ${hex}`);
  return [
    parseInt(h.slice(0, 2), 16),
    parseInt(h.slice(2, 4), 16),
    parseInt(h.slice(4, 6), 16),
  ];
}

function linearize(c) {
  const s = c / 255;
  return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
}

function relativeLuminance(hex) {
  const [r, g, b] = hexToRgb(hex);
  return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b);
}

function contrastRatio(hexA, hexB) {
  const la = relativeLuminance(hexA);
  const lb = relativeLuminance(hexB);
  const lighter = Math.max(la, lb);
  const darker = Math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

function verdict(ratio) {
  if (ratio >= 4.5) return 'PASS-AA';
  if (ratio >= 3.0) return 'PASS-LARGE';
  return 'FAIL';
}

// ---------------------------------------------------------------------------
// Pairing data
// ---------------------------------------------------------------------------

const DOCUMENTED = [
  // §5.5 recommended safe text pairings
  { label: 'White-Hot on Basalt-950 (main text, dark)',         fg: ['White-Hot',    '#FFF9F3'], bg: ['Basalt-950',   '#11100F'], source: '§5.5' },
  { label: 'Ash-50 on Basalt-950 (main text, dark)',            fg: ['Ash-50',       '#FAF5EF'], bg: ['Basalt-950',   '#11100F'], source: '§5.5' },
  { label: 'Ash-100 on Basalt-900 (body text, dark)',           fg: ['Ash-100',      '#EFE6DE'], bg: ['Basalt-900',   '#181513'], source: '§5.5' },
  { label: 'Muted-warm on Basalt-950 (muted text, dark)',       fg: ['Muted-warm',   '#BDAEA3'], bg: ['Basalt-950',   '#11100F'], source: '§5.5' },
  { label: 'Basalt-950 on Ash-50 (main text, light)',           fg: ['Basalt-950',   '#11100F'], bg: ['Ash-50',       '#FAF5EF'], source: '§5.5' },
  { label: 'Graphite-700 on Ash-50 (secondary text, light)',    fg: ['Graphite-700', '#3A332F'], bg: ['Ash-50',       '#FAF5EF'], source: '§5.5' },
  { label: 'Scoria-600 on Ash-50 (links, light)',               fg: ['Scoria-600',   '#B94F31'], bg: ['Ash-50',       '#FAF5EF'], source: '§5.5' },
  { label: 'Scoria-700 on Ash-50 (outlines/links, light)',      fg: ['Scoria-700',   '#8D3826'], bg: ['Ash-50',       '#FAF5EF'], source: '§5.5' },
  { label: 'Ember-500 on Basalt-950 (links/actions, dark)',     fg: ['Ember-500',    '#E65A32'], bg: ['Basalt-950',   '#11100F'], source: '§5.5' },
  { label: 'Molten-400 on Basalt-950 (high-emphasis, dark)',    fg: ['Molten-400',   '#FF7A4D'], bg: ['Basalt-950',   '#11100F'], source: '§5.5' },
  // §5.5 known-risk pair (book warns: avoid as normal text on dark)
  { label: 'Pumice-500 on Basalt-950 (RISK: muted labels, dark)', fg: ['Pumice-500',  '#88786D'], bg: ['Basalt-950',   '#11100F'], source: '§5.5' },
  // §5.5 deliberate negative control — book explicitly warns against this
  { label: 'Scoria-600 on Basalt-950 (NEGATIVE CONTROL: §5.5 warns against)', fg: ['Scoria-600', '#B94F31'], bg: ['Basalt-950', '#11100F'], source: '§5.5' },

  // §5.4 functional accent pairs — dark surface
  { label: 'Success-dark on Basalt-950',  fg: ['Success-dark (#A7C76F)',  '#A7C76F'], bg: ['Basalt-950', '#11100F'], source: '§5.4' },
  { label: 'Info-dark on Basalt-950',     fg: ['Info-dark (#7DD8D1)',     '#7DD8D1'], bg: ['Basalt-950', '#11100F'], source: '§5.4' },
  { label: 'Warning-dark on Basalt-950',  fg: ['Warning-dark (#FFD166)',  '#FFD166'], bg: ['Basalt-950', '#11100F'], source: '§5.4' },
  { label: 'Danger-dark on Basalt-950',   fg: ['Danger-dark (#FF6B4A)',   '#FF6B4A'], bg: ['Basalt-950', '#11100F'], source: '§5.4' },
  { label: 'Trace-dark on Basalt-950',    fg: ['Trace-dark (#B798FF)',    '#B798FF'], bg: ['Basalt-950', '#11100F'], source: '§5.4' },

  // §5.4 functional accent pairs — light surface
  { label: 'Success-light on Ash-50',     fg: ['Success-light (#536A39)', '#536A39'], bg: ['Ash-50', '#FAF5EF'], source: '§5.4' },
  { label: 'Info-light on Ash-50',        fg: ['Info-light (#2A6C69)',    '#2A6C69'], bg: ['Ash-50', '#FAF5EF'], source: '§5.4' },
  { label: 'Warning-light on Ash-50 (RISK: Sulfur)', fg: ['Warning-light (#7A5A16)', '#7A5A16'], bg: ['Ash-50', '#FAF5EF'], source: '§5.4' },
  { label: 'Danger-light on Ash-50',      fg: ['Danger-light (#9E2F20)',  '#9E2F20'], bg: ['Ash-50', '#FAF5EF'], source: '§5.4' },
  { label: 'Trace-light on Ash-50',       fg: ['Trace-light (#6A55A7)',   '#6A55A7'], bg: ['Ash-50', '#FAF5EF'], source: '§5.4' },
];

// Shipped semantic pairings resolved from assets/css/02-tokens.css
// var() chains resolved to primitive hex:
//   Dark default (.scoria-root):
//     --scoria-surface-app = --scoria-basalt-950 = #11100F
//     --scoria-surface-panel = --scoria-basalt-900 = #181513
//     --scoria-text = --scoria-ash-50 = #FAF5EF
//     --scoria-text-muted = --scoria-muted-warm = #BDAEA3
//     --scoria-text-subtle = --scoria-pumice-500 = #88786D
//     --scoria-link = --scoria-ember-500 = #E65A32
//     --scoria-action = --scoria-ember-500 = #E65A32
//     --scoria-action-fg = --scoria-basalt-950 = #11100F
//     tone-*-fg resolved to their dark primitives
//   Light (.scoria-root[data-theme="light"]):
//     --scoria-surface-app = --scoria-ash-50 = #FAF5EF
//     --scoria-surface-panel = --scoria-white-hot = #FFF9F3
//     --scoria-text = --scoria-basalt-950 = #11100F
//     --scoria-text-muted = --scoria-graphite-700 = #3A332F
//     --scoria-text-subtle = --scoria-pumice-500 = #88786D  ← same pumice on light!
//     --scoria-link = --scoria-600 = #B94F31
//     --scoria-action = --scoria-600 = #B94F31
//     --scoria-action-fg = --scoria-white-hot = #FFF9F3
const SHIPPED = [
  // DARK theme — fg on --scoria-surface-app (#11100F)
  { label: 'shipped dark: --scoria-text on --scoria-surface-app',         fg: ['--scoria-text (#FAF5EF)',          '#FAF5EF'], bg: ['--scoria-surface-app (#11100F)',   '#11100F'], source: 'tokens.css:dark' },
  { label: 'shipped dark: --scoria-text-muted on --scoria-surface-app',   fg: ['--scoria-text-muted (#BDAEA3)',    '#BDAEA3'], bg: ['--scoria-surface-app (#11100F)',   '#11100F'], source: 'tokens.css:dark' },
  { label: 'shipped dark: --scoria-text-subtle on --scoria-surface-app',  fg: ['--scoria-text-subtle (#88786D)',   '#88786D'], bg: ['--scoria-surface-app (#11100F)',   '#11100F'], source: 'tokens.css:dark' },
  { label: 'shipped dark: --scoria-link on --scoria-surface-app',         fg: ['--scoria-link (#E65A32)',           '#E65A32'], bg: ['--scoria-surface-app (#11100F)',   '#11100F'], source: 'tokens.css:dark' },
  // DARK theme — fg on --scoria-surface-panel (#181513)
  { label: 'shipped dark: --scoria-text on --scoria-surface-panel',       fg: ['--scoria-text (#FAF5EF)',          '#FAF5EF'], bg: ['--scoria-surface-panel (#181513)', '#181513'], source: 'tokens.css:dark' },
  { label: 'shipped dark: --scoria-text-muted on --scoria-surface-panel', fg: ['--scoria-text-muted (#BDAEA3)',    '#BDAEA3'], bg: ['--scoria-surface-panel (#181513)', '#181513'], source: 'tokens.css:dark' },
  { label: 'shipped dark: --scoria-text-subtle on --scoria-surface-panel',fg: ['--scoria-text-subtle (#88786D)',   '#88786D'], bg: ['--scoria-surface-panel (#181513)', '#181513'], source: 'tokens.css:dark' },
  // DARK theme — action button: fg on action bg
  { label: 'shipped dark: --scoria-action-fg on --scoria-action',         fg: ['--scoria-action-fg (#11100F)',     '#11100F'], bg: ['--scoria-action (#E65A32)',         '#E65A32'], source: 'tokens.css:dark' },
  // DARK theme — tone family fg on Basalt-950 (solid surface underlying tint bg)
  { label: 'shipped dark: tone-neutral-fg (#CDBBAC) on Basalt-950',       fg: ['--scoria-tone-neutral-fg (#CDBBAC)','#CDBBAC'], bg: ['Basalt-950 (#11100F)',            '#11100F'], source: 'tokens.css:dark' },
  { label: 'shipped dark: tone-pass-fg (#A7C76F) on Basalt-950',          fg: ['--scoria-tone-pass-fg (#A7C76F)',  '#A7C76F'], bg: ['Basalt-950 (#11100F)',            '#11100F'], source: 'tokens.css:dark' },
  { label: 'shipped dark: tone-info-fg (#7DD8D1) on Basalt-950',          fg: ['--scoria-tone-info-fg (#7DD8D1)',  '#7DD8D1'], bg: ['Basalt-950 (#11100F)',            '#11100F'], source: 'tokens.css:dark' },
  { label: 'shipped dark: tone-warn-fg (#FFD166) on Basalt-950',          fg: ['--scoria-tone-warn-fg (#FFD166)',  '#FFD166'], bg: ['Basalt-950 (#11100F)',            '#11100F'], source: 'tokens.css:dark' },
  { label: 'shipped dark: tone-fail-fg (#FF6B4A) on Basalt-950',          fg: ['--scoria-tone-fail-fg (#FF6B4A)',  '#FF6B4A'], bg: ['Basalt-950 (#11100F)',            '#11100F'], source: 'tokens.css:dark' },
  { label: 'shipped dark: tone-trace-fg (#B798FF) on Basalt-950',         fg: ['--scoria-tone-trace-fg (#B798FF)', '#B798FF'], bg: ['Basalt-950 (#11100F)',            '#11100F'], source: 'tokens.css:dark' },
  { label: 'shipped dark: tone-brand-fg (#FF7A4D) on Basalt-950',         fg: ['--scoria-tone-brand-fg (#FF7A4D)', '#FF7A4D'], bg: ['Basalt-950 (#11100F)',            '#11100F'], source: 'tokens.css:dark' },

  // LIGHT theme — fg on --scoria-surface-app (#FAF5EF)
  { label: 'shipped light: --scoria-text on --scoria-surface-app',        fg: ['--scoria-text (#11100F)',          '#11100F'], bg: ['--scoria-surface-app (#FAF5EF)',   '#FAF5EF'], source: 'tokens.css:light' },
  { label: 'shipped light: --scoria-text-muted on --scoria-surface-app',  fg: ['--scoria-text-muted (#3A332F)',    '#3A332F'], bg: ['--scoria-surface-app (#FAF5EF)',   '#FAF5EF'], source: 'tokens.css:light' },
  { label: 'shipped light: --scoria-text-subtle on --scoria-surface-app', fg: ['--scoria-text-subtle (#88786D)',   '#88786D'], bg: ['--scoria-surface-app (#FAF5EF)',   '#FAF5EF'], source: 'tokens.css:light' },
  { label: 'shipped light: --scoria-link on --scoria-surface-app',        fg: ['--scoria-link (#B94F31)',           '#B94F31'], bg: ['--scoria-surface-app (#FAF5EF)',   '#FAF5EF'], source: 'tokens.css:light' },
  // LIGHT theme — fg on --scoria-surface-panel (#FFF9F3)
  { label: 'shipped light: --scoria-text on --scoria-surface-panel',      fg: ['--scoria-text (#11100F)',          '#11100F'], bg: ['--scoria-surface-panel (#FFF9F3)', '#FFF9F3'], source: 'tokens.css:light' },
  { label: 'shipped light: --scoria-text-muted on --scoria-surface-panel',fg: ['--scoria-text-muted (#3A332F)',    '#3A332F'], bg: ['--scoria-surface-panel (#FFF9F3)', '#FFF9F3'], source: 'tokens.css:light' },
  { label: 'shipped light: --scoria-text-subtle on --scoria-surface-panel',fg:['--scoria-text-subtle (#88786D)',   '#88786D'], bg: ['--scoria-surface-panel (#FFF9F3)', '#FFF9F3'], source: 'tokens.css:light' },
  // LIGHT theme — action button
  { label: 'shipped light: --scoria-action-fg on --scoria-action',        fg: ['--scoria-action-fg (#FFF9F3)',     '#FFF9F3'], bg: ['--scoria-action (#B94F31)',         '#B94F31'], source: 'tokens.css:light' },
  // LIGHT theme — tone family fg on Ash-50 (solid surface underlying tint bg)
  { label: 'shipped light: tone-neutral-fg (#3A332F) on Ash-50',          fg: ['--scoria-tone-neutral-fg (#3A332F)','#3A332F'], bg: ['Ash-50 (#FAF5EF)',               '#FAF5EF'], source: 'tokens.css:light' },
  { label: 'shipped light: tone-pass-fg (#536A39) on Ash-50',             fg: ['--scoria-tone-pass-fg (#536A39)',  '#536A39'], bg: ['Ash-50 (#FAF5EF)',               '#FAF5EF'], source: 'tokens.css:light' },
  { label: 'shipped light: tone-info-fg (#2A6C69) on Ash-50',             fg: ['--scoria-tone-info-fg (#2A6C69)',  '#2A6C69'], bg: ['Ash-50 (#FAF5EF)',               '#FAF5EF'], source: 'tokens.css:light' },
  { label: 'shipped light: tone-warn-fg (#7A5A16) on Ash-50',             fg: ['--scoria-tone-warn-fg (#7A5A16)',  '#7A5A16'], bg: ['Ash-50 (#FAF5EF)',               '#FAF5EF'], source: 'tokens.css:light' },
  { label: 'shipped light: tone-fail-fg (#9E2F20) on Ash-50',             fg: ['--scoria-tone-fail-fg (#9E2F20)',  '#9E2F20'], bg: ['Ash-50 (#FAF5EF)',               '#FAF5EF'], source: 'tokens.css:light' },
  { label: 'shipped light: tone-trace-fg (#6A55A7) on Ash-50',            fg: ['--scoria-tone-trace-fg (#6A55A7)', '#6A55A7'], bg: ['Ash-50 (#FAF5EF)',               '#FAF5EF'], source: 'tokens.css:light' },
  { label: 'shipped light: tone-brand-fg (#8D3826) on Ash-50',            fg: ['--scoria-tone-brand-fg (#8D3826)', '#8D3826'], bg: ['Ash-50 (#FAF5EF)',               '#FAF5EF'], source: 'tokens.css:light' },
];

// ---------------------------------------------------------------------------
// Output
// ---------------------------------------------------------------------------

function row(pairing) {
  const ratio = contrastRatio(pairing.fg[1], pairing.bg[1]);
  return {
    ...pairing,
    ratio,
    ratioStr: ratio.toFixed(2),
    verdict: verdict(ratio),
  };
}

function printTable(title, pairings) {
  console.log(`\n### ${title}\n`);
  console.log('| Foreground | Background | Ratio | Verdict | Source | Usage |');
  console.log('|---|---|---:|---|---|---|');
  for (const p of pairings) {
    const r = row(p);
    console.log(`| ${r.fg[0]} | ${r.bg[0]} | ${r.ratioStr}:1 | ${r.verdict} | ${r.source} | ${r.label} |`);
  }
  return pairings.map(row);
}

// Header
console.log('# Scoria WCAG 2.1 Contrast Audit');
console.log(`\nGenerated: ${new Date().toISOString()}`);
console.log('\nVerdicts: PASS-AA = ≥4.5:1 · PASS-LARGE = ≥3.0:1 · FAIL = <3.0:1');
console.log('\n---');

const docRows = printTable('DOCUMENTED — Brand-book §5.4 / §5.5 pairings', DOCUMENTED);
const shipRows = printTable('SHIPPED — Resolved semantic pairings from assets/css/02-tokens.css', SHIPPED);

const allRows = [...docRows, ...shipRows];
const passAA    = allRows.filter(r => r.verdict === 'PASS-AA').length;
const passLarge = allRows.filter(r => r.verdict === 'PASS-LARGE').length;
const fail      = allRows.filter(r => r.verdict === 'FAIL').length;

console.log('\n---');
console.log(`\n**Summary:** ${allRows.length} pairings — PASS-AA: ${passAA} · PASS-LARGE: ${passLarge} · FAIL: ${fail}`);

if (fail > 0) {
  console.log('\n**FAILing pairings:**');
  allRows.filter(r => r.verdict === 'FAIL').forEach(r => {
    console.log(`- ${r.label} — ${r.ratioStr}:1 (${r.source})`);
  });
}

if (passLarge > 0) {
  console.log('\n**PASS-LARGE (borderline, requires large text or UI context):**');
  allRows.filter(r => r.verdict === 'PASS-LARGE').forEach(r => {
    console.log(`- ${r.label} — ${r.ratioStr}:1 (${r.source})`);
  });
}
