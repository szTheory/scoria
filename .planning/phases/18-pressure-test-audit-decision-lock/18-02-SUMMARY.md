---
phase: 18-pressure-test-audit-decision-lock
plan: 02
subsystem: brand
tags: [brand, logo, voice, wcag, audit, design-tokens, copy, decisions-locked]
dependency_graph:
  requires:
    - phase: 18-01
      provides: "brandbook/pressure-test.md sections 1–7; contrast-check.mjs; 52-pairing WCAG audit (0 FAIL)"
  provides:
    - "brandbook/pressure-test.md completed (Sections 8–14 + Decisions Locked), 1,304 lines"
    - "BRAND-01 satisfied: all 14 sections of the canonical pressure-test complete"
    - "BRAND-02 ready: Decisions Locked section — tagline, one-liner, naming, palette deltas, typography, logo directions, propagation verdict"
    - "propagation: not-required — confirmed via usage audit of --scoria-text-subtle in lib/scoria_web/"
    - "Logo direction ranking + LOGO-01 through LOGO-07 hard constraints encoded for Phase 19"
    - "15 concrete copy blocks ready for Phase 21/22 (Hex description, GitHub description, README opener, hero headline, CTAs, blurbs)"
  affects:
    - "Phase 19: logo divergence — must read Section 8 (ranked directions + LOGO-01–07 constraints) before generating any SVG"
    - "Phase 20: logo convergence — hard rules gate which Phase 19 candidates advance"
    - "Phase 21: brand-book rewrite + tokens — reads Sections 7–12 for token gaps and brandbook/ directory structure"
    - "Phase 22: integration pass — BRAND-09 conditional does NOT fire (propagation not-required); reads Section 10 copy blocks"
tech-stack:
  added: []
  patterns:
    - "LOGO-01–07 rule naming system: hard constraints named as RULE identifiers so Phase 19 can reference them without re-litigating"
    - "Decisions Locked as standalone skimmable section: self-contained for gate #1 review; separate from full audit narrative"
    - "Usage grep audit to ground propagation verdict: concrete file:line evidence before declaring not-required"
key-files:
  created: []
  modified:
    - "brandbook/pressure-test.md — Sections 8–14 appended (605 lines) + Decisions Locked appended (111 lines); total 1,304 lines"
key-decisions:
  - "Final tagline locked: 'Trace the run. Prove the change. Ship the agent.' (primary brand-book candidate confirmed; three-line landing-hero treatment)"
  - "One-liner TIGHTENED: nouns over gerunds; 'tool governance' over 'governing LLM apps'"
  - "Naming confirmed: Scoria (never Scoria AI); feature names unchanged"
  - "Palette deltas: none — 52-pairing audit shows 0 FAIL; no hex changes warranted; cosmetic preferences stay brandbook-only"
  - "Typography: IBM Plex Sans + JetBrains Mono confirmed KEEP"
  - "Logo direction: Trace Vesicle Mark ranked #1; Cinder Mark #2 (fallback); Aperture study-only; Cutaway Cone deprioritized"
  - "propagation: not-required — --scoria-text-subtle sole shipped usage is a 16x16 SVG sort icon (ui.ex:653), UI component context, PASS-LARGE sufficient per WCAG 2.1 SC 1.4.11; assets/css/02-tokens.css untouched"
  - "LOGO-01–07 hard constraints encoded in Section 8 for Phase 19 inheritance: no rect backgrounds, evenodd holes, tight lockup, no subtitle in primary lockup, integrated typemark first-class, 16px test pass/fail, monochrome test pass/fail"
patterns-established:
  - "Brand audit section structure: KEEP/TIGHTEN/REWORK/ADD/REMOVE verdicts per section, then Decisions Locked as final confirmation layer"
  - "Propagation verdict requires usage grep evidence, not just ratio lookup — concrete file:line citation before declaring not-required"
requirements-completed: [BRAND-01, BRAND-02]
duration: ~60min
completed: "2026-06-11"
---

# Phase 18 Plan 02: Pressure-Test Sections 8–14 + Decisions Locked Summary

