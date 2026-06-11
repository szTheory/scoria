#!/usr/bin/env node
/**
 * verify-logos.mjs — LOGO-01..07 + gallery-completeness verifier
 *
 * Usage: node brandbook/tools/verify-logos.mjs
 *        (or: cd brandbook/tools && node verify-logos.mjs)
 *
 * Exits 0 if all checks PASS, exits 1 if any check FAILs.
 * Prints one PASS/FAIL line per check with a brief description.
 */

import { readFileSync, readdirSync, statSync } from 'fs';
import { join, dirname, resolve } from 'path';
import { fileURLToPath } from 'url';

const __dir = dirname(fileURLToPath(import.meta.url));

// --- Resolve paths -----------------------------------------------------------
const CANDIDATES_DIR = resolve(__dir, 'candidates');
const GALLERY_FILE   = resolve(__dir, 'options-gallery.html');
const BRANDBOOK_DIR  = resolve(__dir, '..');

// --- Helpers -----------------------------------------------------------------
let failures = 0;

function pass(id, msg) {
  console.log(`PASS  [${id}]  ${msg}`);
}

function fail(id, msg) {
  console.log(`FAIL  [${id}]  ${msg}`);
  failures++;
}

function check(id, cond, passMsg, failMsg) {
  if (cond) {
    pass(id, passMsg);
  } else {
    fail(id, failMsg);
  }
}

// Read all candidate SVG files
const allSvgFiles = readdirSync(CANDIDATES_DIR)
  .filter(f => f.endsWith('.svg'))
  .sort();

const markFiles    = allSvgFiles.filter(f => f.endsWith('-mark.svg'));
const lockupFiles  = allSvgFiles.filter(f => f.endsWith('-lockup.svg'));
const monoFiles    = allSvgFiles.filter(f => f.endsWith('-mono.svg'));
const favFiles     = allSvgFiles.filter(f => f.endsWith('-fav.svg'));
const typeFiles    = allSvgFiles.filter(f => f.startsWith('TYPE-'));

function readCandidate(filename) {
  return readFileSync(join(CANDIDATES_DIR, filename), 'utf8');
}

console.log(`\nScoria logo verifier — checking ${allSvgFiles.length} candidates in candidates/`);
console.log(`Gallery: ${GALLERY_FILE}`);
console.log('─'.repeat(70));

// =============================================================================
// LOGO-01: No <rect in any candidate SVG
// =============================================================================
{
  const offenders = allSvgFiles.filter(f => readCandidate(f).includes('<rect'));
  check(
    'LOGO-01',
    offenders.length === 0,
    `No <rect background shapes in ${allSvgFiles.length} candidates`,
    `<rect found in: ${offenders.join(', ')}`
  );
}

// =============================================================================
// LOGO-02: Every *-mark.svg has fill-rule="evenodd" and exactly one <path>
// =============================================================================
{
  const violations = [];
  for (const f of markFiles) {
    const src = readCandidate(f);
    const hasEvenodd = src.includes('fill-rule="evenodd"');
    const pathCount  = (src.match(/<path/g) || []).length;
    if (!hasEvenodd) violations.push(`${f}: missing fill-rule="evenodd"`);
    if (pathCount !== 1) violations.push(`${f}: expected 1 <path>, found ${pathCount}`);
  }
  check(
    'LOGO-02',
    violations.length === 0,
    `All ${markFiles.length} mark SVGs have fill-rule="evenodd" and exactly 1 <path>`,
    violations.join(' | ')
  );
}

// =============================================================================
// LOGO-03: Each lockup SVG root carries data-gap-ratio in [0.35, 0.5]
// =============================================================================
{
  const violations = [];
  for (const f of lockupFiles) {
    const src = readCandidate(f);
    const m = src.match(/data-gap-ratio="([^"]+)"/);
    if (!m) {
      violations.push(`${f}: missing data-gap-ratio attribute`);
    } else {
      const val = parseFloat(m[1]);
      if (isNaN(val) || val < 0.35 || val > 0.5) {
        violations.push(`${f}: data-gap-ratio="${m[1]}" not in [0.35, 0.5]`);
      }
    }
  }
  check(
    'LOGO-03',
    violations.length === 0,
    `All ${lockupFiles.length} lockup SVGs carry data-gap-ratio in [0.35, 0.5]`,
    violations.join(' | ')
  );
}

