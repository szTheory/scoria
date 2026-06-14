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

import { readFileSync, readdirSync, statSync, existsSync } from 'fs';
import { join, dirname, resolve } from 'path';
import { fileURLToPath } from 'url';

const __dir = dirname(fileURLToPath(import.meta.url));

// --- Resolve paths -----------------------------------------------------------
const CANDIDATES_DIR = resolve(__dir, 'candidates');
const GALLERY_FILE   = resolve(__dir, 'options-gallery.html');
const BRANDBOOK_DIR  = resolve(__dir, '..');

// Phase 20: the gallery HTML files and losing candidates are pruned in this
// phase. Gallery-completeness + full-candidate-set checks therefore SKIP
// gracefully (pass with a "pruned in Phase 20" note) once the gallery is gone.
const GALLERY_PRESENT = existsSync(GALLERY_FILE);

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
// LOGO-03: Each SIDE-BY-SIDE lockup SVG root carries data-gap-ratio in [0.35,0.5]
//
// Round-2 escape (19-02b) introduced integrated/stacked/overlap lockups (LK-B
// mark-as-o, LK-C stacked, LK-D overlap, LK-E counter-punch, LK-F mark-as-tittle)
// where the mark and wordmark are NOT placed side-by-side, so a horizontal
// data-gap-ratio is undefined by construction. Per the 19-02b brief
// ("LOGO-03 data-gap-ratio applies to side-by-side lockups; stacked/integrated
// forms may exempt with a documented reason"), such files declare an explicit
// machine-readable exemption marker on the root <svg>:
//   data-integrated="true"   — mark fused into a letterform (LK-B/E/F)
//   data-gap-exempt="..."    — relationship is overlap/stack, not a gap (LK-C/D)
// Side-by-side lockups (round-1 *-lockup.svg and LK-A) MUST still carry a valid
// data-gap-ratio. This keeps LOGO-03 enforced where it is meaningful and
// documents the exemption where it is not.
// =============================================================================
{
  const violations = [];
  let exemptCount = 0;
  for (const f of lockupFiles) {
    const src = readCandidate(f);
    const exempt = /data-integrated="true"/.test(src) || /data-gap-exempt="/.test(src);
    if (exempt) {
      exemptCount++;
      continue; // documented stacked/integrated/overlap form — gap is undefined
    }
    const m = src.match(/data-gap-ratio="([^"]+)"/);
    if (!m) {
      violations.push(`${f}: missing data-gap-ratio attribute (and no exemption marker)`);
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
    `All ${lockupFiles.length - exemptCount} side-by-side lockup SVGs carry data-gap-ratio in [0.35, 0.5] (${exemptCount} integrated/stacked/overlap forms documented-exempt)`,
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
  if (typeFiles.length === 0) {
    // Phase 20: TYPE-1/TYPE-2 ring-o/porous-a typemark STUDIES were rejected at
    // gate #2b and pruned — the LK-B fused lockup IS the integrated typemark now
    // (shipped as logotype-integrated.svg). The >=2-study gate no longer applies.
    pass('LOGO-05', 'typemarks pruned in Phase 20 (LK-B fused lockup is the integrated typemark) — skipped');
  } else {
    check(
      'LOGO-05',
      typeFiles.length >= 2,
      `${typeFiles.length} integrated typemark studies present (${typeFiles.join(', ')})`,
      `Only ${typeFiles.length} TYPE-*.svg found (need >=2)`
    );
  }
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
    // The ±200 bound catches accidental padding boxes. A vertical/stacked lockup
    // (LK-C) legitimately needs a tall negative-Y origin because the mark stacks
    // far above the baseline-anchored wordmark; allow ±300 on Y for stacked forms
    // (declared via data-gap-exempt or data-variant="LK-C"). X stays tight (±200)
    // since nothing here is laid out far off-origin horizontally.
    const isStacked = /data-gap-exempt="stack"/.test(src) || /data-variant="LK-C"/.test(src);
    const yBound = isStacked ? 300 : 200;
    if (Math.abs(minX) > 200 || Math.abs(minY) > yBound) {
      violations.push(`${f}: viewBox origin (${minX},${minY}) far from 0`);
    }
  }
  check(
    'STRUCT-VIEWBOX',
    violations.length === 0,
    `All ${allSvgFiles.length} candidates have viewBox with origin near 0 (stacked lockups allowed ±300 on Y)`,
    violations.join(' | ')
  );
}

