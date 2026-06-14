/**
 * svg.mjs — SVG document builder
 *
 * Builds a minimal, accessibility-correct SVG string with:
 *   - viewBox hugging the artwork (computed from path bbox, no padding container)
 *   - role="img" + <title> for screen readers
 *   - exactly one <path fill-rule="evenodd">
 *   - fill="currentColor" by default (monochrome-safe)
 *   - NO <rect>, NO stroke
 *
 * Public API:
 *   svgDocument(opts) → string
 *   svgLockupDocument(opts) → string  (two paths: mark + wordmark)
 */

import { pathBBox } from './geometry.mjs';

/**
 * Compute a tight viewBox string from a path d string.
 * Adds 1px padding on all sides so curves don't clip at exact extents.
 *
 * @param {string} d  Path d string
 * @param {number} [pad=1]  Padding in user units
 * @returns {string}  "minX minY width height"
 */
function tightViewBox(d, pad = 1) {
  const { minX, minY, maxX, maxY } = pathBBox(d);
  const x = Math.round((minX - pad) * 100) / 100;
  const y = Math.round((minY - pad) * 100) / 100;
  const w = Math.round((maxX - minX + pad * 2) * 100) / 100;
  const h = Math.round((maxY - minY + pad * 2) * 100) / 100;
  return `${x} ${y} ${w} ${h}`;
}

/**
 * Compute a tight viewBox from two paths combined.
 *
 * @param {string} d1
 * @param {string} d2
 * @param {number} [pad=1]
 * @returns {string}
 */
function combinedViewBox(d1, d2, pad = 1) {
  const b1 = pathBBox(d1);
  const b2 = pathBBox(d2);
  const minX = Math.min(b1.minX, b2.minX);
  const minY = Math.min(b1.minY, b2.minY);
  const maxX = Math.max(b1.maxX, b2.maxX);
  const maxY = Math.max(b1.maxY, b2.maxY);
  const x = Math.round((minX - pad) * 100) / 100;
  const y = Math.round((minY - pad) * 100) / 100;
  const w = Math.round((maxX - minX + pad * 2) * 100) / 100;
  const h = Math.round((maxY - minY + pad * 2) * 100) / 100;
  return `${x} ${y} ${w} ${h}`;
}

/**
 * Build a single-path SVG document for a mark.
 *
 * @param {object} opts
 * @param {string}  opts.pathD       The compound path d string
 * @param {string}  [opts.fillRule='evenodd']
 * @param {string}  [opts.fill='currentColor']
 * @param {string}  [opts.viewBox]   Override; computed from pathD if omitted
 * @param {string}  [opts.title='Scoria mark']
 * @param {string}  [opts.id]        Optional id on the <path>
 * @param {number}  [opts.pad=1]     viewBox padding
 * @returns {string}
 */
function svgDocument({
  pathD,
  fillRule = 'evenodd',
  fill = 'currentColor',
  viewBox,
  title = 'Scoria mark',
  id,
  pad = 1,
} = {}) {
  const vb = viewBox ?? tightViewBox(pathD, pad);
  const pathId = id ? ` id="${id}"` : '';
  return [
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${vb}" role="img" aria-label="${title}">`,
    `  <title>${title}</title>`,
    `  <path${pathId} fill="${fill}" fill-rule="${fillRule}" d="${pathD}"/>`,
    `</svg>`,
  ].join('\n');
}

export { svgDocument, tightViewBox, combinedViewBox };
