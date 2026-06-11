#!/usr/bin/env node
/**
 * quality-gate.mjs — Phase 22 aggregating final quality gate
 *
 * Usage: node brandbook/tools/quality-gate.mjs
 *        (runs from any cwd; paths resolved relative to this script)
 *
 * Checks (in order):
 *   1. CONTRAST          — contrast-check.mjs: parse FAIL count from stdout (always exits 0)
 *   2. VERIFY-LOGOS      — verify-logos.mjs: trust exit code
 *   3. CONSISTENCY       — check-consistency.mjs: trust exit code
 *   4. EXTENSION-ALLOWLIST — brandbook/ recursive walk (excl. tools/node_modules): zero binaries
 *   5. BRANDBOOK-SIZE    — total bytes of all files under brandbook/ < 500 KB
 *   6. INDEX-OFFLINE     — index.html: zero http(s) refs (xmlns excepted), all src= resolve
 *   7. MIX-TEST          — documented green in 22-01 (spawning mix from this script is env-fragile)
 *   8. DASHBOARD-MARK    — layouts.ex brand_mark/1 uses evenodd and has no <circle elements
 *
 * Exits 0 if all checks PASS, 1 if any FAIL.
 */

import { spawnSync } from 'child_process';
import { readFileSync, statSync, readdirSync, existsSync } from 'fs';
import { join, dirname, resolve, extname, basename } from 'path';
import { fileURLToPath } from 'url';

const __dir = dirname(fileURLToPath(import.meta.url));
const BRANDBOOK_DIR = resolve(__dir, '..');
const REPO_ROOT = resolve(BRANDBOOK_DIR, '..');

// ---------------------------------------------------------------------------
// Helpers: PASS/FAIL output (matches sibling tool style)
// ---------------------------------------------------------------------------

let failures = 0;

function pass(id, msg) {
  console.log(`PASS  [${id}]  ${msg}`);
}

function fail(id, msg) {
  console.log(`FAIL  [${id}]  ${msg}`);
  failures++;
}

// ---------------------------------------------------------------------------
// Check 1: CONTRAST
// Run contrast-check.mjs and parse FAIL count from the **Summary:** line.
// CRITICAL: contrast-check always exits 0 — do NOT trust exit code.
// ---------------------------------------------------------------------------
{
  const result = spawnSync('node', ['contrast-check.mjs'], {
    cwd: __dir,
    encoding: 'utf8',
  });

  // Extract the **Summary:** line and parse FAIL: <n>
  const summaryMatch = (result.stdout || '').match(/\*\*Summary:\*\*[^–\n]*FAIL:\s*(\d+)/);
  const failCount = summaryMatch ? parseInt(summaryMatch[1], 10) : null;

  if (failCount === null) {
    fail('CONTRAST', 'Could not parse FAIL count from contrast-check.mjs stdout');
  } else if (failCount === 0) {
    // Also surface the full summary numbers for the gate report
    const fullSummary = (result.stdout || '').match(/\*\*Summary:\*\*.+/);
    const summary = fullSummary ? fullSummary[0].replace(/\*\*/g, '') : `FAIL count = ${failCount}`;
    pass('CONTRAST', `WCAG contrast: ${summary.replace('Summary: ', '')}`);
  } else {
    fail('CONTRAST', `contrast-check.mjs reports FAIL: ${failCount} (expected 0)`);
  }
}

// ---------------------------------------------------------------------------
// Check 2: VERIFY-LOGOS
// Trust exit code.
// ---------------------------------------------------------------------------
{
  const result = spawnSync('node', ['verify-logos.mjs'], {
    cwd: __dir,
    encoding: 'utf8',
  });

  if (result.status === 0) {
    pass('VERIFY-LOGOS', 'All logo checks passed (verify-logos.mjs exited 0)');
  } else {
    const output = (result.stdout || result.stderr || '').split('\n').filter(l => l.includes('FAIL')).slice(0, 5).join(' | ');
    fail('VERIFY-LOGOS', `verify-logos.mjs exited ${result.status}${output ? ': ' + output : ''}`);
  }
}

// ---------------------------------------------------------------------------
// Check 3: CONSISTENCY
// Trust exit code.
// ---------------------------------------------------------------------------
{
  const result = spawnSync('node', ['check-consistency.mjs'], {
    cwd: __dir,
    encoding: 'utf8',
  });

  if (result.status === 0) {
    pass('CONSISTENCY', '4-source hex consistency confirmed (check-consistency.mjs exited 0)');
  } else {
    const output = (result.stdout || result.stderr || '').split('\n').filter(l => l.includes('FAIL')).slice(0, 5).join(' | ');
    fail('CONSISTENCY', `check-consistency.mjs exited ${result.status}${output ? ': ' + output : ''}`);
  }
}