**Completed the 14-section brand audit with ranked logo directions (Trace Vesicle Mark #1), LOGO-01–07 hard constraints for Phase 19, 15 production-ready copy blocks, and a locked Decisions section ending in `propagation: not-required` (confirmed by grep audit of --scoria-text-subtle usage in lib/scoria_web/).**

## Performance

- **Duration:** ~60 min
- **Started:** 2026-06-11
- **Completed:** 2026-06-11
- **Tasks:** 2 (+ 1 checkpoint:decision)
- **Files modified:** 1 (`brandbook/pressure-test.md`)

## Accomplishments

- Sections 8–14 appended (605 lines): logo system ranking with scored table, visual examples guidance, voice system confirmation + 15 concrete copy blocks, landing page and README blueprints, repo artifact plan with CI/lint checks, prioritized action plan mapped to Phases 19–22, and a final quality gate answering all 8 questions.
- Section 8 encodes LOGO-01 through LOGO-07 as named hard constraints — no rectangular backgrounds, evenodd punched holes, logotype optically tight (~0.35–0.5× cap height), no subtitle in primary lockup, integrated typemark as first-class option, 16px favicon test pass/fail, monochrome test pass/fail. Phase 19 inherits these by name.
- Decisions Locked section appended (111 lines): all seven required fields (tagline, one-liner, naming, palette deltas, typography, logo guidance, propagation verdict), self-contained for gate #1 review.
- Propagation verdict confirmed `not-required` via usage audit: `--scoria-text-subtle` appears only at `lib/scoria_web/ui.ex:653` as a 16×16 SVG sort icon fill — UI component context, WCAG 2.1 SC 1.4.11 requires ≥3:1 for non-text components, all four surface ratios (4.48, 4.29, 3.91, 4.06) satisfy this. No body text usage found.

## Task Commits

1. **Task 1: Sections 8–14** - `0de71a8` (feat)
2. **Task 2: Decisions Locked + propagation verdict** - `030673d` (feat)

## Files Created/Modified

- `/Users/jon/projects/scoria/brandbook/pressure-test.md` — Sections 8–14 appended after Section 7; Decisions Locked appended after Section 14; total 1,304 lines (was 589)

## Decisions Made

- **Tagline:** "Trace the run. Prove the change. Ship the agent." — confirmed as final primary. "AI ops for Phoenix apps." approved for secondary contexts (subheadline, Hex.pm, social card). "Make the fire inspectable." approved for stickers and release taglines.
- **One-liner tightened:** nouns over gerunds; "tool governance" replaces "governing LLM apps" for better scannability.
- **Logo direction #1:** Trace Vesicle Mark — structured hole arrangement (trace-node hierarchy) gives the mark a readable internal logic; best favicon discipline; orthogonal to Threadline's line motif.
- **Propagation not-required:** The one shipped usage of `--scoria-text-subtle` is a sort-direction SVG icon (UI component), not body text. The WCAG 2.1 SC 1.4.11 standard (≥3:1 for non-text) is satisfied by all four ratios (lowest: 3.91:1 on light surface-app).

## Deviations from Plan

None — plan executed exactly as written. Sections 8–14 and the Decisions Locked section are complete, all acceptance criteria pass (verified via the automated check loop). The propagation verdict follows directly from the contrast table produced in 18-01 and the grep audit of `lib/scoria_web/` conducted in this plan.

## Known Stubs

None. All copy blocks in Section 10 are concrete and ready to use. The visual examples in Section 9 are documented guidance (no SVG artifacts yet — those are Phase 21 deliverables, not stubs of Phase 18's scope).

## Threat Flags

None. `brandbook/pressure-test.md` is a documentation artifact with no network endpoints, auth paths, file writes, or schema changes.

## Self-Check: PASSED

- `brandbook/pressure-test.md` exists at 1,304 lines: confirmed
- All 14 section headings verbatim: confirmed (verify loop — no MISSING lines)
- `sec1_still_present=1`: confirmed (Sections 1–7 intact)
- `logo_dirs=13`: confirmed (≥4 references to all four logo directions)
- `constraints=45`: confirmed (≥5 references to evenodd/rectangular/favicon/optically tight/subtitle)
- `## Decisions Locked` heading present: confirmed
- `verdict=1`: confirmed (exactly one `propagation: not-required` line)
- `fields=67`: confirmed (≥7 required lock fields covered)
- IBM Plex Sans + JetBrains Mono typography confirmed: confirmed
- Naming rejection ("never Scoria AI"): confirmed
- Commits `0de71a8` and `030673d` exist: confirmed

## Next Phase Readiness

Phase 19 (logo divergence) is unblocked after gate #1 user approval. It must read:
- `brandbook/pressure-test.md` Section 8 for ranked directions and LOGO-01–07 constraints
- `brandbook/pressure-test.md` Decisions Locked for the approved #1 direction
- `prompts/scoria-brand-book-deep-research.md` §4 for the detailed mark structure descriptions

The propagation verdict (`not-required`) clears BRAND-09 conditional — Phase 22 does not need to schedule a token propagation pass unless a future contrast audit finds new failures.

---
*Phase: 18-pressure-test-audit-decision-lock*
*Completed: 2026-06-11*
