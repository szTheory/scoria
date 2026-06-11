---
phase: 20-logo-convergence-variant-set
verified: 2026-06-11T00:00:00Z
status: passed
score: 9/9
overrides_applied: 0
re_verification: false
---

# Phase 20: Logo Convergence — Variant Set Verification Report

**Phase Goal:** The locked TV-1 + LK-B direction became a complete optically-corrected 8-variant set at brandbook/ root with clear-space/min-size spec, losers pruned, user-confirmed at the ship-it checkpoint (user approved 2026-06-11, no adjustments).
**Verified:** 2026-06-11
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | All 8 root variant SVGs exist at brandbook/ root with exact census filenames | VERIFIED | `ls brandbook/*.svg` returns exactly 8 files: logo-primary, logo-primary-light, logo-mark, logo-monochrome, logo-lockup-subtitle, logotype-integrated, favicon, social-card |
| 2 | Every root logo SVG (except social-card's documented rect) has no `<rect>`, uses fill-rule=evenodd, fills only | VERIFIED | grep confirms 0 `<rect>` in all 7 non-social SVGs; social-card has exactly 1 card-ground rect; ROOT-NORECT + ROOT-EVENODD checks PASS |
| 3 | favicon.svg renders TV-1 holes16 3-hole simplified path, pixel-grid snapped, ≤1KB | VERIFIED | `wc -c` = 734 bytes (≤1024); ROOT-FAVICON check: ≤1024 bytes + exactly 3 hole subpaths — PASS |
| 4 | logo-monochrome.svg and logotype-integrated.svg use currentColor with holes intact | VERIFIED | `cmp` confirms byte-identical; ROOT-CURRENTCOLOR check PASS; both use `currentColor` fill |
| 5 | `node brandbook/tools/verify-logos.mjs` exits 0 with all ROOT-* checks covering all 8 root files | VERIFIED | Executed live; exit code 0; all 21 checks PASS including ROOT-EXISTS, ROOT-NORECT, ROOT-EVENODD, ROOT-STROKE, ROOT-VIEWBOX, ROOT-DECIMALS, ROOT-CURRENTCOLOR, ROOT-FAVICON, ROOT-SUBTITLE, BUDGET |
| 6 | Optical-correction pass documented (single-vs-two-tone, ink-density, overshoot/spacing notes) in variant-spec.md | VERIFIED | variant-spec.md contains: two-tone decision with ink-density 0.61 vs 0.57 (~7%), overshoot/baseline measurement (x 111.22–167.87, y −53.38–1.18), favicon legibility (holes ≥1.5px at 16px, even 16-grid snap) |
| 7 | Clear-space (cap-height/2) and min-size rules written in variant-spec.md | VERIFIED | Sections 5 and 6 of variant-spec.md: clear space = cap-height/2 ≈38.4u; min sizes: lockup ≥120px, mark ≥20px, favicon 16/32px exact |
| 8 | Losing candidates and both gallery HTML files deleted; candidates/ retains only TV-1 lineage + LK-B files | VERIFIED | options-gallery.html and options-gallery-round2.html absent; `ls candidates/` = LK-B-lockup, TV-1-fav, TV-1-lockup, TV-1-mark, TV-1-mono (exactly 5 files, no extras) |
| 9 | Subtitle text appears ONLY in logo-lockup-subtitle.svg and social-card.svg | VERIFIED | grep confirms "AI ops for Phoenix apps." absent from the 6 non-subtitle/social SVGs; ROOT-SUBTITLE check PASS |

**Score:** 9/9 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `brandbook/logo-primary.svg` | LK-B fused lockup, dark-surface colorway, fill-rule="evenodd" | VERIFIED | Exists; contains fill-rule="evenodd"; two-tone (#FFF9F3 letters + #E65A32 mark) |
| `brandbook/logo-primary-light.svg` | LK-B fused lockup, light-surface colorway, fill-rule="evenodd" | VERIFIED | Exists; contains fill-rule="evenodd"; light colorway |
| `brandbook/logo-mark.svg` | TV-1 mark alone, role="img" | VERIFIED | Exists; contains role="img" |
| `brandbook/logo-monochrome.svg` | LK-B fused lockup, currentColor | VERIFIED | Exists; contains currentColor |
| `brandbook/logo-lockup-subtitle.svg` | LK-B + tagline "AI ops for Phoenix apps." | VERIFIED | Exists; tagline confirmed present |
| `brandbook/logotype-integrated.svg` | Fused wordmark single-color, currentColor | VERIFIED | Exists; byte-identical to logo-monochrome.svg (cmp confirms) |
| `brandbook/favicon.svg` | TV-1 holes16 3-hole path, fill-rule="evenodd", ≤1KB | VERIFIED | Exists; 734 bytes; exactly 3 hole subpaths confirmed by ROOT-FAVICON |
| `brandbook/social-card.svg` | 1280×640 bounded card, LK-B lockup + tagline | VERIFIED | Exists; viewBox="0 0 1280 640"; contains tagline |
| `brandbook/tools/variant-spec.md` | Clear-space/min-size spec + documented optical-correction pass, contains "Clear space" | VERIFIED | Exists; sections 1–7 cover all required documentation |
| `brandbook/tools/final-variants.html` | Confirm strip, both #11100F and #FAF5EF grounds present | VERIFIED | Exists; grep finds both ground colors; 122 KB inline, standalone |
| `brandbook/tools/final-strip.mjs` | Generator that reads + inlines 8 root SVGs, ≥20 lines | VERIFIED | Exists; 122 lines; reads from brandbook/ via readFileSync |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `brandbook/tools/converge.mjs` | `brandbook/tools/lib/root-variants.mjs` | import of root-variant composers | WIRED | Line 33: `from './lib/root-variants.mjs'` |
| `brandbook/tools/lib/root-variants.mjs` | `brandbook/tools/presets.mjs` | TV-1 / holes16 lineage source | WIRED | Line 32: `import { TV_1, PALETTE } from '../presets.mjs'` |
| `brandbook/tools/verify-logos.mjs` | `brandbook/` root SVGs | ROOT-* structural checks over the 8 files | WIRED | Lines 432+ implement ROOT-* checks; all 8 census filenames enumerated |
| `brandbook/tools/final-strip.mjs` | `brandbook/*.svg` | reads + inlines 8 root SVGs | WIRED | readFileSync pattern confirmed; logo-primary referenced in file |
| `brandbook/tools/final-variants.html` | the 8 root variants | inline SVG on both grounds | WIRED | File contains #11100F + #FAF5EF grounds; no `<img>` tags; no external http refs |

---

### Data-Flow Trace (Level 4)

Not applicable — this phase produces static SVG artwork and verifier scripts, not components that render dynamic data from a database or API.

---

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Verifier exits 0 with all ROOT-* checks | `node brandbook/tools/verify-logos.mjs` | exit 0; 21 checks PASS | PASS |
| Exactly 8 SVGs at brandbook root | `ls brandbook/*.svg \| wc -l` | 8 | PASS |
| favicon.svg ≤ 1024 bytes | `wc -c brandbook/favicon.svg` | 734 | PASS |
| logotype-integrated byte-identical to logo-monochrome | `cmp brandbook/logotype-integrated.svg brandbook/logo-monochrome.svg` | no output (identical) | PASS |
| No `<rect` in 7 non-social SVGs | grep count on each | 0 for all 7 | PASS |
| social-card.svg has exactly 1 rect | grep count | 1 | PASS |
| Gallery HTML files absent | `test ! -f options-gallery*.html` | both absent | PASS |
| candidates/ contains only 5 approved files | ls + grep exclusion | CANDIDATES_CLEAN | PASS |
| No Phase 21/22 scope leak | test -f tokens.json, brand-book.md, -d examples | all absent | PASS |
| brandbook/ artifacts under 500 KB | verifier BUDGET check via statSync() | 463 KB | PASS |

Note on size measurement: `du -sk` reports 528 KB (filesystem block allocation on macOS APFS), which exceeds 500 KB. However the authoritative gate is `verify-logos.mjs` which uses `statSync().size` (actual byte content) and reports 463 KB — the spec-defined measure. The verifier exits 0; the BUDGET check PASSES against the correct metric.

---

### Probe Execution

No probe scripts declared for this phase. Not a migration or CLI tooling phase.

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| BRAND-04 | 20-01-PLAN.md, 20-02-PLAN.md | Complete committed variant set with clear-space/min-size rules and optical-correction pass | SATISFIED | REQUIREMENTS.md line 19: `- [x] **BRAND-04**`; table entry: "Complete"; all 8 variant files verified on disk; variant-spec.md confirmed |

---

### Anti-Patterns Found

No TBD, FIXME, or XXX debt markers in any phase-modified files (converge.mjs, lib/root-variants.mjs, verify-logos.mjs, variant-spec.md, final-strip.mjs, final-variants.html). No TODO/PLACEHOLDER/HACK patterns found.

No empty implementations. All 8 SVGs contain real frozen artwork. All tooling scripts perform real file I/O.

---

### Human Verification Required

None. All verification criteria were confirmable programmatically. The ship-it checkpoint (Task 3 of Plan 20-02) was completed: the objective states "user approved 2026-06-11, no adjustments."

---

### Gaps Summary

No gaps. All 9 observable truths verified. All required artifacts exist, are substantive, and are properly wired. BRAND-04 is marked complete in REQUIREMENTS.md. The phase goal is fully achieved.

---

_Verified: 2026-06-11T00:00:00Z_
_Verifier: Claude (gsd-verifier)_
