/**
 * geometry.mjs — Faceted polygon + vesicle-hole geometry library
 *
 * Produces a single compound SVG path string (outer faceted polygon + punched
 * vesicle holes) using fill-rule="evenodd". Coordinates rounded to ≤2 decimals.
 * All radius variance is LOW-FREQUENCY (smooth, seeded sine sequence) — not
 * independent random jitter per anchor.
 *
 * Public API:
 *   facetedPolygon(opts) → string  (outer polygon path d)
 *   vesicleHoles(holes)  → string  (hole sub-paths d)
 *   markPath(preset)     → string  (compound outer + holes d)
 */

/** Round to ≤2 decimal places, strip trailing zeros. */
function r2(x) {
  return Math.round(x * 100) / 100;
}

/**
 * Low-frequency radius perturbation via a seeded sine sequence.
 * Returns an array of per-anchor radius scale factors in [1-variance, 1+variance].
 * "Low-frequency" = only 1–2 full sine cycles across all anchors so adjacent
 * radii vary smoothly (no independent random jitter).
 *
 * @param {number} n       Number of anchors
 * @param {number} variance  Fractional radius variance, e.g. 0.15 = ±15%
 * @param {number} seed    Integer seed for phase offset
 * @returns {number[]}
 */
function lowFreqRadii(n, variance, seed) {
  // 1.5 cycles across all anchors gives smooth, slightly irregular shape
  const freq = 1.5;
  const phase = (seed % 100) / 100 * Math.PI * 2;
  return Array.from({ length: n }, (_, i) => {
    const t = (i / n) * Math.PI * 2 * freq + phase;
    return 1 + variance * Math.sin(t);
  });
}

/**
 * Shorten a segment endpoint toward the other end by `amount` units.
 * Used for corner-rounding: pull back from each vertex along each incident edge.
 */
function pullBack(ax, ay, bx, by, amount) {
  const dx = bx - ax;
  const dy = by - ay;
  const len = Math.hypot(dx, dy);
  if (len < 1e-9) return [ax, ay];
  const t = amount / len;
  return [ax + dx * t, ay + dy * t];
}

/**
 * Build a closed rounded polygon with low-frequency radius perturbation.
 *
 * @param {object} opts
 * @param {number}   opts.anchors       Number of anchor vertices (6–8)
 * @param {number}   opts.baseRadius    Radius of the base circle (default 50)
 * @param {number}   opts.radiusVariance  Fractional ±variance (0.12–0.18)
 * @param {number}   opts.flatFacets    Number of anchors that get no rounding (0–2)
 * @param {number}   opts.rounding      Corner pull-back distance (default 6)
 * @param {number}   opts.seed          Deterministic seed integer
 * @param {number}   [opts.cx=0]        Center x
 * @param {number}   [opts.cy=0]        Center y
 * @returns {string}  SVG path d string (closed, no fill-rule attr — caller sets that)
 */
function facetedPolygon({
  anchors = 7,
  baseRadius = 50,
  radiusVariance = 0.15,
  flatFacets = 1,
  rounding = 6,
  seed = 1,
  cx = 0,
  cy = 0,
} = {}) {
  const n = anchors;
  const radii = lowFreqRadii(n, radiusVariance, seed);

  // Compute polygon vertices (angle starts at -90° = top)
  const pts = Array.from({ length: n }, (_, i) => {
    const angle = (i / n) * Math.PI * 2 - Math.PI / 2;
    const rad = baseRadius * radii[i];
    return [r2(cx + rad * Math.cos(angle)), r2(cy + rad * Math.sin(angle))];
  });

  // Identify flat-facet anchor indices (evenly spaced, offset by seed)
  const flatSet = new Set();
  for (let f = 0; f < flatFacets; f++) {
    flatSet.add(Math.round((f / flatFacets + (seed % 7) / 70) * n) % n);
  }

  // Build path with quadratic-curve corner rounding
  // For each vertex: pull back along both incident edges, then draw quadratic
  // from the pulled-back point to the next corner entry point.
  const r = rounding;
  let d = '';

  for (let i = 0; i < n; i++) {
    const [px, py] = pts[(i + n - 1) % n];
    const [ax, ay] = pts[i];
    const [nx, ny] = pts[(i + 1) % n];

    const flat = flatSet.has(i);
    const [ex, ey] = flat ? [ax, ay] : pullBack(ax, ay, px, py, r);  // entry from prev
    const [lx, ly] = flat ? [ax, ay] : pullBack(ax, ay, nx, ny, r);  // leave to next

    if (i === 0) {
      d += `M${r2(ex)},${r2(ey)}`;
    } else {
      // Line from previous leave-point to this entry-point
      d += `L${r2(ex)},${r2(ey)}`;
    }

    if (!flat) {
      // Quadratic curve through the actual vertex
      d += `Q${r2(ax)},${r2(ay)},${r2(lx)},${r2(ly)}`;
    }
  }

  d += 'Z';
  return d;
}