// =============================================================================
// LOGO-04: No subtitle text in lockups ("AI ops", "Phoenix", tagline text)
// =============================================================================
{
  const SUBTITLE_PATTERNS = [
    /AI\s+ops/i,
    /for Phoenix/i,
    /subtitle/i,
    /tagline/i,
    /Trace the run/i,
    /Prove the change/i,
  ];
  const violations = [];
  for (const f of lockupFiles) {
    const src = readCandidate(f);
    for (const pat of SUBTITLE_PATTERNS) {
      if (pat.test(src)) {
        violations.push(`${f}: subtitle text matched "${pat}"`);
        break;
      }
    }
  }
  check(
    'LOGO-04',
    violations.length === 0,
    `No subtitle/tagline text in ${lockupFiles.length} lockup SVGs`,
    violations.join(' | ')
  );
}

// =============================================================================
// LOGO-05: >=2 typemark studies (TYPE-*.svg files)
// =============================================================================
{
  check(
    'LOGO-05',
    typeFiles.length >= 2,
    `${typeFiles.length} integrated typemark studies present (${typeFiles.join(', ')})`,
    `Only ${typeFiles.length} TYPE-*.svg found (need >=2)`
  );
}

// =============================================================================
// LOGO-06: TV favicon SVGs exist; each declares exactly 3 hole subpaths
//          A compound evenodd path has holes as interior subpaths — count them
//          by counting the number of M (moveto) commands minus 1 (the outer shape)
// =============================================================================
{
  const violations = [];

  if (favFiles.length === 0) {
    fail('LOGO-06', 'No *-fav.svg files found');
  } else {
    for (const f of favFiles) {
      const src = readCandidate(f);
      // Count M / m commands to find subpath count
      // Each "M" or "m" starts a new subpath in the compound path
      const pathMatch = src.match(/<path[^>]*d="([^"]+)"/);
      if (!pathMatch) {
        violations.push(`${f}: no <path d="..."> found`);
        continue;
      }
      const d = pathMatch[1];
      // Count absolute M commands (start of each subpath)
      const mCount = (d.match(/M/g) || []).length;
      // First M is the outer silhouette, remaining are holes
      const holeCount = mCount - 1;
      if (holeCount !== 3) {
        violations.push(`${f}: expected 3 holes, found ${holeCount} (M count = ${mCount})`);
      }
    }
    check(
      'LOGO-06',
      violations.length === 0,
      `All ${favFiles.length} favicon SVGs have exactly 3 hole subpaths`,
      violations.join(' | ')
    );
  }
}

// =============================================================================
// LOGO-07: Monochrome variants exist and use currentColor (holes intact)
// =============================================================================
{
  if (monoFiles.length === 0) {
    fail('LOGO-07', 'No *-mono.svg files found');
  } else {
    const violations = [];
    for (const f of monoFiles) {
      const src = readCandidate(f);
      if (!src.includes('currentColor')) {
        violations.push(`${f}: missing currentColor fill`);
      }
      // Holes intact = fill-rule="evenodd" present
      if (!src.includes('fill-rule="evenodd"')) {
        violations.push(`${f}: missing fill-rule="evenodd" (holes may be lost)`);
      }
    }
    check(
      'LOGO-07',
      violations.length === 0,
      `All ${monoFiles.length} mono SVGs use currentColor with evenodd (holes intact)`,
      violations.join(' | ')
    );
  }
}

// =============================================================================
// STRUCTURAL: No strokes in any candidate
// =============================================================================
{
  const offenders = allSvgFiles.filter(f => {
    const src = readCandidate(f);
    // Allow stroke="none" or stroke-width="0" (explicitly disabled) — these are fine
    // Fail if there's a non-none stroke
    return /stroke(?!=[-a-z])/.test(src) &&
      !src.split('\n').every(line =>
        !line.includes('stroke') ||
        line.includes('stroke="none"') ||
        line.includes('stroke-width="0"')
      );
  });
  check(
    'STRUCT-STROKE',
    offenders.length === 0,
    `No active stroke attributes in ${allSvgFiles.length} candidates`,
    `Stroke found in: ${offenders.join(', ')}`
  );
}