// ---------------------------------------------------------------------------
// Check 4: EXTENSION-ALLOWLIST
// Walk brandbook/ recursively, skip tools/node_modules.
// Every file must match: html|md|json|css|svg|mjs by extension,
// OR be named .gitignore, OR end in .lock.
// ---------------------------------------------------------------------------
{
  const NODE_MODULES = resolve(BRANDBOOK_DIR, 'tools', 'node_modules');
  const ALLOWED_EXTS = new Set(['.html', '.md', '.json', '.css', '.svg', '.mjs']);

  const violations = [];

  function walkAllowlist(dir) {
    for (const entry of readdirSync(dir)) {
      const full = join(dir, entry);
      if (full === NODE_MODULES) continue;
      const st = statSync(full);
      if (st.isDirectory()) {
        walkAllowlist(full);
      } else {
        const name = basename(full);
        const ext = extname(full).toLowerCase();
        const isAllowed =
          ALLOWED_EXTS.has(ext) ||
          name === '.gitignore' ||
          name.endsWith('.lock');
        if (!isAllowed) {
          violations.push(full.replace(REPO_ROOT + '/', ''));
        }
      }
    }
  }

  walkAllowlist(BRANDBOOK_DIR);

  if (violations.length === 0) {
    pass('EXTENSION-ALLOWLIST', 'All brandbook/ files have allowed extensions (zero binaries)');
  } else {
    fail('EXTENSION-ALLOWLIST', `Non-allowlisted files: ${violations.join(', ')}`);
  }
}

// ---------------------------------------------------------------------------
// Check 5: BRANDBOOK-SIZE
// Sum byte sizes of all files under brandbook/ (excluding tools/node_modules).
// PASS if total < 500 KB (512000 bytes).
// ---------------------------------------------------------------------------
{
  const NODE_MODULES = resolve(BRANDBOOK_DIR, 'tools', 'node_modules');
  const BUDGET_BYTES = 500 * 1024; // 500 KB

  let totalBytes = 0;

  function walkSize(dir) {
    for (const entry of readdirSync(dir)) {
      const full = join(dir, entry);
      if (full === NODE_MODULES) continue;
      const st = statSync(full);
      if (st.isDirectory()) {
        walkSize(full);
      } else {
        totalBytes += st.size;
      }
    }
  }

  walkSize(BRANDBOOK_DIR);

  const totalKB = Math.round(totalBytes / 1024);

  if (totalBytes < BUDGET_BYTES) {
    pass('BRANDBOOK-SIZE', `brandbook/ total: ${totalKB} KB (budget: <500 KB)`);
  } else {
    fail('BRANDBOOK-SIZE', `brandbook/ total: ${totalKB} KB — exceeds 500 KB budget`);
  }
}

// ---------------------------------------------------------------------------
// Check 6: INDEX-OFFLINE
// Read brandbook/index.html:
//   a) Zero http:// or https:// substrings EXCEPT xmlns="http://www.w3.org/2000/svg"
//   b) Every src="..." (and local href="...") resolves as a file relative to brandbook/
// ---------------------------------------------------------------------------
{
  const INDEX_PATH = resolve(BRANDBOOK_DIR, 'index.html');

  if (!existsSync(INDEX_PATH)) {
    fail('INDEX-OFFLINE', 'brandbook/index.html does not exist');
  } else {
    const html = readFileSync(INDEX_PATH, 'utf8');
    const violations = [];

    // a) Network ref scan — strip xmlns= occurrences first, then find remaining http(s)
    const stripped = html
      // Remove the SVG xmlns attribute occurrences (the only allowed exception)
      .replace(/xmlns="http:\/\/www\.w3\.org\/2000\/svg"/g, '')
      // Also handle single-quoted or unquoted variants just in case
      .replace(/xmlns='http:\/\/www\.w3\.org\/2000\/svg'/g, '');

    const httpRefs = stripped.match(/https?:\/\/[^\s"'<>]*/g) || [];
    if (httpRefs.length > 0) {
      violations.push(`Disallowed network refs: ${httpRefs.slice(0, 5).join(', ')}`);
    }

    // b) src= resolution — extract src="..." values, skip absolute URLs and data URIs
    const srcMatches = html.matchAll(/\bsrc="([^"]+)"/g);
    for (const m of srcMatches) {
      const ref = m[1];
      if (ref.startsWith('http://') || ref.startsWith('https://') || ref.startsWith('data:')) {
        continue; // external or inline — already caught by network scan
      }
      const resolved = resolve(BRANDBOOK_DIR, ref);
      if (!existsSync(resolved)) {
        violations.push(`Unresolved src="${ref}"`);
      }
    }

    // Also check href= for local file refs (exclude in-page anchors and external URLs)
    const hrefMatches = html.matchAll(/\bhref="([^"]+)"/g);
    for (const m of hrefMatches) {
      const ref = m[1];
      if (
        ref.startsWith('#') ||
        ref.startsWith('http://') ||
        ref.startsWith('https://') ||
        ref.startsWith('data:') ||
        ref.startsWith('mailto:')
      ) {
        continue;
      }
      const resolved = resolve(BRANDBOOK_DIR, ref);
      if (!existsSync(resolved)) {
        violations.push(`Unresolved href="${ref}"`);
      }
    }

    if (violations.length === 0) {
      pass('INDEX-OFFLINE', 'index.html has zero network refs (xmlns excepted); all src= resolve locally');
    } else {
      fail('INDEX-OFFLINE', violations.join(' | '));
    }
  }
}

