#!/usr/bin/env node
/**
 * converge.mjs — Phase 20 convergence writer.
 *
 * Emits the 8 canonical ROOT logo variants to brandbook/ root from the frozen
 * gate-#2 artwork (LK-B fused lockup + TV-1 mark/favicon). Geometry is FROZEN —
 * the composers in lib/root-variants.mjs only recolor / substitute currentColor /
 * tighten viewBoxes / snap the favicon / add outlined tagline text.
 *
 * Usage: node brandbook/tools/converge.mjs
 *        (or: cd brandbook/tools && node converge.mjs)
 *
 * Exits 0 after writing all 8 files; prints a count.
 *
 * NOTE: main() is async and AWAITS each builder — logoLockupSubtitle and
 * socialCard call the async wordmarkPath() to outline the tagline. Forgetting
 * the await would write "[object Promise]" as file content.
 */

import { writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

import {
  logoPrimary,
  logoPrimaryLight,
  logoMark,
  logoMonochrome,
  logoLockupSubtitle,
  logotypeIntegrated,
  favicon,
  socialCard,
} from './lib/root-variants.mjs';

const __dir = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dir, '..'); // brandbook/

// [filename, builderFn] — builders may be sync or async; main() awaits each.
const builders = [
  ['logo-primary.svg', logoPrimary],
  ['logo-primary-light.svg', logoPrimaryLight],
  ['logo-mark.svg', logoMark],
  ['logo-monochrome.svg', logoMonochrome],
  ['logo-lockup-subtitle.svg', logoLockupSubtitle],
  ['logotype-integrated.svg', logotypeIntegrated],
  ['favicon.svg', favicon],
  ['social-card.svg', socialCard],
];

async function main() {
  let n = 0;
  for (const [name, fn] of builders) {
    const svg = await fn(); // MUST await — subtitle/social builders are async.
    if (typeof svg !== 'string' || svg.includes('[object Promise]')) {
      throw new Error(`converge.mjs: builder for ${name} did not return a string (missing await?)`);
    }
    writeFileSync(join(ROOT, name), svg + '\n', 'utf8');
    n++;
  }
  console.log(`converge.mjs: wrote ${n} root variant SVG(s) to brandbook/`);
}

main().catch((err) => {
  console.error('converge.mjs failed:', err);
  process.exit(1);
});