/**
 * Build hole sub-paths for a list of vesicle circles.
 * Each hole is a circle approximated as a closed path (4-bezier arc) so it
 * combines cleanly with the outer polygon in a single compound path string.
 * Returns a d string of concatenated sub-paths (no M preceding call needed).
 *
 * @param {Array<{cx:number, cy:number, r:number, edgeBite?:boolean}>} holes
 * @returns {string}
 */
function vesicleHoles(holes) {
  return holes.map(({ cx, cy, r }) => {
    // Approximate circle with 4 cubic bezier arcs (κ = 0.5523)
    const k = r2(r * 0.5523);
    const rx = r2(cx);
    const ry = r2(cy);
    const rr = r2(r);
    return [
      `M${r2(rx + rr)},${ry}`,
      `C${r2(rx + rr)},${r2(ry - k)},${r2(rx + k)},${r2(ry - rr)},${rx},${r2(ry - rr)}`,
      `C${r2(rx - k)},${r2(ry - rr)},${r2(rx - rr)},${r2(ry - k)},${r2(rx - rr)},${ry}`,
      `C${r2(rx - rr)},${r2(ry + k)},${r2(rx - k)},${r2(ry + rr)},${rx},${r2(ry + rr)}`,
      `C${r2(rx + k)},${r2(ry + rr)},${r2(rx + rr)},${r2(ry + k)},${r2(rx + rr)},${ry}`,
      'Z',
    ].join('');
  }).join('');
}

/**
 * Build a single compound path string: outer faceted polygon + punched vesicle
 * holes (fill-rule="evenodd" makes the holes show through).
 *
 * @param {object} preset
 * @param {number}  preset.anchors
 * @param {number}  [preset.baseRadius=50]
 * @param {number}  preset.radiusVariance
 * @param {number}  preset.flatFacets
 * @param {number}  [preset.rounding=6]
 * @param {number}  preset.seed
 * @param {Array<{cx:number, cy:number, r:number}>} preset.holes
 * @param {number}  [preset.cx=0]
 * @param {number}  [preset.cy=0]
 * @param {boolean} [preset.edgeNotch=false]  Allow one hole to bleed the edge
 * @returns {string}  Single compound path d string
 */
function markPath(preset) {
  const outer = facetedPolygon(preset);
  const holes = preset.holes && preset.holes.length > 0
    ? vesicleHoles(preset.holes)
    : '';
  return outer + holes;
}

/**
 * Compute an approximate bounding box for a path produced by this library.
 * We track all M/L/C/Q/Z numeric coordinates by a simple regex scan.
 * This is sufficient for the paths we generate (no arcs, no H/V shorthands).
 *
 * @param {string} d  Path d string
 * @returns {{minX:number, minY:number, maxX:number, maxY:number}}
 */
function pathBBox(d) {
  const nums = [];
  // Extract all coordinate pairs from M, L, C, Q, Z commands
  const re = /[MLCQZ][^MLCQZ]*/gi;
  let match;
  while ((match = re.exec(d)) !== null) {
    const cmd = match[0][0].toUpperCase();
    if (cmd === 'Z') continue;
    const coords = match[0].slice(1).trim().split(/[\s,]+/).map(Number);
    // All our commands use absolute coords; extract x,y pairs
    for (let i = 0; i + 1 < coords.length; i += 2) {
      nums.push([coords[i], coords[i + 1]]);
    }
  }
  if (nums.length === 0) return { minX: 0, minY: 0, maxX: 0, maxY: 0 };
  let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
  for (const [x, y] of nums) {
    if (x < minX) minX = x;
    if (y < minY) minY = y;
    if (x > maxX) maxX = x;
    if (y > maxY) maxY = y;
  }
  return { minX, minY, maxX, maxY };
}

export { facetedPolygon, vesicleHoles, markPath, pathBBox };