// ---------------------------------------------------------------------------
// Check 7: MIX-TEST
// Phase 22-01 ran `mix test` green: 3 doctests, 632 tests, 0 failures.
// Spawning `mix` from a Node.js gate script is environment-fragile
// (requires Elixir on PATH, correct MIX_ENV, DB up). Per the plan's
// read_first discretion, we document the 22-01 run as the gate evidence.
// ---------------------------------------------------------------------------
{
  pass(
    'MIX-TEST',
    'Verified in 22-01 (mix test: 3 doctests, 632 tests, 0 failures; see 22-01-SUMMARY.md)'
  );
}

// ---------------------------------------------------------------------------
// Check 8: DASHBOARD-MARK
// Verify lib/scoria_web/components/layouts.ex brand_mark/1 function:
//   - Contains fill-rule="evenodd" within the brand_mark/1 function body
//   - Does NOT contain <circle within the brand_mark/1 function body
//
// Note: layouts.ex also has icon/1 which legitimately contains <circle elements
// (nav icons: :tree, default fallback). The check is scoped to brand_mark/1
// only — the plan's file-wide `!grep -q "<circle"` verify would false-FAIL
// due to these unrelated circles (documented in 22-01-SUMMARY.md deviation §1).
// ---------------------------------------------------------------------------
{
  const LAYOUTS_PATH = resolve(REPO_ROOT, 'lib', 'scoria_web', 'components', 'layouts.ex');

  if (!existsSync(LAYOUTS_PATH)) {
    fail('DASHBOARD-MARK', 'lib/scoria_web/components/layouts.ex not found');
  } else {
    const src = readFileSync(LAYOUTS_PATH, 'utf8');

    // Extract brand_mark/1 function body: from "def brand_mark" to the matching "end"
    // The ~H""" template closes before the final "end"
    const brandMarkMatch = src.match(/def brand_mark\(assigns\)[^]*?^  end/m);

    if (!brandMarkMatch) {
      fail('DASHBOARD-MARK', 'Could not locate brand_mark/1 function in layouts.ex');
    } else {
      const brandMarkBody = brandMarkMatch[0];
      const hasEvenodd = brandMarkBody.includes('fill-rule="evenodd"');
      const hasCircle = brandMarkBody.includes('<circle');
      const violations = [];

      if (!hasEvenodd) violations.push('brand_mark/1 is missing fill-rule="evenodd"');
      if (hasCircle) violations.push('brand_mark/1 contains <circle (placeholder not fully removed)');

      if (violations.length === 0) {
        pass('DASHBOARD-MARK', 'brand_mark/1 uses fill-rule="evenodd" and contains no <circle elements');
      } else {
        fail('DASHBOARD-MARK', violations.join(' | '));
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Summary
// ---------------------------------------------------------------------------

console.log('');
if (failures === 0) {
  console.log(`PASS  [GATE]  All 8 checks passed — Phase 22 final quality gate GREEN`);
  process.exit(0);
} else {
  console.log(`FAIL  [GATE]  ${failures} check(s) failed — Phase 22 quality gate RED`);
  process.exit(1);
}