// =============================================================================
// GALLERY: completeness checks — Phase 20 prunes the gallery HTML files, so
// these SKIP gracefully (pass with a "pruned in Phase 20" note) when absent.
// They served gate #2 and live on in git history; the ROOT-* checks below are
// the Phase 20 gate.
// =============================================================================
if (!GALLERY_PRESENT) {
  pass('GALLERY-*', 'gallery HTML pruned in Phase 20 — gallery-completeness checks skipped (ROOT-* checks gate the converged set)');
} else {
  // GALLERY: Standalone (zero external http(s) refs, zero <img)
  {
    const gallery = readFileSync(GALLERY_FILE, 'utf8');
    const httpMatches = gallery.match(/https?:\/\/(?!www\.w3\.org\/2000\/svg)[^\s"<>]+/g) || [];
    check('GALLERY-STANDALONE', httpMatches.length === 0,
      'Gallery has zero external network references',
      `External refs found: ${httpMatches.slice(0, 5).join(', ')}`);
    const imgCount = (gallery.match(/<img/g) || []).length;
    check('GALLERY-NO-IMG', imgCount === 0,
      'Gallery has zero <img> tags (fully inline SVG)',
      `${imgCount} <img> tag(s) found`);
  }
  // GALLERY: Both grounds present (#11100F and #FAF5EF)
  {
    const gallery = readFileSync(GALLERY_FILE, 'utf8');
    const hasDark  = gallery.includes('#11100F');
    const hasLight = gallery.includes('#FAF5EF');
    check('GALLERY-GROUNDS', hasDark && hasLight,
      'Gallery has both dark (#11100F) and light (#FAF5EF) grounds',
      `Missing: ${hasDark ? '' : '#11100F '}${hasLight ? '' : '#FAF5EF'}`);
  }
  // GALLERY: Full size ramp (256/64/32/16)
  {
    const gallery = readFileSync(GALLERY_FILE, 'utf8');
    const sizes = [256, 64, 32, 16];
    const missing = sizes.filter(s => !gallery.includes(`width="${s}"`));
    check('GALLERY-SIZE-RAMP', missing.length === 0,
      'Gallery includes all sizes: 256 / 64 / 32 / 16px',
      `Missing width values: ${missing.join(', ')}`);
  }
  // GALLERY: Mock keywords (monochrome, favicon, sidebar, readme)
  {
    const gallery = readFileSync(GALLERY_FILE, 'utf8').toLowerCase();
    const KEYWORDS = ['monochrome', 'favicon', 'sidebar', 'readme'];
    const missing = KEYWORDS.filter(k => !gallery.includes(k));
    check('GALLERY-MOCKS', missing.length === 0,
      `Gallery references all mock contexts: ${KEYWORDS.join(', ')}`,
      `Missing keywords: ${missing.join(', ')}`);
  }
  // GALLERY: All stable option IDs present (>=6 marks + 2 typemarks)
  {
    const gallery = readFileSync(GALLERY_FILE, 'utf8');
    const REQUIRED_IDS = ['TV-1', 'TV-2', 'TV-3', 'CM-1', 'CM-2', 'AP-1', 'TYPE-1', 'TYPE-2'];
    const missing = REQUIRED_IDS.filter(id => !gallery.includes(id));
    check('GALLERY-IDS', missing.length === 0,
      `All stable option IDs present: ${REQUIRED_IDS.join(', ')}`,
      `Missing IDs: ${missing.join(', ')}`);
  }
  // GALLERY: Ranked recommendation block present (names a specific ID)
  {
    const gallery = readFileSync(GALLERY_FILE, 'utf8');
    const hasRecommend  = /recommend/i.test(gallery);
    const hasPick       = /TV-1|CM-1|CM-2/i.test(gallery) && /recommend|pick|primary/i.test(gallery);
    check('GALLERY-RECOMMEND', hasRecommend && hasPick,
      'Gallery has a ranked recommendation block naming a specific option ID',
      'Recommendation block missing or does not name a specific option ID');
  }
  // GALLERY: Second-round escape note present
  {
    const gallery = readFileSync(GALLERY_FILE, 'utf8');
    const hasEscape = /second round|none of these/i.test(gallery);
    check('GALLERY-ESCAPE', hasEscape,
      'Gallery includes "none of these → second round" escape note',
      'Escape note missing (need "second round" or "none of these")');
  }
}

// =============================================================================
// ROOT-* : Phase 20 converged variant gate — the 8 census SVGs at brandbook/ root
// =============================================================================
{
  const ROOT_NAMES = [
    'logo-primary.svg',
    'logo-primary-light.svg',
    'logo-mark.svg',
    'logo-monochrome.svg',
    'logo-lockup-subtitle.svg',
    'logotype-integrated.svg',
    'favicon.svg',
    'social-card.svg',
  ];
  const SOCIAL = 'social-card.svg';
  const readRoot = (f) => readFileSync(join(BRANDBOOK_DIR, f), 'utf8');
  const present = ROOT_NAMES.filter((f) => existsSync(join(BRANDBOOK_DIR, f)));

  // ROOT-EXISTS: all 8 census filenames at brandbook/ root
  {
    const missing = ROOT_NAMES.filter((f) => !existsSync(join(BRANDBOOK_DIR, f)));
    check('ROOT-EXISTS', missing.length === 0,
      `All 8 root variant SVGs present: ${ROOT_NAMES.join(', ')}`,
      `Missing root SVGs: ${missing.join(', ')}`);
  }

  // ROOT-NORECT: no <rect in any root SVG EXCEPT social-card.svg, which is
  // allowed EXACTLY ONE card-ground rect (documented exemption — 20-CONTEXT:
  // "the card IS a bounded artwork, not a logo background").
  {
    const offenders = [];
    for (const f of present) {
      const rectCount = (readRoot(f).match(/<rect/g) || []).length;
      if (f === SOCIAL) {
        if (rectCount !== 1) offenders.push(`${f}: expected exactly 1 card-ground rect, found ${rectCount}`);
      } else if (rectCount !== 0) {
        offenders.push(`${f}: ${rectCount} <rect> (none allowed)`);
      }
    }
    check('ROOT-NORECT', offenders.length === 0,
      'No <rect> in the 7 logo SVGs; social-card.svg has exactly its 1 documented card-ground rect',
      offenders.join(' | '));
  }

  // ROOT-EVENODD: every root logo path uses fill-rule="evenodd" (holes punched)
  {
    const offenders = present.filter((f) => !readRoot(f).includes('fill-rule="evenodd"'));
    check('ROOT-EVENODD', offenders.length === 0,
      `All ${present.length} root SVGs carry fill-rule="evenodd" (mark holes punched)`,
      `Missing evenodd in: ${offenders.join(', ')}`);
  }

  // ROOT-STROKE: no active stroke attributes (reuse the candidate stroke logic)
  {
    const offenders = present.filter((f) => {
      const src = readRoot(f);
      return /stroke(?!=[-a-z])/.test(src) &&
        !src.split('\n').every(line =>
          !line.includes('stroke') ||
          line.includes('stroke="none"') ||
          line.includes('stroke-width="0"'));
    });
    check('ROOT-STROKE', offenders.length === 0,
      `No active stroke attributes in ${present.length} root SVGs`,
      `Stroke found in: ${offenders.join(', ')}`);
  }

  // ROOT-VIEWBOX: every root SVG has a viewBox; logo viewBoxes tight near origin.
  // social-card is the bounded 0 0 1280 640 canvas — exempt from the tight-origin bound.
  {
    const violations = [];
    for (const f of present) {
      const m = readRoot(f).match(/viewBox="([^"]+)"/);
      if (!m) { violations.push(`${f}: no viewBox`); continue; }
      const parts = m[1].split(/\s+/).map(Number);
      if (parts.length < 4 || parts.some(isNaN)) { violations.push(`${f}: malformed viewBox "${m[1]}"`); continue; }
      if (f === SOCIAL) continue; // bounded card canvas — exempt from tight-origin
      const [minX, minY] = parts;
      if (Math.abs(minX) > 200 || Math.abs(minY) > 200) {
        violations.push(`${f}: viewBox origin (${minX},${minY}) far from 0`);
      }
    }
    check('ROOT-VIEWBOX', violations.length === 0,
      `All ${present.length} root SVGs have a viewBox; logo viewBoxes tight near origin (social-card exempt)`,
      violations.join(' | '));
  }

  // ROOT-DECIMALS: all coordinates ≤2 decimal places across the 8 files
  {
    const offenders = present.filter((f) => /[0-9]\.[0-9]{3,}/.test(readRoot(f)));
    check('ROOT-DECIMALS', offenders.length === 0,
      `All coordinates ≤2 decimal places across ${present.length} root SVGs`,
      `3+ decimal places found in: ${offenders.join(', ')}`);
  }

  // ROOT-CURRENTCOLOR: logo-monochrome.svg and logotype-integrated.svg use currentColor
  {
    const need = ['logo-monochrome.svg', 'logotype-integrated.svg'].filter((f) => present.includes(f));
    const offenders = need.filter((f) => !readRoot(f).includes('currentColor'));
    check('ROOT-CURRENTCOLOR', offenders.length === 0,
      'logo-monochrome.svg and logotype-integrated.svg use currentColor (single-color, holes intact)',
      `Missing currentColor in: ${offenders.join(', ')}`);
  }

  // ROOT-FAVICON: favicon.svg ≤1024 bytes AND exactly 3 hole subpaths (M-count − 1)
  {
    const violations = [];
    const fav = 'favicon.svg';
    if (!present.includes(fav)) {
      violations.push('favicon.svg missing');
    } else {
      const bytes = statSync(join(BRANDBOOK_DIR, fav)).size;
      if (bytes > 1024) violations.push(`favicon.svg is ${bytes} bytes (>1024)`);
      const d = readRoot(fav).match(/<path[^>]*\sd="([^"]+)"/)?.[1] || '';
      const holeCount = (d.match(/M/g) || []).length - 1;
      if (holeCount !== 3) violations.push(`favicon.svg has ${holeCount} holes (expected 3)`);
    }
    check('ROOT-FAVICON', violations.length === 0,
      'favicon.svg ≤1024 bytes with exactly 3 hole subpaths',
      violations.join(' | '));
  }

  // ROOT-SUBTITLE: logo-lockup-subtitle.svg carries the tagline; the OTHER logo
  // SVGs do NOT (social-card MAY carry the tagline — exempt).
  {
    const TAGLINE = 'AI ops for Phoenix apps.';
    const violations = [];
    const subtitle = 'logo-lockup-subtitle.svg';
    if (present.includes(subtitle) && !readRoot(subtitle).includes(TAGLINE)) {
      violations.push(`${subtitle}: missing tagline "${TAGLINE}"`);
    }
    for (const f of present) {
      if (f === subtitle || f === SOCIAL) continue; // subtitle must carry it; social may
      if (readRoot(f).includes(TAGLINE) || /AI\s+ops/i.test(readRoot(f))) {
        violations.push(`${f}: unexpected tagline text`);
      }
    }
    check('ROOT-SUBTITLE', violations.length === 0,
      'logo-lockup-subtitle.svg carries the tagline; the other logo SVGs carry none (social-card exempt)',
      violations.join(' | '));
  }
}

