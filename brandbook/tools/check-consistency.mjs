#!/usr/bin/env node
/**
 * check-consistency.mjs
 *
 * Asserts hex-value consistency across the three Scoria token sources:
 *   1. brandbook/tokens.css   — docs/marketing SSOT (:root-scoped)
 *   2. assets/css/02-tokens.css — dashboard runtime SSOT (.scoria-root-scoped)
 *   3. brandbook/tokens.json  — structured token object (raw.color block)
 *
 * The check covers PRIMITIVE tokens only (the raw.color block in tokens.json
 * and their corresponding --scoria-* declarations in both CSS files).
 * Semantic tokens are intentionally excluded — they use var() references and
 * color-mix() expressions that vary between dark/light contexts.
 *
 * TODO(21-03): wire in brandbook/brand-book.md as a fourth source.
 *   Extension point: add a parseBrandBookHexes(filePath) function that extracts
 *   hex values from the color table in brand-book.md (markdown table or code block
 *   with #hex patterns), then add it to the comparison set below the "SOURCES"
 *   section. The assertion loop already handles N sources generically.
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
  // TODO(21-03): add brand-book.md source here. Example:
  // {
  //   label: 'brandbook/brand-book.md',
  //   path: resolve(REPO_ROOT, 'brandbook', 'brand-book.md'),
  //   parse: parseBrandBookHexes,
  // },
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

// ─── Assert CSS ↔ CSS ────────────────────────────────────────────────────────
// For every primitive token present in BOTH CSS files, the hex must match.
// We determine "primitive" by using the intersection of both CSS maps;
// semantic tokens (surface/text/link/etc.) are present in both but are NOT
// bare hex values (they resolve to var() in the runtime file), so they will
// not be captured by parseCssHexTokens — the regex only matches #hex.

console.log('\n── CSS ↔ CSS comparison ─────────────────────────────────────────');

const [primary, ...rest] = cssMaps;
const cssMismatches = [];

for (const [name, primaryHex] of primary.map) {
  for (const other of rest) {
    const otherHex = other.map.get(name);
    if (otherHex === undefined) continue; // token not present in this source — skip
    if (primaryHex !== otherHex) {
      cssMismatches.push({
        token: `--scoria-${name}`,
        [primary.label]: primaryHex,
        [other.label]: otherHex,
      });
    }
  }
}

if (cssMismatches.length === 0) {
  console.log(`PASS    All shared primitive tokens agree between CSS sources`);
} else {
  console.error(`FAIL    ${cssMismatches.length} primitive hex mismatch(es) between CSS sources:`);
  for (const m of cssMismatches) {
    const vals = Object.entries(m)
      .filter(([k]) => k !== 'token')
      .map(([src, hex]) => `  ${src}: ${hex}`)
      .join('\n');
    console.error(`\n  ${m.token}\n${vals}`);
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