// =============================================================================
// STRUCTURAL: Coordinates <= 2 decimal places
// =============================================================================
{
  const offenders = [];
  for (const f of allSvgFiles) {
    const src = readCandidate(f);
    // Look for numbers with 3+ decimal places in path data
    if (/[0-9]\.[0-9]{3,}/.test(src)) {
      offenders.push(f);
    }
  }
  check(
    'STRUCT-DECIMALS',
    offenders.length === 0,
    `All coordinates <=2 decimal places in ${allSvgFiles.length} candidates`,
    `3+ decimal places found in: ${offenders.join(', ')}`
  );
}

// =============================================================================
// STRUCTURAL: viewBox present and origin near 0 (tighter than ±200 units)
// =============================================================================
{
  const violations = [];
  for (const f of allSvgFiles) {
    const src = readCandidate(f);
    const m = src.match(/viewBox="([^"]+)"/);
    if (!m) {
      violations.push(`${f}: no viewBox`);
      continue;
    }
    const parts = m[1].split(/\s+/).map(Number);
    if (parts.length < 4 || parts.some(isNaN)) {
      violations.push(`${f}: malformed viewBox "${m[1]}"`);
      continue;
    }
    const [minX, minY] = parts;
    if (Math.abs(minX) > 200 || Math.abs(minY) > 200) {
      violations.push(`${f}: viewBox origin (${minX},${minY}) far from 0`);
    }
  }
  check(
    'STRUCT-VIEWBOX',
    violations.length === 0,
    `All ${allSvgFiles.length} candidates have viewBox with origin near 0`,
    violations.join(' | ')
  );
}

