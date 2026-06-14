/**
 * wordmark.mjs — Wordmark path generation for "Scoria" in IBM Plex Sans SemiBold
 *
 * Uses wawoff2 (CJS default import) to decompress the repo woff2 at runtime,
 * then opentype.js to outline the text as SVG paths. Includes an integrated
 * glyph-replacement hook that swaps the 'o' for a vesicle-ring form matching
 * the original 'o' advance width and x-height alignment.
 *
 * IMPORTANT — wawoff2 is CJS-only: import via default, not named export.
 * See CJS import note near the import statement below.
 *
 * Public API:
 *   loadFont()                          → Font  (opentype Font object, cached)
 *   wordmarkPath(text, opts)            → { d, capHeight, width, bbox }
 *   integratedTypemark(text, opts)      → { d, capHeight, width, bbox }
 */

import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

// CJS-safe default import — named exports do not exist in wawoff2's ESM wrapper.
// Always use: import wawoff2 from 'wawoff2'; then wawoff2.decompress(...)
import wawoff2 from 'wawoff2';
import opentype from 'opentype.js';

import { vesicleHoles } from './geometry.mjs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Path to the repo woff2 (relative to this file: ../../assets/fonts/...)
const FONT_PATH = join(__dirname, '../../../assets/fonts/ibm-plex-sans_latest_latin-600-normal.woff2');

// Cached Font instance — decompressed once per process
let _font = null;

/**
 * Load and cache the IBM Plex Sans SemiBold font.
 * Decompresses the repo woff2 via wawoff2, parses with opentype.js.
 *
 * @returns {Promise<import('opentype.js').Font>}
 * @throws {Error} if the font file is missing
 */
async function loadFont() {
  if (_font) return _font;

  let woff2Buf;
  try {
    woff2Buf = readFileSync(FONT_PATH);
  } catch (err) {
    throw new Error(
      `wordmark.mjs: font file not found at ${FONT_PATH}\n` +
      `Expected ibm-plex-sans_latest_latin-600-normal.woff2 in assets/fonts/.\n` +
      `Original error: ${err.message}`
    );
  }

  // wawoff2.decompress returns a Promise<Uint8Array> (TTF bytes)
  const ttfBuf = await wawoff2.decompress(woff2Buf);

  // opentype.js 1.x parse() expects an ArrayBuffer
  const ab = ttfBuf.buffer.slice(ttfBuf.byteOffset, ttfBuf.byteOffset + ttfBuf.byteLength);
  _font = opentype.parse(ab);
  return _font;
}

/**
 * Round to ≤2 decimal places.
 * @param {number} x
 * @returns {number}
 */
function r2(x) {
  return Math.round(x * 100) / 100;
}

/**
 * Stringify an opentype Path to an SVG d string, rounding all coordinates
 * to ≤2 decimals.
 *
 * @param {import('opentype.js').Path} path
 * @returns {string}
 */
function pathToD(path) {
  const parts = [];
  for (const cmd of path.commands) {
    switch (cmd.type) {
      case 'M':
        parts.push(`M${r2(cmd.x)},${r2(cmd.y)}`);
        break;
      case 'L':
        parts.push(`L${r2(cmd.x)},${r2(cmd.y)}`);
        break;
      case 'C':
        parts.push(`C${r2(cmd.x1)},${r2(cmd.y1)},${r2(cmd.x2)},${r2(cmd.y2)},${r2(cmd.x)},${r2(cmd.y)}`);
        break;
      case 'Q':
        parts.push(`Q${r2(cmd.x1)},${r2(cmd.y1)},${r2(cmd.x)},${r2(cmd.y)}`);
        break;
      case 'Z':
        parts.push('Z');
        break;
    }
  }
  return parts.join('');
}

/**
 * Apply letter-spacing (tracking) to a text string, given the font and size.
 * Returns array of {glyph, x} for each character.
 *
 * @param {import('opentype.js').Font} font
 * @param {string} text
 * @param {number} fontSize
 * @param {number} tracking  Fractional letter-spacing offset per em (e.g. -0.01 = -1%)
 * @returns {Array<{glyph: object, x: number}>}
 */
function glyphPositions(font, text, fontSize, tracking) {
  const scale = fontSize / font.unitsPerEm;
  const trackingPx = tracking * fontSize;
  let x = 0;
  const positions = [];
  for (const char of text) {
    const glyph = font.charToGlyph(char);
    positions.push({ glyph, x });
    x += (glyph.advanceWidth * scale) + trackingPx;
  }
  return positions;
}

/**
 * Outline a text string to a single compound SVG path d string.
 * Applies tracking and returns the outlined path plus measurements.
 *
 * @param {string} text           The text to outline (e.g. "Scoria")
 * @param {object} [opts]
 * @param {number} [opts.fontSize=100]  Font size in user units
 * @param {number} [opts.tracking=0]    Letter-spacing as fraction of em (-0.01 to 0)
 * @param {number} [opts.x=0]           Left origin
 * @param {number} [opts.y=0]           Baseline y
 * @returns {Promise<{d:string, capHeight:number, width:number, bbox:object}>}
 */
