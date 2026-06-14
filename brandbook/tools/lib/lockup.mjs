/**
 * lockup.mjs — Mark + wordmark lockup composer
 *
 * Enforces LOGO-03: gap between mark and wordmark = 0.35–0.5× cap height.
 * Optically aligns baselines. Emits a tight viewBox over both elements.
 *
 * The lockup SVG root carries `data-gap-ratio="<gap/capHeight, 2 decimals>"`
 * for machine-checkable LOGO-03 compliance (asserted by smoke.mjs and 19-03).
 *
 * Public API:
 *   composeLockup(opts) → string  (SVG string)
 */

import { combinedViewBox } from './svg.mjs';
import { pathBBox } from './geometry.mjs';

/**
 * Round to ≤2 decimal places.
 * @param {number} x
 * @returns {number}
 */
function r2(x) {
  return Math.round(x * 100) / 100;
}

/**
 * Compute a tight viewBox from two bounding boxes plus a transform offset.
 * @param {{minX,minY,maxX,maxY}} markBB  Already-translated
 * @param {{minX,minY,maxX,maxY}} wmBB    Already-translated
 * @param {number} [pad=1]
 * @returns {string}
 */
function bboxToViewBox(markBB, wmBB, pad = 1) {
  const minX = Math.min(markBB.minX, wmBB.minX);
  const minY = Math.min(markBB.minY, wmBB.minY);
  const maxX = Math.max(markBB.maxX, wmBB.maxX);
  const maxY = Math.max(markBB.maxY, wmBB.maxY);
  const x = r2(minX - pad);
  const y = r2(minY - pad);
  const w = r2(maxX - minX + pad * 2);
  const h = r2(maxY - minY + pad * 2);
  return `${x} ${y} ${w} ${h}`;
}

/**
 * Offset a path d string by (dx, dy) by prepending a translate transform.
 * We do this via a <g transform="translate(...)"> wrapper rather than
 * rewriting coordinates, since the lockup positions both elements.
 *
 * @param {string} d
 * @param {number} dx
 * @param {number} dy
 * @returns {string}  SVG <path> element string with transform
 */
function pathElementWithOffset(d, dx, dy, fill, fillRule) {
  const transform = (dx !== 0 || dy !== 0) ? ` transform="translate(${r2(dx)},${r2(dy)})"` : '';
  return `<path fill="${fill}" fill-rule="${fillRule}" d="${d}"${transform}/>`;
}

/**
 * Compose a mark + wordmark lockup SVG.
 *
 * The mark is placed left of the wordmark. Gap enforces LOGO-03:
 * gap = clamp(0.35, 0.5) × capHeight.
 *
 * Both mark and wordmark are placed with optical baseline alignment:
 * the wordmark baseline (y=0 when rendered) aligns with the mark's
 * visual center-of-mass (approximate: vertically centered in the mark bbox).
 *
 * @param {object} opts
 * @param {string}  opts.markD        Mark compound path d string (centered near 0,0)
 * @param {{minX,minY,maxX,maxY}} opts.markBox   Mark bbox (from pathBBox)
 * @param {string}  opts.wordmarkD    Wordmark path d string
 * @param {object}  opts.wordmarkBbox Wordmark bbox {x1,y1,x2,y2}
 * @param {number}  opts.capHeight    Cap height in wordmark user units
 * @param {string}  [opts.fill='currentColor']
 * @param {string}  [opts.markFill]   Override mark fill (defaults to fill)
 * @param {string}  [opts.title='Scoria']
 * @param {number}  [opts.gapRatio]   Override gap ratio (default 0.4, clamped to [0.35,0.5])
 * @returns {string}  SVG lockup string
 */
function composeLockup({
  markD,
  markBox,
  wordmarkD,
  wordmarkBbox,
  capHeight,
  fill = 'currentColor',
  markFill,
  title = 'Scoria',
  gapRatio,
} = {}) {
  const mFill = markFill ?? fill;

  // LOGO-03: gap = clamp(0.35, 0.5) × capHeight
  const rawRatio = gapRatio ?? 0.4;
  const clampedRatio = Math.max(0.35, Math.min(0.5, rawRatio));
  const gap = r2(clampedRatio * capHeight);
  const dataGapRatio = r2(clampedRatio);

  // Mark dimensions
  const markWidth = r2(markBox.maxX - markBox.minX);
  const markHeight = r2(markBox.maxY - markBox.minY);

  // Wordmark dimensions
  const wmWidth = r2(wordmarkBbox.x2 - wordmarkBbox.x1);
  const wmHeight = r2(Math.abs(wordmarkBbox.y2 - wordmarkBbox.y1));

  // Scale mark to match wordmark cap height
  // Mark height → cap height (so the mark's visual height equals the cap height)
  const markScale = r2(capHeight / markHeight);
  const scaledMarkWidth = r2(markWidth * markScale);

  // Position mark: translate so its scaled bbox starts at (0, 0) top
  // (we'll use transform="scale + translate" on a group)
  // Mark is centered near origin; we place it at (0, 0) top-left
  const markGroupTransform =
    `translate(${r2(-markBox.minX * markScale)},${r2(-markBox.minY * markScale)}) scale(${markScale})`;

  // Wordmark position: immediately to the right of mark + gap
  // Wordmark baseline: align to mark optical center
  // Mark cap height top is at y=0 after transform; bottom at y=capHeight
  // Wordmark baseline: place so ascenders align with mark top
  // wordmark y coords: y1 is ascender (negative), y=0 is baseline
  // We want wordmark top (y1, ascender) to align near mark top (y=0)
  // So wordmark translate y = -wordmarkBbox.y1 (moves baseline up to put cap at y=0)
  const wmX = r2(scaledMarkWidth + gap - wordmarkBbox.x1);
  const wmY = r2(-wordmarkBbox.y1);  // Aligns wordmark cap-top to mark top

  // Compute translated bboxes for viewBox
  // Mark bbox after scaling and translating:
  const tMarkBB = {
    minX: 0,
    minY: 0,
    maxX: r2(scaledMarkWidth),
    maxY: r2(markHeight * markScale),
  };
  // Wordmark bbox after translating:
  const tWmBB = {
    minX: r2(scaledMarkWidth + gap),
    minY: r2(wordmarkBbox.y1 + wmY),
    maxX: r2(scaledMarkWidth + gap + wmWidth),
    maxY: r2(wordmarkBbox.y2 + wmY),
  };

  const viewBox = bboxToViewBox(tMarkBB, tWmBB, 1);

  return [
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${viewBox}" role="img" aria-label="${title}" data-gap-ratio="${dataGapRatio}">`,
    `  <title>${title}</title>`,
    `  <g transform="${markGroupTransform}">`,
    `    <path fill="${mFill}" fill-rule="evenodd" d="${markD}"/>`,
    `  </g>`,
    `  <path fill="${fill}" fill-rule="evenodd" d="${wordmarkD}" transform="translate(${r2(wmX)},${r2(wmY)})"/>`,
    `</svg>`,
  ].join('\n');
}

export { composeLockup };
