#!/usr/bin/env node
/**
 * check-consistency.mjs
 *
 * Asserts hex-value consistency across the four Scoria token sources:
 *   1. brandbook/tokens.css   — docs/marketing SSOT (:root-scoped)
 *   2. assets/css/02-tokens.css — dashboard runtime SSOT (.scoria-root-scoped)
 *   3. brandbook/tokens.json  — structured token object (raw.color block)
 *   4. brandbook/brand-book.md — canonical guide (the §4 color tables)
 *
 * The check covers PRIMITIVE tokens only (the raw.color block in tokens.json
 * and their corresponding --scoria-* declarations in both CSS files).
 * Semantic tokens are intentionally excluded — they use var() references and
 * color-mix() expressions that vary between dark/light contexts.
 *
 * brand-book.md is a *subset* source: its §4 color tables document representative
 * palette values (e.g. "Basalt-950 | `#11100F`"), not every token. The check
 * therefore asserts agreement/membership — any hex in brand-book.md that names a
 * known token MUST match the CSS hex — and does NOT require completeness.
 *
 * Exit codes:
 *   0  — all sources agree (or only non-primitive tokens differ, which is expected)
 *   1  — at least one primitive hex mismatch found
 */

import { readFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, '..', '..');

// ─── Parsers ─────────────────────────────────────────────────────────────────

/**
 * Extract --scoria-NAME: #HEX pairs from a CSS file.
 * Only captures lines with a bare hex value (#xxx or #xxxxxx), not var() or rgba().
 * Returns a Map<name, normalizedHex>.
 */