// =============================================================================
// BUDGET: brandbook/ source artifacts < 500 KB (final BRAND-05 target)
//
// The §8 pressure-test.md budget (<500 KB) applies to the final brandbook/ root.
// Phase 19 temporarily relaxed this to 1024 KB because the standalone galleries
// inlined all candidate SVGs. Phase 20 PRUNES both gallery HTML files and the
// losing candidates, so the threshold returns to the original <500 KB target
// (excluding node_modules, which is gitignored).
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
  // Phase 20 final target: <500 KB (galleries + losing candidates pruned).
  const BUDGET_KB = 500;

  check(
    'BUDGET',
    totalKB < BUDGET_KB,
    `brandbook/ text+SVG artifacts: ${totalKB} KB (Phase 20 final target: <${BUDGET_KB} KB)`,
    `brandbook/ text+SVG artifacts: ${totalKB} KB — EXCEEDS ${BUDGET_KB} KB final target`
  );
}

// =============================================================================
// Summary
// =============================================================================
console.log('─'.repeat(70));
if (failures === 0) {
  console.log(`\nAll checks PASSED — ${allSvgFiles.length} candidates + 8 root variants verified.\n`);
  process.exit(0);
} else {
  console.log(`\n${failures} check(s) FAILED.\n`);
  process.exit(1);
}
