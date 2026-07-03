/**
 * priv/dev/e2e/lib/boxes_intersect.mjs — shared bounding-box intersection
 * primitive (D-17).
 *
 * The SOLE geometry helper for axis-aligned rectangle overlap checks used by
 * BOTH occlusion checks this phase needs:
 *   - the drawer focus spec (dynamic SC 2.4.11 occlusion — a focused element
 *     hidden behind the sticky approval action footer)
 *   - the responsive scan (static toast/nav occlusion — D-16(5))
 * Neither spec re-derives its own intersection math; both import this
 * module. Dependency-free beyond the DOMRect-like input shape.
 *
 * Dev-only — never shipped to Hex (priv/dev is excluded from mix.exs
 * package.files).
 */

/**
 * Axis-aligned overlap test over DOMRect-like `{top,right,bottom,left}`
 * objects (matches the shape returned by `Element.getBoundingClientRect()`
 * when destructured/serialized across the Playwright page boundary).
 *
 * A small 1px tolerance is applied so boxes that merely touch at an edge
 * (e.g. a sticky footer whose top edge is exactly flush with a focused
 * element's bottom edge) are NOT reported as overlapping — consistent with
 * the 1px idiom already used elsewhere in this harness (e.g.
 * `phase16_parity.spec.mjs`'s overflow tolerance).
 *
 * @param {{top: number, right: number, bottom: number, left: number}} a
 * @param {{top: number, right: number, bottom: number, left: number}} b
 * @param {number} [tolerance=1] pixel tolerance for edge-touching boxes
 * @returns {boolean} true if the two rects overlap by more than `tolerance`
 */
export function boxesIntersect(a, b, tolerance = 1) {
  const horizontalOverlap = a.left < b.right - tolerance && b.left < a.right - tolerance;
  const verticalOverlap = a.top < b.bottom - tolerance && b.top < a.bottom - tolerance;
  return horizontalOverlap && verticalOverlap;
}