function parseCssHexTokens(filePath) {
  const text = readFileSync(filePath, 'utf8');
  const map = new Map();
  // Match:  --scoria-name: #hexvalue;
  // Allows optional whitespace; captures the hex (3 or 6 digits, case-insensitive).
  const re = /--scoria-([\w-]+)\s*:\s*(#[0-9a-fA-F]{3,8})\s*;/g;
  let m;
  while ((m = re.exec(text)) !== null) {
    map.set(m[1], m[2].toLowerCase());
  }
  return map;
}

/**
 * Extract primitive hex values from tokens.json raw.color block.
 * The key names in raw.color use short names (e.g. "basalt-950"); we map them
 * to the --scoria-* CSS names by prepending "scoria-" only for the warm brand
 * scale (which in CSS is --scoria-900, --scoria-800, etc.) and using the key
 * directly for everything else.
 * Returns a Map<cssTokenName, normalizedHex>.
 */
function parseJsonPrimitives(filePath) {
  const json = JSON.parse(readFileSync(filePath, 'utf8'));
  const raw = json.raw?.color ?? {};
  const map = new Map();
  for (const [key, value] of Object.entries(raw)) {
    if (typeof value !== 'string' || !value.startsWith('#')) continue;
    // CSS token name: raw.color key maps 1:1 to --scoria-<key>
    // e.g. "basalt-950" → "basalt-950", "ember-500" → "ember-500",
    //      "scoria-900" → "900" in CSS (--scoria-900), "scoria-800" → "800", etc.
    // Handle the warm brand scale: raw.color uses "scoria-900", CSS uses "900".
    let cssName = key;
    if (/^scoria-\d+$/.test(key)) {
      cssName = key.replace(/^scoria-/, '');
    }
    map.set(cssName, value.toLowerCase());
  }
  return map;
}

/**
 * Extract documented token hexes from brand-book.md §4 color tables.
 *
 * The doc names tokens by their human label ("Basalt-950", "Ember-500",
 * "Success (pass)" with a light/dark hex pair, etc.). We map each label to the
 * corresponding --scoria-* CSS token name, normalize the hex to lowercase, and
 * return a Map<cssTokenName, normalizedHex>.
 *
 * Only labels that map cleanly to a single known primitive token are captured;
 * functional-accent rows that carry a light/dark hex pair are split into the
 * *-light / *-dark CSS names. Anything we cannot map is skipped (the doc is a
 * subset source — see file header).
 */
function parseBrandBookHexes(filePath) {
  const text = readFileSync(filePath, 'utf8');
  const map = new Map();

  // Label → CSS token name for single-hex neutral / brand-scale rows.
  const SINGLE = {
    'basalt-950': 'basalt-950',
    'basalt-900': 'basalt-900',
    'char-850': 'char-850',
    'graphite-700': 'graphite-700',
    'pumice-500': 'pumice-500',
    'muted-warm': 'muted-warm',
    'tuff-300': 'tuff-300',
    'ash-100': 'ash-100',
    'ash-50': 'ash-50',
    'white-hot': 'white-hot',
    'scoria-900': '900',
    'scoria-800': '800',
    'scoria-700': '700',
    'scoria-600': '600',
    'ember-500': 'ember-500',
    'molten-400': 'molten-400',
    'cinder-100': 'cinder-100',
    'cinder-50': 'cinder-50',
  };

  // Functional-accent role → [lightCssName, darkCssName] for the light/dark pair rows.
  const PAIR = {
    success: ['success-light', 'success-dark'],
    info: ['info-light', 'info-dark'],
    warning: ['warning-light', 'warning-dark'],
    danger: ['danger-light', 'danger-dark'],
    trace: ['trace-light', 'trace-dark'],
  };

  const hex = '#[0-9a-fA-F]{3,8}';

  // Single-hex table rows: | <Label> | `#HEX` | ... |
  for (const [label, cssName] of Object.entries(SINGLE)) {
    // Match a table row whose first cell is the label (case-insensitive) and
    // whose next cell is a backticked hex.
    const re = new RegExp(
      `\\|\\s*${label.replace('-', '-')}\\s*\\|\\s*\`(${hex})\`\\s*\\|`,
      'i'
    );
    const m = text.match(re);
    if (m) map.set(cssName, m[1].toLowerCase());
  }

  // Pair rows: | <Role> (pass) | `#LIGHT` | `#DARK` | ... |
  for (const [role, [lightName, darkName]] of Object.entries(PAIR)) {
    const re = new RegExp(
      `\\|\\s*${role}[^|]*\\|\\s*\`(${hex})\`\\s*\\|\\s*\`(${hex})\`\\s*\\|`,
      'i'
    );
    const m = text.match(re);
    if (m) {
      map.set(lightName, m[1].toLowerCase());
      map.set(darkName, m[2].toLowerCase());
    }
  }

  return map;
}

// ─── Sources ─────────────────────────────────────────────────────────────────

const SOURCES = [
  {
    label: 'brandbook/tokens.css',
    path: resolve(REPO_ROOT, 'brandbook', 'tokens.css'),
    parse: parseCssHexTokens,
  },
  {
    label: 'assets/css/02-tokens.css',
    path: resolve(REPO_ROOT, 'assets', 'css', '02-tokens.css'),
    parse: parseCssHexTokens,
  },
  {
    label: 'brandbook/brand-book.md',
    path: resolve(REPO_ROOT, 'brandbook', 'brand-book.md'),
    parse: parseBrandBookHexes,
  },
];

const JSON_SOURCE = {
  label: 'brandbook/tokens.json (raw.color)',
  path: resolve(REPO_ROOT, 'brandbook', 'tokens.json'),
};

// ─── Load ─────────────────────────────────────────────────────────────────────

const cssMaps = SOURCES.map(s => {
  try {
    const m = s.parse(s.path);
    console.log(`LOADED  ${s.label} — ${m.size} hex tokens found`);
    return { label: s.label, map: m };
  } catch (err) {
    console.error(`ERROR   Cannot read ${s.label}: ${err.message}`);
    process.exit(1);
  }
});

let jsonMap;
try {
  jsonMap = parseJsonPrimitives(JSON_SOURCE.path);
  console.log(`LOADED  ${JSON_SOURCE.label} — ${jsonMap.size} primitive hex values found`);
} catch (err) {
  console.error(`ERROR   Cannot read ${JSON_SOURCE.label}: ${err.message}`);
  process.exit(1);
}

// ─── Assert cross-source agreement ───────────────────────────────────────────
// Base = brandbook/tokens.css. Every other source (02-tokens.css, brand-book.md)
// must AGREE on every token it shares with the base. Sources are subsets — a
// token absent from a source is simply not asserted (brand-book.md documents a
// representative subset of the palette; see file header).
//   - 02-tokens.css: the runtime CSS SSOT (bare #hex declarations).
//   - brand-book.md: the §4 color tables (membership/agreement only).

console.log('\n── Cross-source agreement (base: brandbook/tokens.css) ───────────');

const [primary, ...rest] = cssMaps;
const cssMismatches = [];

for (const other of rest) {
  let shared = 0;
  const localMismatches = [];
  for (const [name, otherHex] of other.map) {
    const primaryHex = primary.map.get(name);
    if (primaryHex === undefined) continue; // not a primitive shared with the base — skip
    shared++;
    if (primaryHex !== otherHex) {
      const rec = {
        token: `--scoria-${name}`,
        [primary.label]: primaryHex,
        [other.label]: otherHex,
      };
      localMismatches.push(rec);
      cssMismatches.push(rec);
    }
  }
  if (localMismatches.length === 0) {
    console.log(`PASS    ${other.label} — ${shared} shared token(s), all agree`);
  } else {
    console.error(`FAIL    ${other.label} — ${localMismatches.length} mismatch(es):`);
    for (const m of localMismatches) {
      const vals = Object.entries(m)
        .filter(([k]) => k !== 'token')
        .map(([src, hex]) => `  ${src}: ${hex}`)
        .join('\n');
      console.error(`\n  ${m.token}\n${vals}`);
    }
  }
}

// ─── Assert JSON ↔ tokens.css ────────────────────────────────────────────────
// Every primitive in tokens.json raw.color must match the corresponding CSS token
// in brandbook/tokens.css (the brandbook-native SSOT for this check).

console.log('\n── JSON ↔ brandbook/tokens.css comparison ───────────────────────');

const jsonMismatches = [];
const jsonMissing = [];

for (const [name, jsonHex] of jsonMap) {
  const cssHex = primary.map.get(name);
  if (cssHex === undefined) {
    jsonMissing.push(name);
    continue;
  }
  if (jsonHex !== cssHex) {
    jsonMismatches.push({ name, json: jsonHex, css: cssHex });
  }
}

if (jsonMissing.length > 0) {
  console.warn(`WARN    ${jsonMissing.length} token(s) in tokens.json not found in tokens.css:`);
  for (const n of jsonMissing) console.warn(`  --scoria-${n}`);
}

if (jsonMismatches.length === 0) {
  console.log(`PASS    All tokens.json primitives match brandbook/tokens.css`);
} else {
  console.error(`FAIL    ${jsonMismatches.length} hex mismatch(es) between tokens.json and tokens.css:`);
  for (const m of jsonMismatches) {
    console.error(`  --scoria-${m.name}  json: ${m.json}  css: ${m.css}`);
  }
}

// ─── Summary ─────────────────────────────────────────────────────────────────

console.log('\n── Summary ──────────────────────────────────────────────────────');

const totalFails = cssMismatches.length + jsonMismatches.length;
if (totalFails === 0) {
  console.log('PASS    All token sources agree. Hex consistency check complete.\n');
  process.exit(0);
} else {
  console.error(`FAIL    ${totalFails} total mismatch(es). Fix the values above to restore consistency.\n`);
  process.exit(1);
}
