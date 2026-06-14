---
phase: 18-pressure-test-audit-decision-lock
plan: 01
subsystem: brand
tags: [brand, wcag, audit, contrast, design-tokens]
dependency_graph:
  requires: []
  provides: [brandbook/tools/contrast-check.mjs, brandbook/pressure-test.md sections 1-7]
  affects: [18-02 decisions-locked, Phase 19 logo direction, Phase 21 token spec, BRAND-09 propagation verdict]
tech_stack:
  added: [Node ESM .mjs, WCAG 2.1 relative luminance math]
  patterns: [zero-dep contrast checker, dual-tier token audit (documented + shipped), KEEP/TIGHTEN/REWORK/ADD/REMOVE verdict taxonomy]
key_files:
  created:
    - brandbook/tools/contrast-check.mjs
    - brandbook/pressure-test.md
  modified: []
decisions:
  - "Propagation verdict presumption: not-required — all 52 shipped pairings pass WCAG at minimum PASS-LARGE; no FAIL; pending Phase 18-02 usage audit of --scoria-text-subtle in actual rendered text"
  - "--scoria-text-subtle (#88786D Pumice-500) is PASS-LARGE (3.91–4.48:1 across surfaces) — acceptable for muted UI labels, icons, 12px metadata; must not be used for running body text"
  - "Warning-light (#7A5A16 Sulfur) on Ash-50 passes at 5.87:1 — the 18-CONTEXT known-risk flag was overcautious; no fix needed"
  - "Scoria-600 on Basalt-950 = 3.82:1 PASS-LARGE confirms the brand-book §5.5 warning; dark-mode normal text use prohibited"
  - "Logo execution (Phase 19) is the highest-leverage unblocked action; all visual-identity stress tests are blocked until the mark exists"
  - "IBM Plex Sans + JetBrains Mono confirmed KEEP — correct pairing, no reason to change"
  - "Voice/microcopy section (§7) is the brand book's strongest section — KEEP without changes"
metrics:
  duration: ~90min
  completed: "2026-06-11"
  tasks: 2
  files: 2
---

# Phase 18 Plan 01: Contrast Checker + Pressure-Test Sections 1–7 Summary

**One-liner:** Zero-dep WCAG contrast checker (52 pairings, 0 FAIL) and candid 7-section brand audit establishing propagation-not-required presumption and logo execution as the #1 gap.

## What Was Built

### Task 1: `brandbook/tools/contrast-check.mjs`

A standalone Node ESM script (no npm install, exits 0 always) implementing WCAG 2.1 relative luminance per the IEC 61966-2-1 spec. Exports a `relativeLuminance()` function. Covers:

- 22 DOCUMENTED pairings from brand-book §5.4 (functional accent pairs, both surfaces) and §5.5 (recommended pairings + known-risk pairs + the deliberate negative-control Scoria-600 on Basalt-950)
- 30 SHIPPED pairings resolved from `assets/css/02-tokens.css` — semantic fg tokens on resolved surface hex for both dark default and `[data-theme="light"]`

Results: 52 total pairings — **46 PASS-AA, 6 PASS-LARGE, 0 FAIL**.

### Task 2: `brandbook/pressure-test.md` Sections 1–7

Comprehensive brand-book audit (588 lines) covering:
- **Section 1** — Candid executive judgment (strong enough to build from; logo is the critical gap)
- **Section 2** — 11-field brand DNA extraction with all canonical fields
- **Section 3** — 15-dimension 1–10 scorecard (Accessibility score 6/10 citing the Pumice-500 boundary)
- **Section 4** — All 26 prompt surfaces stress-tested with depth proportional to relevance
- **Section 5** — Severity-ranked gaps: C1 (logo absent), C2 (text-subtle PASS-LARGE with all 4 shipped ratios), C3 (propagation policy undocumented), plus Important and Nice-to-have tiers
- **Section 6** — KEEP/TIGHTEN/REWORK/ADD/REMOVE verdicts; §5.5 accessibility rules flagged for REWORK; §14 ADD badge spec
- **Section 7** — Token direction spec (focus ring, state, code-block, callout tokens); contrast table embedded verbatim from script output

## Contrast Findings (Key Numbers for 18-02)

| Pairing | Ratio | Verdict | Impact |
|---|---|---|---|
| `--scoria-text-subtle` on `--scoria-surface-app` (dark) | 4.48:1 | PASS-LARGE | Muted labels only |
| `--scoria-text-subtle` on `--scoria-surface-panel` (dark) | 4.29:1 | PASS-LARGE | Muted labels only |
| `--scoria-text-subtle` on `--scoria-surface-app` (light) | 3.91:1 | PASS-LARGE | Most constrained shipped pair |
| `--scoria-text-subtle` on `--scoria-surface-panel` (light) | 4.06:1 | PASS-LARGE | Muted labels only |
| Scoria-600 on Basalt-950 (negative control) | 3.82:1 | PASS-LARGE | Book's own §5.5 warning confirmed |
| Warning-light (#7A5A16) on Ash-50 | 5.87:1 | PASS-AA | Known-risk label was overcautious |

**Propagation verdict input for 18-02:** No shipped pairing FAILS. Propagation presumption = not-required. The Phase 18-02 task must audit actual dashboard usage of `--scoria-text-subtle` in rendered text to confirm the final verdict.

## Deviations from Plan

None — plan executed exactly as written. The contrast checker produced 52 rows (plan required ≥20). The pressure-test is 588 lines (plan required ≥250). All seven section headings are verbatim.

## Known Stubs

None. The pressure-test is editorial content, not a data-backed artifact. The contrast table is the script's stdout, not hand-typed.

## Threat Flags

None. These are documentation artifacts with no network endpoints, auth paths, file writes, or schema changes.

## Self-Check: PASSED

- `brandbook/tools/contrast-check.mjs` exists and runs: confirmed (exit=0, 52 rows)
- `brandbook/pressure-test.md` exists: confirmed (588 lines)
- Commits: `2b74473` (contrast-check.mjs), `cae5b0a` (pressure-test.md)
- All seven `## SECTION N —` headings present verbatim: confirmed (verify loop printed no MISSING lines)
- dims=24 (≥15), verdicts=46 (≥10), contrast_in_doc=70 (≥20), dna_fields=10 (≥7)
