/**
 * priv/dev/contact_sheet.mjs — Scoria before/after contact-sheet generator
 *
 * Reads dated PNG capture dirs and emits an HTML grid for visual before/after
 * comparison. Gitignored output; committed generator.
 *
 * Usage:
 *   node priv/dev/contact_sheet.mjs \
 *     --before priv/shots/2026-06-04 \
 *     --after priv/shots/<final-date> \
 *     --out priv/shots/contact_sheet.html
 *
 * No Playwright dependency — plain Node.js fs/path only.
 */

import { readdir, writeFile } from 'fs/promises';
import { existsSync } from 'fs';
import { join, relative, dirname } from 'path';
import { fileURLToPath } from 'url';

// ---------------------------------------------------------------------------
// Arg parsing
// ---------------------------------------------------------------------------

function parseArgs(argv) {
  const args = argv.slice(2);
  const result = {
    before: null,
    after: null,
    out: 'priv/shots/contact_sheet.html',
  };

  for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--before':
        result.before = args[++i];
        break;
      case '--after':
        result.after = args[++i];
        break;
      case '--out':
        result.out = args[++i];
        break;
      default:
        console.error(`Unknown argument: ${args[i]}`);
        process.exit(1);
    }
  }

  if (!result.before || !result.after) {
    console.error('Error: --before and --after are required');
    process.exit(1);
  }

  return result;
}

// ---------------------------------------------------------------------------
// Screen manifest (mirrors priv/dev/shots.mjs SCREENS)
// tenantScoped: false means only populated_* pairs exist (no empty_* captures)
// ---------------------------------------------------------------------------

const SCREENS = [
  { name: 'live_ops', tenantScoped: true },
  { name: 'approvals', tenantScoped: true },
  { name: 'workflows', tenantScoped: false },
  { name: 'incidents', tenantScoped: true },
  { name: 'connectors', tenantScoped: true },
  { name: 'reviews', tenantScoped: false },
  { name: 'eval_specs', tenantScoped: false },
  { name: 'prompts', tenantScoped: false },
  { name: 'prompt_release', tenantScoped: false },
];

// ---------------------------------------------------------------------------
// PNG discovery — lists all .png files in a screen subdir (if it exists)
// ---------------------------------------------------------------------------

async function listScreenPngs(dir, screenName) {
  const screenDir = join(dir, screenName);
  if (!existsSync(screenDir)) {
    return [];
  }
  let entries;
  try {
    entries = await readdir(screenDir);
  } catch {
    return [];
  }
  return entries.filter((f) => f.endsWith('.png')).sort();
}

// ---------------------------------------------------------------------------
// HTML generation helpers
// ---------------------------------------------------------------------------

function relPath(outFile, targetFile) {
  return relative(dirname(outFile), targetFile).replace(/\\/g, '/');
}

function renderPairRow(filename, beforeFile, afterFile, outPath, isBaseline, isAfterMissing) {
  const beforeSrc = beforeFile ? relPath(outPath, beforeFile) : null;
  const afterSrc = afterFile ? relPath(outPath, afterFile) : null;

  const beforeCell = beforeSrc
    ? `<img src="${beforeSrc}" alt="Before: ${filename}" loading="lazy" />`
    : `<div class="placeholder">not captured</div>`;

  const afterCell = afterSrc
    ? `<img src="${afterSrc}" alt="After: ${filename}" loading="lazy" />`
    : isAfterMissing
    ? `<div class="placeholder missing">not re-captured<br><small>(screen missing from final dir)</small></div>`
    : `<div class="placeholder">not captured</div>`;

  return `
      <tr>
        <td class="filename">${filename}</td>
        <td class="img-cell">${beforeCell}</td>
        <td class="img-cell">${afterCell}</td>
      </tr>`;
}