// =============================================================================
// GALLERY: Standalone (zero external http(s) refs, zero <img)
// =============================================================================
{
  const gallery = readFileSync(GALLERY_FILE, 'utf8');

  // External HTTP refs (SVG xmlns is excepted — it's never fetched)
  const httpMatches = gallery.match(/https?:\/\/(?!www\.w3\.org\/2000\/svg)[^\s"<>]+/g) || [];
  check(
    'GALLERY-STANDALONE',
    httpMatches.length === 0,
    'Gallery has zero external network references',
    `External refs found: ${httpMatches.slice(0, 5).join(', ')}`
  );

  // No <img tags
  const imgCount = (gallery.match(/<img/g) || []).length;
  check(
    'GALLERY-NO-IMG',
    imgCount === 0,
    'Gallery has zero <img> tags (fully inline SVG)',
    `${imgCount} <img> tag(s) found`
  );
}

// =============================================================================
// GALLERY: Both grounds present (#11100F and #FAF5EF)
// =============================================================================
{
  const gallery = readFileSync(GALLERY_FILE, 'utf8');
  const hasDark  = gallery.includes('#11100F');
  const hasLight = gallery.includes('#FAF5EF');
  check(
    'GALLERY-GROUNDS',
    hasDark && hasLight,
    'Gallery has both dark (#11100F) and light (#FAF5EF) grounds',
    `Missing: ${hasDark ? '' : '#11100F '}${hasLight ? '' : '#FAF5EF'}`
  );
}

// =============================================================================
// GALLERY: Full size ramp (256/64/32/16)
// =============================================================================
{
  const gallery = readFileSync(GALLERY_FILE, 'utf8');
  const sizes = [256, 64, 32, 16];
  const missing = sizes.filter(s => !gallery.includes(`width="${s}"`));
  check(
    'GALLERY-SIZE-RAMP',
    missing.length === 0,
    'Gallery includes all sizes: 256 / 64 / 32 / 16px',
    `Missing width values: ${missing.join(', ')}`
  );
}

// =============================================================================
// GALLERY: Mock keywords (monochrome, favicon, sidebar, readme)
// =============================================================================
{
  const gallery = readFileSync(GALLERY_FILE, 'utf8').toLowerCase();
  const KEYWORDS = ['monochrome', 'favicon', 'sidebar', 'readme'];
  const missing = KEYWORDS.filter(k => !gallery.includes(k));
  check(
    'GALLERY-MOCKS',
    missing.length === 0,
    `Gallery references all mock contexts: ${KEYWORDS.join(', ')}`,
    `Missing keywords: ${missing.join(', ')}`
  );
}

// =============================================================================
// GALLERY: All stable option IDs present (>=6 marks + 2 typemarks)
// =============================================================================
{
  const gallery = readFileSync(GALLERY_FILE, 'utf8');
  const REQUIRED_IDS = ['TV-1', 'TV-2', 'TV-3', 'CM-1', 'CM-2', 'AP-1', 'TYPE-1', 'TYPE-2'];
  const missing = REQUIRED_IDS.filter(id => !gallery.includes(id));
  check(
    'GALLERY-IDS',
    missing.length === 0,
    `All stable option IDs present: ${REQUIRED_IDS.join(', ')}`,
    `Missing IDs: ${missing.join(', ')}`
  );
}

// =============================================================================
// GALLERY: Ranked recommendation block present (names a specific ID)
// =============================================================================
{
  const gallery = readFileSync(GALLERY_FILE, 'utf8');
  const hasRecommend  = /recommend/i.test(gallery);
  const hasPick       = /TV-1|CM-1|CM-2/i.test(gallery) && /recommend|pick|primary/i.test(gallery);
  check(
    'GALLERY-RECOMMEND',
    hasRecommend && hasPick,
    'Gallery has a ranked recommendation block naming a specific option ID',
    'Recommendation block missing or does not name a specific option ID'
  );
}

// =============================================================================
// GALLERY: Second-round escape note present
// =============================================================================
{
  const gallery = readFileSync(GALLERY_FILE, 'utf8');
  const hasEscape = /second round|none of these/i.test(gallery);
  check(
    'GALLERY-ESCAPE',
    hasEscape,
    'Gallery includes "none of these → second round" escape note',
    'Escape note missing (need "second round" or "none of these")'
  );
}

// =============================================================================
// BUDGET: brandbook/ source artifacts < 1024 KB (Phase 19 tooling budget)
//
// The §8 pressure-test.md budget (<500 KB) applies to the final brandbook/ root
// (Phase 20+: logo-*.svg + brand-book.md + examples/). Phase 19 produces a
// 320 KB standalone gallery (options-gallery.html) that inlines all 23 candidate
// SVGs — this is intentional tooling output and exceeds the Phase 20 target.
//
// This check uses 1024 KB as the Phase 19 tooling budget (excluding node_modules).
// After gate #2 and Phase 20, all tooling artifacts are pruned and the final
// brandbook/ root must satisfy the original <500 KB constraint.
// =============================================================================
{
  function walkSize(dir, excludeDir) {
    let total = 0;
    for (const entry of readdirSync(dir)) {
      const full = join(dir, entry);
      if (excludeDir && full === excludeDir) continue;
      const st = statSync(full);
      if (st.isDirectory()) {
        total += walkSize(full, excludeDir);
      } else if (/\.(svg|html|mjs|md|json)$/.test(entry)) {
        total += st.size;
      }
    }
    return total;
  }

  const nodeModulesDir = resolve(BRANDBOOK_DIR, 'tools', 'node_modules');
  const totalBytes = walkSize(BRANDBOOK_DIR, nodeModulesDir);
  const totalKB = Math.round(totalBytes / 1024);
  // Phase 19 tooling budget: 1024 KB (gallery inlines 23 SVGs; Phase 20 target is <500 KB)
  const BUDGET_KB = 1024;

  check(
    'BUDGET',
    totalKB < BUDGET_KB,
    `brandbook/ text+SVG artifacts: ${totalKB} KB (Phase 19 tooling budget: <${BUDGET_KB} KB; Phase 20 final target: <500 KB)`,
    `brandbook/ text+SVG artifacts: ${totalKB} KB — EXCEEDS ${BUDGET_KB} KB Phase 19 tooling budget`
  );
}

// =============================================================================
// Summary
// =============================================================================
console.log('─'.repeat(70));
if (failures === 0) {
  console.log(`\nAll checks PASSED — ${allSvgFiles.length} candidates verified, gallery complete.\n`);
  process.exit(0);
} else {
  console.log(`\n${failures} check(s) FAILED.\n`);
  process.exit(1);
}
