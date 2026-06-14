---
phase: 19-logo-divergence-user-choice
verified: 2026-06-11T17:30:00Z
status: passed
score: 7/7 must-haves verified
overrides_applied: 0
---

# Phase 19: Logo Divergence + User Choice — Verification Report

**Phase Goal:** The user chose a logo direction from a gallery of genuinely distinct programmatic options with all LOGO-01..07 constraints enforced. OUTCOME (both gates happened): round 1 → TV-1 "Span rail" mark locked, TYPE-1/TYPE-2 typemarks rejected; second round (escape fired as designed) → 6 lockup-relationship variations; gate #2b → LK-B "Mark-as-o" fused lockup locked. Phase 20 inherits: TV-1 mark + LK-B primary lockup.
**Verified:** 2026-06-11T17:30:00Z
**Status:** PASSED
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `node brandbook/tools/smoke.mjs` exits 0 with all LOGO-01/02/03 checks passing | VERIFIED | Script ran; output: "SMOKE TEST PASS — toolchain is structurally valid." Exit 0. |
| 2 | `node brandbook/tools/verify-logos.mjs` exits 0 with LOGO-01..07 all PASS | VERIFIED | 19/19 checks PASS, 29 candidates verified. Exit 0. |
| 3 | >=6 distinct mark candidates + 6 LK-* round-2 lockup SVGs exist under candidates/ | VERIFIED | `ls candidates/*.svg` = 29 total; 6 mark SVGs; LK-A..LK-F all present. |
| 4 | Both galleries (options-gallery.html, options-gallery-round2.html) exist with zero external network refs and zero `<img>` tags | VERIFIED | Both files exist. Only http reference is `http://www.w3.org/2000/svg` namespace (not fetched). `<img>` count = 0 in both. |
| 5 | No `<rect>` in any candidates/*.svg; every *-mark.svg has fill-rule="evenodd"; no font binaries under brandbook/; node_modules not tracked | VERIFIED | `grep -rc '<rect' candidates/*.svg \| grep -v ':0'` = 0. `grep -L 'fill-rule="evenodd"' *-mark.svg` = empty. `find brandbook -name '*.woff2' -o -name '*.ttf'` = 0. `git ls-files \| grep node_modules` = 0. |
| 6 | No brandbook/ root SVG files (Phase 20 owns those) | VERIFIED | `ls brandbook/*.svg` = 0 files. |
| 7 | STATE.md records both gate #2 decisions (TV-1 mark locked + LK-B "Mark-as-o" lockup locked) | VERIFIED | STATE.md Decisions section line 95: "Gate #2 partial: TV-1 mark locked; typemarks rejected; second round for lockup variations". Line 96: "Gate #2 final: TV-1 mark + LK-B Mark-as-o lockup locked". |

**Score:** 7/7 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `brandbook/tools/package.json` | ESM, Node>=18, opentype.js + wawoff2 deps | VERIFIED | "type":"module", engines Node>=18, opentype.js ^1.3.5, wawoff2 ^2.0.1 |
| `brandbook/tools/.gitignore` | node_modules ignored | VERIFIED | Contains `node_modules/`, `*.ttf`, `*.otf` |
| `brandbook/tools/lib/geometry.mjs` | faceted-polygon + vesicle-hole -> single evenodd path | VERIFIED | 211 lines (>= 60 required) |
| `brandbook/tools/lib/svg.mjs` | SVG document builder | VERIFIED | 89 lines (>= 30 required) |
| `brandbook/tools/lib/wordmark.mjs` | woff2 decompress + opentype.js outline | VERIFIED | 258 lines (>= 50 required) |
| `brandbook/tools/lib/lockup.mjs` | mark + wordmark composer with LOGO-03 | VERIFIED | 159 lines (>= 30 required) |
| `brandbook/tools/smoke.mjs` | structural validity smoke test, exits 0 | VERIFIED | 210 lines (>= 40 required). Exits 0. |
| `brandbook/tools/presets.mjs` | 6 mark presets + 2 typemark presets, @design-intent blocks | VERIFIED | 364 lines (>= 120 required). 6 marks, 2 types, 9 @design-intent tags (>= 8 required). |
| `brandbook/tools/generate.mjs` | orchestrator: presets -> candidate SVGs | VERIFIED | exists |
| `brandbook/tools/gallery.mjs` | options-gallery.html builder | VERIFIED | exists |
| `brandbook/tools/options-gallery.html` | standalone gate-#2 evidence page | VERIFIED | 1264+ lines (>= 100 required). Both grounds. Full size ramp. Zero external refs. |
| `brandbook/tools/verify-logos.mjs` | LOGO-01..07 + gallery completeness verifier | VERIFIED | 492 lines (>= 60 required). All 19 checks pass. |
| `brandbook/tools/lib/lockup-variants.mjs` | 6 LK-* relationship composers (round 2) | VERIFIED | exists |
| `brandbook/tools/generate-round2.mjs` | round-2 candidate generator | VERIFIED | exists |
| `brandbook/tools/gallery-round2.mjs` | round-2 gallery builder | VERIFIED | exists |
| `brandbook/tools/options-gallery-round2.html` | round-2 gate evidence page | VERIFIED | 611 lines. Both grounds. LK-A..LK-F IDs. Second-round escape present. |
| `brandbook/tools/candidates/` (29 SVGs) | round-1 (23) + round-2 LK-A..F (6) | VERIFIED | 29 total. 6 marks, 6 lockups, 6 mono, 3 favicons, 2 typemarks, 6 LK-* lockups. |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `lib/wordmark.mjs` | `assets/fonts/ibm-plex-sans_latest_latin-600-normal.woff2` | wawoff2.decompress + opentype.parse | VERIFIED | smoke.mjs passes; SUMMARY confirms wawoff2 CJS default import form used |
| `lib/lockup.mjs` | `lib/geometry.mjs` | import mark path + wordmark path, compose | VERIFIED | smoke.mjs tests the full chain; lockup writes data-gap-ratio attribute |
| `generate.mjs` | `presets.mjs` | import presets, render each via lib/lockup + lib/svg | VERIFIED | verify-logos confirms 29 candidates render correctly |
| `gallery.mjs` | `candidates/` | inline each candidate SVG into HTML at multiple sizes | VERIFIED | options-gallery.html contains both grounds, all stable IDs, zero external refs |
| `verify-logos.mjs` | `candidates/` | reads each candidate SVG, asserts structural rules | VERIFIED | script references CANDIDATES_DIR, runs against 29 candidates |
| `verify-logos.mjs` | `options-gallery.html` | asserts gallery completeness | VERIFIED | GALLERY_FILE constant wired; all gallery checks pass |

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| BRAND-03 | 19-01, 19-02, 19-03 | User chooses logo direction from >=6 options gallery with LOGO constraints enforced | SATISFIED | Both gate #2 decisions recorded in STATE.md. TV-1 mark locked. LK-B lockup locked. All LOGO-01..07 checks scripted and passing. REQUIREMENTS.md shows BRAND-03 checked off. |

---

### Anti-Patterns Found

No debt markers (TBD/FIXME/XXX), placeholder returns, or stub implementations found in files modified by this phase. The budget note below is informational:

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| `brandbook/` total disk usage | 6056 KB total; 1012 KB excluding gitignored node_modules | WARNING | node_modules is local dev-only, gitignored, not committed. 1012 KB (excluding node_modules) exceeds the <500 KB BRAND-05 final target but verify-logos.mjs correctly uses a 1024 KB Phase-19 tooling threshold (documented inline). Phase 20 prunes the round-1 losers and non-primary galleries; the final `brandbook/` root must satisfy <500 KB at Phase 22. Not a blocker. |

---

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| smoke.mjs renders valid mark + lockup | `node brandbook/tools/smoke.mjs` | Exit 0, "SMOKE TEST PASS" | PASS |
| verify-logos.mjs checks all 29 candidates | `node brandbook/tools/verify-logos.mjs` | Exit 0, 19/19 PASS lines | PASS |
| presets.mjs exports 6 marks + 2 typemarks | node -e import check | marks: 6, types: 2 | PASS |
| No rect in any candidate SVG | `grep -rc '<rect' candidates/*.svg` | 0 matches | PASS |
| No root brandbook SVGs | `ls brandbook/*.svg` | 0 files | PASS |
| node_modules not git-tracked | `git ls-files \| grep node_modules` | 0 results | PASS |
| No font binaries under brandbook/ | `find brandbook -name '*.woff2' -o -name '*.ttf'` | 0 files | PASS |

---

### Probe Execution

No probe scripts declared for this phase. Step 7c: SKIPPED (no `scripts/*/tests/probe-*.sh` pattern applies to this branding toolchain phase).

---

### Human Verification Required

None. Both gate #2 decisions are already recorded in STATE.md:

- Gate #2 partial: TV-1 "Span rail" mark locked; TYPE-1/TYPE-2 typemarks rejected (reasons documented in 19-03-SUMMARY.md §Diagnosis).
- Gate #2 final: TV-1 mark + LK-B "Mark-as-o" lockup locked.

The human choices occurred during phase execution (checkpoint:decision gates) and are reflected in the codebase. No further human input is required for phase verification.

---

### Gaps Summary

No gaps. All 7 must-have truths verified. All required artifacts exist and are substantive. All key links wired. BRAND-03 satisfied. Both user-choice gates completed and recorded.

The only NOTE is that `brandbook/` total disk (1012 KB excluding node_modules) exceeds the BRAND-05 final <500 KB target — but this is expected and documented: Phase 19's tooling threshold is set to 1024 KB in verify-logos.mjs with an inline note that Phase 20 pruning brings it back under budget. This is a WARNING for Phase 20/22 to address, not a Phase 19 blocker.

---

_Verified: 2026-06-11T17:30:00Z_
_Verifier: Claude (gsd-verifier)_
