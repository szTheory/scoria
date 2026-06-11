---
phase: 21-tokens-brandbook-html
plan: 01
subsystem: brandbook
tags: [tokens, css-custom-properties, json, brandbook, consistency-check]
dependency_graph:
  requires: []
  provides: [brandbook/tokens.css, brandbook/tokens.json, brandbook/README.md, brandbook/tools/check-consistency.mjs]
  affects: [phase-22-integration]
tech_stack:
  added: []
  patterns: [two-tier-tokens, two-ssot-distinction, threadline-compatible-json-shape]
key_files:
  created:
    - brandbook/tokens.css
    - brandbook/tokens.json
    - brandbook/README.md
    - brandbook/tools/check-consistency.mjs
  modified: []
decisions:
  - "Two SSOT pattern: assets/css/02-tokens.css (.scoria-root, @layer) is dashboard runtime; brandbook/tokens.css (:root) is docs/marketing — same names, same hexes, different selector/scope"
  - "tokens.json raw.color warm brand scale uses keys 'scoria-900' etc. which the checker maps to CSS name '900' (--scoria-900) — consistent with CSS declarations"
  - "check-consistency.mjs covers only PRIMITIVE hex tokens (parseable as bare #hex); semantic color-mix() / var() tokens are intentionally excluded from the hex equality assertion"
  - "TODO(21-03) extension point in check-consistency.mjs for wiring brand-book.md as fourth source — no restructuring needed when plan 21-03 lands"
metrics:
  duration: 28m
  completed: "2026-06-11T18:17:40Z"
  tasks_completed: 3
  files_created: 4
---

# Phase 21 Plan 01: Brandbook Token Layer Summary

**One-liner:** `:root`-scoped `--scoria-` token layer (two-tier, hex-identical to 02-tokens.css) plus Threadline-shaped tokens.json, maintenance README, and hex-consistency checker.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Author brandbook/tokens.css | d161748 | brandbook/tokens.css |
| 2 | Author brandbook/tokens.json | 02ecc30 | brandbook/tokens.json |
| 3 | README.md + check-consistency.mjs | cfa998f | brandbook/README.md, brandbook/tools/check-consistency.mjs |

## Artifacts

### brandbook/tokens.css
- 173 `--scoria-*` declarations across both dark (`:root`) and light (`:root[data-theme="light"]`) blocks
- PRIMITIVE tier: 30 bare-hex tokens (neutrals basalt/char/graphite/pumice/tuff/ash, warm brand scale scoria/ember/molten/cinder, functional accent pairs)
- SEMANTIC tier: surface, text, link, border, focus, action, shadow, glow, tone family (neutral/pass/info/warn/fail/trace/brand x fg/bg/border), span-kind (10 tokens)
- No `.scoria-root` selector, no `@layer` wrapper — copy-pasteable into any host page
- Header comment explains the two-SSOT distinction and points to check-consistency.mjs

### brandbook/tokens.json
- Threadline-compatible nested shape: `name`, `version`, `source`, `raw.color`, `semantic.dark`, `semantic.light`, `typography`, `spacing`, `radius`, `motion`, `state`
- `raw.color`: 28 primitive hex entries matching tokens.css exactly
- `semantic.dark` + `semantic.light`: 51 tokens each, with `var()` references resolved to literal hex values; `color-mix()` expressions preserved as CSS strings
- `state`: 12-token block (default/hover/active/focus/disabled/selected/success/warning/error/info/subtle/muted) — Threadline-parity

### brandbook/README.md
- 73 content lines
- Two-SSOT table distinguishing runtime vs docs token files
- Maintenance rules covering: SVG/text-only constraint, font-file prohibition, sync rule for both token files, consistency checker invocation, candidates as historical
- Best current defaults: positioning, one-liner, hero headline, logo system, palette, typography, voice

### brandbook/tools/check-consistency.mjs
- Node ESM, zero external dependencies
- Parses `--scoria-NAME: #hex` pairs from both CSS files using regex
- Parses `raw.color` primitives from tokens.json, mapping `scoria-900` → CSS name `900`
- Normalizes all hex to lowercase before comparison
- Exits 0: all 30 CSS primitive tokens agree between the two CSS files; all 28 JSON primitives match tokens.css
- Exits 1 with diff listing on any mismatch
- TODO(21-03) extension point with commented example for brand-book.md as fourth source

## Verification Results

```
node brandbook/tools/check-consistency.mjs

LOADED  brandbook/tokens.css — 30 hex tokens found
LOADED  assets/css/02-tokens.css — 30 hex tokens found
LOADED  brandbook/tokens.json (raw.color) — 28 primitive hex values found

── CSS ↔ CSS comparison ─────────────────────────────────────────
PASS    All shared primitive tokens agree between CSS sources

── JSON ↔ brandbook/tokens.css comparison ───────────────────────
PASS    All tokens.json primitives match brandbook/tokens.css

── Summary ──────────────────────────────────────────────────────
PASS    All token sources agree. Hex consistency check complete.
```

Spot checks:
- `--scoria-basalt-950: #11100f` present in tokens.css (line 22)
- `--scoria-ember-500: #e65a32` present in tokens.css (line 35)
- No `.scoria-root` selector, no `@layer` in tokens.css
- No edits to repo-root README.md, layouts.ex, or mix.exs

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Comment text triggered verify grep for `scoria-root` and `@layer`**
- **Found during:** Task 1 verification
- **Issue:** The header comment in tokens.css contained the literal strings `.scoria-root` (in "scoped to .scoria-root class") and `@layer` (in "@layer scoria.tokens") which caused the plan's `! grep -q 'scoria-root'` and `! grep -q '@layer'` assertions to fail.
- **Fix:** Rewrote comment phrases to avoid the literal tokens: "class-scoped, cascade-layer wrapped" instead of ".scoria-root-scoped, @layer scoria.tokens"; "cascade-layer wrapper" instead of "@layer wrapper".
- **Files modified:** brandbook/tokens.css (comment block only)
- **Commit:** d161748 (included in original commit)

## Known Stubs

None — all four artifacts are fully implemented and wired. The TODO(21-03) in check-consistency.mjs is a clearly-labeled extension point, not a stub; the checker functions correctly without brand-book.md.

## Threat Flags

None. No new network endpoints, auth paths, file access patterns, or schema changes. The consistency checker reads local files at a path relative to the repo root; no network calls.

## Self-Check: PASSED

- [x] `brandbook/tokens.css` exists with 173 `--scoria-*` declarations, `:root` + `:root[data-theme="light"]` scope
- [x] `brandbook/tokens.json` exists, valid JSON, required key set present
- [x] `brandbook/README.md` exists, 73 content lines
- [x] `brandbook/tools/check-consistency.mjs` exists, exits 0
- [x] Commits d161748, 02ecc30, cfa998f verified in git log
- [x] No edits to repo-root README.md, layouts.ex, or mix.exs
