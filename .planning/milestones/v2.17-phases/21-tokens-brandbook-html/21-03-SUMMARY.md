---
phase: 21-tokens-brandbook-html
plan: 03
subsystem: ui
tags: [brand, brand-book, html, design-tokens, accessibility, contrast, consistency-gate]

# Dependency graph
requires:
  - phase: 21-tokens-brandbook-html
    plan: 01
    provides: tokens.css (--scoria- :root token set), tokens.json, check-consistency.mjs with the 21-03 extension point
  - phase: 21-tokens-brandbook-html
    plan: 02
    provides: brand-book.md (canonical content + §4 color tables), 7 example SVG specimens, 8 shipped logo SVGs
  - phase: 18-pressure-test
    provides: pressure-test.md §1 executive judgment, §7 52-pairing contrast table, §14 quality gate
provides:
  - "brandbook/index.html — professional standalone dark-first brand book (BRAND-06), 11-section skeleton, 55KB, zero network refs"
  - "Full 52-pairing WCAG contrast table rendered as a real color-coded <table> (46 PASS-AA / 6 PASS-LARGE / 0 FAIL)"
  - "check-consistency.mjs extended to a 4th hex source (brand-book.md §4 color tables); the consistency gate now spans tokens.json ↔ tokens.css ↔ 02-tokens.css ↔ brand-book.md"
affects: [22-integration]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Self-contained HTML: --scoria- token set inlined in a <style> block (hexes identical to tokens.css, gate-verified); page opens from file:// with zero network requests"
    - "System-fallback font stacks only (\"IBM Plex Sans\", -apple-system, … ) — no webfont <link>, renders correctly without Plex installed"
    - "Relative <img src> to sibling logo + examples SVGs (preferred over inlining); the brandbook/ directory ships as a unit"
    - "Subset consistency source: brand-book.md asserts agreement/membership (label→token mapping), not completeness"

key-files:
  created:
    - brandbook/index.html
  modified:
    - brandbook/tools/check-consistency.mjs

key-decisions:
  - "Omitted the Google-Fonts <link> entirely (plan permitted an optional one) — chose the stricter zero-network-ref interpretation so the page is provably offline-complete; system fallback stack carries the typography"
  - "Inlined the token :root set rather than <link rel=stylesheet href=tokens.css> (Threadline's approach) — Threadline's external link would be a load-bearing network/file ref; inlining keeps index.html a true single-file artifact"
  - "Rendered the FULL 52-pairing contrast table verbatim from pressure-test §7 (not the abbreviated brand-book.md version) — index.html is the comprehensive reference; verdicts color-coded with the tone-pass/tone-warn/tone-fail tokens"
  - "brand-book.md consistency mapping is label-keyed (Basalt-950 → basalt-950, scoria-600 → 600, Success pair → success-light/success-dark) with subset semantics — the doc documents a representative palette, so missing tokens are skipped, present tokens must match"
  - "Replaced the single 'CSS ↔ CSS' PASS line with a per-source PASS line so all 4 sources report coverage explicitly (the plan asked for a PASS line per source)"

patterns-established:
  - "Standalone brand-book HTML is dark-first volcanic: Basalt-950 ground, warm Ash text, Ember/Molten accents, big quiet mono section numbers, ~70ch measure"
  - "Light grounds appear only as inset cards (panel-light / [data-theme=light]) where the logo-on-light and contrast comparison demand them"
  - "Consistency gate is honest: verified via negative control (tampering a brand-book.md hex produces FAIL + exit 1; restoring returns exit 0)"

requirements-completed: [BRAND-06]

# Metrics
metrics:
  duration: ~25m
  tasks: 2
  files-created: 1
  files-modified: 1
  completed: 2026-06-11
---

# Phase 21 Plan 03: Standalone Brand Book (index.html) + 4-source consistency gate Summary

**`brandbook/index.html` is a 55KB self-contained dark-first volcanic brand book covering the full 11-section skeleton (hero → executive summary → brand DNA → logo system → color with the full 52-pairing contrast table → typography → voice → UI → blueprints → artifact index → QA gate), styled entirely with the inlined `--scoria-` tokens, with zero network refs and all relative `<img>` references resolving to sibling files; `check-consistency.mjs` now asserts hex agreement across four sources including `brand-book.md` and exits 0.**

## What was built

### Task 1 — `brandbook/index.html` (commit `44380e6`)

A single standalone file, titled "Scoria Brand Book", that opens from `file://` with no network requests:

- **Dark-first volcanic styling** built entirely from the `--scoria-` token set, inlined into a `<style>` block (hexes identical to `tokens.css`, gate-verified). Basalt-950 ground, warm Ash text, Ember/Molten accents, generous whitespace, ~70ch measure, big quiet JetBrains-Mono section numbers.
- **Hero**: `logo-primary.svg` via relative `<img>`, the primary tagline "AI ops for Phoenix apps.", the one-liner, then the three-line verb-triplet ("Trace the run." / "Prove the change." / "Ship the agent.") as the display treatment beneath — demonstrating the locked hierarchy.
- **11 sections**: executive judgment (§1), brand DNA, logo system (variants on both dark and light grounds + usage/clear-space/min-size/misuse rules + two-tone table), color (4 swatch groups built from the real token hexes + palette specimen + the **full 52-pairing contrast verdict table**, color-coded PASS-AA / PASS-LARGE / FAIL with the two load-bearing constraints called out), typography (Plex/JetBrains specimen + scale + specimen SVG), voice (say/don't table + error/empty/success microcopy + word bank), UI guidance (states, non-color-status rule, Elixir code block, component + terminal specimens), landing/docs blueprints (with landing-hero/docs-page/readme-header specimens), artifact index, and the QA/quality-gate summary (§14).
- **Zero network refs**: no Google-Fonts `<link>` at all; system fallback font stacks only. All 12 `src=` references resolve to existing sibling files (7 examples + 5 logos).
- **55,490 bytes** — well under the 90KB target.

### Task 2 — `check-consistency.mjs` 4th source (commit `55632ec`)

Extended the consistency gate at the 21-01 TODO extension point:

- Added `parseBrandBookHexes()` — extracts the §4 color-table hexes from `brand-book.md` and maps each documented token label to its `--scoria-*` CSS name (single neutral/brand-scale rows + light/dark functional-accent pairs), normalizing to lowercase.
- `brand-book.md` is wired in as the 4th source; the gate now spans `tokens.json ↔ tokens.css ↔ 02-tokens.css ↔ brand-book.md`. It is a **subset** source — the check asserts agreement/membership (any documented token must match), not completeness.
- Output now prints a **PASS line per source** (26 brand-book.md tokens shared and agreeing; 30 for 02-tokens.css; JSON primitives match). Exits 0 on full agreement, exit 1 with a diff on any mismatch.

## Verification (all run honestly)

| Check | Result |
|---|---|
| `node brandbook/tools/check-consistency.mjs` | exit 0, 4 sources loaded & agreeing |
| `index.html` byte budget ≤ 90KB | 55,490 bytes — PASS |
| `ls brandbook/examples/*.svg` count | 7 — PASS |
| Every `src=` resolves to existing file | PASS (all 12) |
| Load-bearing network refs | none — PASS |
| `brand-book.md` referenced in tool | yes (9 occurrences) |
| Negative control (tamper a hex) | FAIL + exit 1; restore → exit 0 (gate is honest) |

## Deviations from Plan

### Auto-fixed / discretion-applied

**1. [Discretion] Omitted the optional Google-Fonts `<link>` entirely.** The plan and 21-CONTEXT permitted a non-load-bearing font link, but also stated "zero network refs at all" in the Task 1 action. Chose the stricter interpretation: no `<link>` of any kind, system fallback stacks only. This makes the page provably offline-complete and satisfies the network-ref verifier with no exemptions needed.

**2. [Rule 3 - blocking accuracy] Inlined the token `:root` set instead of linking `tokens.css`.** Threadline's precedent uses `<link rel="stylesheet" href="tokens.css">`, but that is a load-bearing file reference. To keep `index.html` a true single-file artifact that styles correctly when opened in isolation, the `--scoria-` tokens are copied into an inline `<style>` (header documents that the hexes are identical to `tokens.css` and gate-verified).

**3. [Rule 1 - accuracy] Re-labeled the consistency comparison from "CSS ↔ CSS" to per-source "Cross-source agreement".** With `brand-book.md` (a markdown source) added to the comparison set, the old "CSS ↔ CSS" label and single rolled-up PASS line were inaccurate. Refactored the loop to iterate per source and emit one PASS/FAIL line each, so a `brand-book.md` mismatch surfaces distinctly and the 4-source coverage is explicit.

No architectural changes; no authentication gates; no out-of-scope files touched (no edits to `README.md`, `layouts.ex`, or `mix.exs`).

## Known Stubs

None. Every section renders real content from `brand-book.md` / `pressure-test.md`; every swatch and contrast row carries real token hexes and verdicts; every `<img>` points at a real sibling specimen.

## Self-Check: PASSED

- `brandbook/index.html` — FOUND
- `brandbook/tools/check-consistency.mjs` (modified) — FOUND
- Commit `44380e6` (index.html) — FOUND
- Commit `55632ec` (check-consistency 4th source) — FOUND
