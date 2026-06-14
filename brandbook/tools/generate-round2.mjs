#!/usr/bin/env node
/**
 * generate-round2.mjs — Second-round lockup/typemark candidate generator (19-02b)
 *
 * Gate #2 escape (#2): TV-1 "Span rail" is the LOCKED direction; the round needed
 * is divergence in the MARK↔WORDMARK RELATIONSHIP (not a new mark), and the two
 * integrated typemarks (TYPE-1 ring 'o', TYPE-2 porous 'a') were rejected.
 *
 * Writes LK-A..LK-F candidates into candidates/ (alongside the round-1 files,
 * which stay for reference). Each LK-* is built on the LOCKED TV-1 geometry;
 * LK-B applies one documented optical micro-tune (root hole) for ink-density
 * matching at glyph scale.
 *
 * Output (in brandbook/tools/candidates/):
 *   LK-A-lockup.svg   classic tight (baseline reference)
 *   LK-B-lockup.svg   mark-as-o (integrated; mark becomes the 'o')
 *   LK-C-lockup.svg   stacked (vertical lockup)
 *   LK-D-lockup.svg   overlap (mark notches the S)
 *   LK-E-lockup.svg   counter-punch (trace tree through the S)
 *   LK-F-lockup.svg   mark-as-tittle (mark replaces the i dot)
 *
 * Exits 0; prints a count.
 */

import { writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

import {
  classicTight, markAsO, stacked, overlap, counterPunch, markAsDot,
} from './lib/lockup-variants.mjs';

const __dir = dirname(fileURLToPath(import.meta.url));
const CANDIDATES = join(__dir, 'candidates');

const builders = [
  ['LK-A-lockup.svg', classicTight],
  ['LK-B-lockup.svg', markAsO],
  ['LK-C-lockup.svg', stacked],
  ['LK-D-lockup.svg', overlap],
  ['LK-E-lockup.svg', counterPunch],
  ['LK-F-lockup.svg', markAsDot],
];

async function main() {
  let n = 0;
  for (const [name, fn] of builders) {
    const svg = await fn();
    writeFileSync(join(CANDIDATES, name), svg + '\n', 'utf8');
    n++;
  }
  console.log(`generate-round2.mjs: wrote ${n} second-round lockup SVG(s) to candidates/`);
}

main().catch((err) => {
  console.error('generate-round2.mjs failed:', err);
  process.exit(1);
});