function renderScreenSection(screenName, pairs, tenantScoped, afterDirMissing, outPath) {
  const note = !tenantScoped
    ? '<p class="note">Non-tenant-scoped screen: only <code>populated_*</code> captures exist (no <code>empty_*</code> pairs).</p>'
    : '';

  const missingBanner = afterDirMissing
    ? '<p class="warning">Screen directory missing from the final (--after) dir — not re-captured. Baseline-only rows shown.</p>'
    : '';

  const rows = pairs.map(({ filename, beforePath, afterPath, afterMissing }) =>
    renderPairRow(filename, beforePath, afterPath, outPath, false, afterMissing)
  ).join('');

  return `
    <section class="screen" id="${screenName}">
      <h2>${screenName}</h2>
      ${note}${missingBanner}
      <table>
        <thead>
          <tr>
            <th class="filename">File</th>
            <th>Before (baseline)</th>
            <th>After (final)</th>
          </tr>
        </thead>
        <tbody>${rows}
        </tbody>
      </table>
    </section>`;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  const args = parseArgs(process.argv);
  const { before, after, out } = args;

  if (!existsSync(before)) {
    console.error(`Error: --before dir does not exist: ${before}`);
    process.exit(1);
  }
  if (!existsSync(after)) {
    console.error(`Error: --after dir does not exist: ${after}`);
    process.exit(1);
  }

  console.log(`Contact sheet generator`);
  console.log(`  --before  ${before}`);
  console.log(`  --after   ${after}`);
  console.log(`  --out     ${out}`);
  console.log('');

  const sections = [];
  let totalPaired = 0;
  let totalBeforeOnly = 0;

  for (const screen of SCREENS) {
    const beforePngs = await listScreenPngs(before, screen.name);
    const afterPngs = await listScreenPngs(after, screen.name);

    const afterDirMissing = !existsSync(join(after, screen.name));

    const afterSet = new Set(afterPngs);
    const beforeSet = new Set(beforePngs);

    // Build the union of all filenames from both dirs
    const allFilenames = [...new Set([...beforePngs, ...afterPngs])].sort();

    const pairs = [];

    for (const filename of allFilenames) {
      // Skip empty_* files for non-tenant-scoped screens (they don't exist by design)
      if (!screen.tenantScoped && filename.startsWith('empty_')) {
        continue;
      }

      const beforePath = beforeSet.has(filename) ? join(before, screen.name, filename) : null;
      const afterPath = afterSet.has(filename) ? join(after, screen.name, filename) : null;
      const afterMissing = afterDirMissing || (!afterSet.has(filename) && beforeSet.has(filename));

      if (beforePath && afterPath) {
        totalPaired++;
      } else if (beforePath && !afterPath) {
        totalBeforeOnly++;
      }

      pairs.push({ filename, beforePath, afterPath, afterMissing });
    }

    const status = afterDirMissing
      ? 'MISSING from final dir'
      : `${pairs.filter((p) => p.beforePath && p.afterPath).length} paired`;

    console.log(`  ${screen.name}: ${beforePngs.length} before / ${afterPngs.length} after — ${status}`);

    sections.push(renderScreenSection(screen.name, pairs, screen.tenantScoped, afterDirMissing, out));
  }

  console.log('');
  console.log(`  Paired: ${totalPaired} | Baseline-only (not re-captured): ${totalBeforeOnly}`);

  const beforeLabel = before;
  const afterLabel = after;
  const generated = new Date().toISOString().slice(0, 10);

  const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Scoria v3.0 Control Room — Before/After Contact Sheet</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: system-ui, -apple-system, sans-serif;
      font-size: 14px;
      background: #1a1a1a;
      color: #e5e5e5;
      padding: 2rem;
    }
    header { margin-bottom: 2rem; }
    header h1 { font-size: 1.5rem; font-weight: 600; margin-bottom: 0.5rem; }
    header p { color: #aaa; font-size: 0.875rem; }
    header p + p { margin-top: 0.25rem; }
    nav { margin-bottom: 2rem; }
    nav a { color: #60a5fa; margin-right: 1rem; text-decoration: none; font-size: 0.875rem; }
    nav a:hover { text-decoration: underline; }
    .screen { margin-bottom: 3rem; }
    .screen h2 {
      font-size: 1.125rem;
      font-weight: 600;
      margin-bottom: 0.75rem;
      padding-bottom: 0.5rem;
      border-bottom: 1px solid #333;
    }
    .note, .warning {
      font-size: 0.8125rem;
      margin-bottom: 0.75rem;
      padding: 0.5rem 0.75rem;
      border-radius: 4px;
    }
    .note { background: #1e3a5f; color: #93c5fd; }
    .warning { background: #4c1d1d; color: #fca5a5; }
    table {
      width: 100%;
      border-collapse: collapse;
      table-layout: fixed;
    }
    th, td {
      padding: 0.5rem;
      border: 1px solid #333;
      vertical-align: top;
    }
    th {
      background: #262626;
      font-weight: 600;
      font-size: 0.8125rem;
      text-align: left;
    }
    th.filename, td.filename {
      width: 18rem;
      font-family: monospace;
      font-size: 0.8125rem;
      color: #aaa;
      word-break: break-all;
    }
    td.img-cell { width: calc((100% - 18rem) / 2); }
    img {
      display: block;
      width: 100%;
      height: auto;
      border-radius: 2px;
    }
    .placeholder {
      display: flex;
      align-items: center;
      justify-content: center;
      flex-direction: column;
      min-height: 6rem;
      font-size: 0.8125rem;
      color: #666;
      background: #222;
      border-radius: 2px;
      text-align: center;
      gap: 0.25rem;
    }
    .placeholder.missing { color: #f87171; background: #2a1515; }
    small { font-size: 0.75em; }
  </style>
</head>
<body>
  <header>
    <h1>Scoria v3.0 Control Room — Before/After Contact Sheet</h1>
    <p><strong>Baseline dir:</strong> ${beforeLabel}</p>
    <p><strong>Final dir:</strong> ${afterLabel}</p>
    <p><strong>Generated:</strong> ${generated}</p>
    <p><strong>Paired PNG files:</strong> ${totalPaired} | <strong>Baseline-only (not re-captured):</strong> ${totalBeforeOnly}</p>
  </header>
  <nav>
    ${SCREENS.map((s) => `<a href="#${s.name}">${s.name}</a>`).join('\n    ')}
  </nav>
  ${sections.join('\n  ')}
</body>
</html>
`;

  await writeFile(out, html, 'utf8');
  console.log(`\nWrote: ${out}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