async function wordmarkPath(text, { fontSize = 100, tracking = 0, x = 0, y = 0 } = {}) {
  const font = await loadFont();
  const scale = fontSize / font.unitsPerEm;
  const capHeight = r2((font.tables?.os2?.sCapHeight ?? 700) * scale);
  const positions = glyphPositions(font, text, fontSize, tracking);

  // Collect all glyph paths into a single compound d string
  let d = '';
  for (const { glyph, x: gx } of positions) {
    const glyphPath = glyph.getPath(x + gx, y, fontSize);
    const glyphD = pathToD(glyphPath);
    if (glyphD) d += glyphD;
  }

  // Compute total width (last glyph x + its advance)
  const last = positions[positions.length - 1];
  const lastAdv = r2(last.glyph.advanceWidth * scale);
  const width = r2(last.x + lastAdv);

  // Compute bbox by scanning the combined path
  // (simple bbox from positions)
  const firstPath = positions[0].glyph.getPath(x, y, fontSize);
  const lastPath = last.glyph.getPath(x + last.x, y, fontSize);
  const firstBB = firstPath.getBoundingBox();
  const lastBB = lastPath.getBoundingBox();

  const bbox = {
    x1: r2(firstBB.x1),
    y1: r2(Math.min(firstBB.y1, lastBB.y1)),
    x2: r2(x + width),
    y2: r2(Math.max(firstBB.y2, lastBB.y2)),
  };

  return { d, capHeight, width, bbox };
}

/**
 * Produce a wordmark path where the 'o' glyph is replaced by a vesicle-ring
 * form. The ring's outer diameter matches the 'o' x-height, its advance width
 * is preserved so kerning is undisturbed, and its ring weight ≈ the 'S' stem
 * width (estimated as ~12% of fontSize for IBM Plex Sans SemiBold 600).
 *
 * The 'o' is located at character index 2 in "Scoria" (0-indexed: S=0 c=1 o=2).
 *
 * @param {string} text  The text (expected to contain 'o')
 * @param {object} [opts]
 * @param {number} [opts.fontSize=100]
 * @param {number} [opts.tracking=0]
 * @param {number} [opts.x=0]
 * @param {number} [opts.y=0]
 * @param {boolean} [opts.oReplacement=true]  Set false to skip replacement
 * @returns {Promise<{d:string, capHeight:number, width:number, bbox:object}>}
 */
async function integratedTypemark(text, { fontSize = 100, tracking = 0, x = 0, y = 0, oReplacement = true } = {}) {
  const font = await loadFont();
  const scale = fontSize / font.unitsPerEm;
  const capHeight = r2((font.tables?.os2?.sCapHeight ?? 700) * scale);
  const positions = glyphPositions(font, text, fontSize, tracking);

  // Find the 'o' character index
  const oIdx = text.indexOf('o');

  let d = '';
  for (let i = 0; i < positions.length; i++) {
    const { glyph, x: gx } = positions[i];
    const absX = x + gx;
    const char = text[i];

    if (oReplacement && char === 'o' && oIdx !== -1) {
      // Replace 'o' with a vesicle-ring form
      // The 'o' bbox in font units: x1=39 y1=-12 x2=524 y2=534 (at 1000 upem)
      // x-height at current scale = sXHeight or approx from 'o' glyph
      const oGlyph = glyph;
      const oBB = oGlyph.getPath(absX, y, fontSize).getBoundingBox();
      const oWidth = r2(oBB.x2 - oBB.x1);
      const oHeight = r2(Math.abs(oBB.y2 - oBB.y1));

      // Ring center: middle of the original 'o' bounding box
      const ringCx = r2(oBB.x1 + oWidth / 2);
      const ringCy = r2(oBB.y1 + oHeight / 2);

      // Outer radius = half the smaller of oWidth/oHeight (keep circular)
      const outerR = r2(Math.min(oWidth, oHeight) / 2);

      // Ring weight ≈ 12% of fontSize (matches ~'S' stem weight at SemiBold 600)
      // IBM Plex Sans 600 stem width ≈ 12% of em
      const ringWeight = r2(fontSize * 0.12);
      const innerR = r2(Math.max(outerR - ringWeight, outerR * 0.35));

      // Generate outer circle and inner circle as evenodd compound path
      const ringD = vesicleHoles([
        { cx: ringCx, cy: ringCy, r: outerR },
      ]) + vesicleHoles([
        { cx: ringCx, cy: ringCy, r: innerR },
      ]);

      // Use the ring sub-paths
      d += ringD;
    } else {
      const glyphPath = glyph.getPath(absX, y, fontSize);
      const glyphD = pathToD(glyphPath);
      if (glyphD) d += glyphD;
    }
  }

  // Compute total width
  const last = positions[positions.length - 1];
  const lastAdv = r2(last.glyph.advanceWidth * scale);
  const width = r2(last.x + lastAdv);

  const bbox = { x1: x, y1: r2(y - capHeight), x2: r2(x + width), y2: r2(y + capHeight * 0.2) };

  return { d, capHeight, width, bbox };
}

export { loadFont, wordmarkPath, integratedTypemark };
