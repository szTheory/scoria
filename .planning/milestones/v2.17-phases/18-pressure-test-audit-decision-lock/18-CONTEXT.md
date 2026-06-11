# Phase 18: Pressure-test audit + decision lock - Context

**Gathered:** 2026-06-11
**Status:** Ready for planning
**Source:** Plan-mode session (approved milestone plan) — discuss-phase skipped, context fully gathered

<domain>
## Phase Boundary

Execute the canonical 14-section pressure-test prompt (`prompts/brand-book-pressure-test-prompt.md`) against the AI-deep-research brand book (`prompts/scoria-brand-book-deep-research.md`), producing `brandbook/pressure-test.md` and a small programmatic WCAG contrast checker in `brandbook/tools/`. End with a Decisions Locked section approved by the user (gate #1). NO logo generation, NO token files, NO HTML brand book in this phase — those belong to phases 19–21. This phase creates only: the audit document, the contrast tool, and the locked decisions.

</domain>

<decisions>
## Implementation Decisions

### Audit scope and posture
- All 14 sections of the pressure-test prompt must be executed — executive judgment, brand DNA, 15-dimension scorecard (1–10 with Why/Risk/Fix each), surface stress tests (all ~26 surfaces), gaps by severity, recommended upgrades, token spec direction, logo system evaluation, visual examples guidance, voice/microcopy, landing/docs blueprint, repo artifact plan, prioritized actions, final quality gate.
- Every brand-book element gets a KEEP / TIGHTEN / REWORK / ADD / REMOVE verdict. "All killer no filler" — no churn for churn's sake; preserve what is strong.
- The brand book is a SEED, not gospel: fonts/colors/taglines are explicitly tweakable if the audit finds material improvements ("NOW is your chance to nail it").
- Suite-coherence lens is mandatory: compare against the Threadline brandbook (`/Users/jon/projects/threadline/brandbook/` — brand-book.md, pressure-test.md, index.html) and `prompts/sztheory-elixir-dna.md` (szTheory suite: Sigra, Threadline, Chimeway, Mailglass, Parapet...). Scoria must be distinct per-library but recognizably same-studio. Don't clone Threadline's identity; do rhyme with its artifact conventions.

### Contrast checking (programmatic, not vibes)
- A small Node script in `brandbook/tools/` (e.g. `contrast-check.mjs`) computes WCAG 2.1 relative-luminance contrast ratios for every documented fg/bg pairing in the brand book (§5 color system: text-on-Basalt-950, text-on-Ash-50, Ember-500 on dark, Scoria-600/700 on light, functional accent pairs on both surfaces, badge fills, etc.).
- Verdicts: pass AA normal (≥4.5:1), pass AA large/UI (≥3:1), fail. Results embedded as a table in pressure-test.md.
- No heavy deps — pure-math luminance calc, no npm install needed for the checker itself.
- The existing `assets/css/02-tokens.css` semantic pairings should also be checked (it implements the brand book), since the propagation verdict depends on whether SHIPPED pairings fail.

### Propagation verdict (locked policy)
- `brandbook/` becomes the canonical brand source. `assets/css/02-tokens.css` + precompiled `priv/static` CSS + `test/support/ds06_baseline.txt` are touched ONLY if the audit finds MATERIAL failures: WCAG AA contrast failures in shipped pairings, accessibility defects, or genuine coherence breaks. Cosmetic preference deltas stay brandbook-only.
- The audit must end with an explicit verdict: `propagation: required` (with the specific failing pairs) or `propagation: not-required`. This verdict feeds conditional BRAND-09 in Phase 22.

### Decisions Locked section + user gate #1
- pressure-test.md ends with (or is accompanied by) a "Decisions Locked" section covering: final tagline (the brand book offers "Trace the run. Prove the change. Ship the agent." as primary plus alternatives — pick/confirm one), one-liner, naming confirmation ("Scoria", never "Scoria AI"; feature names unchanged), palette deltas if any (with before/after hex), typography confirmation (IBM Plex Sans + JetBrains Mono unless audit finds material reason to change), logo direction guidance for Phase 19 (which of the 4 brand-book concepts are strongest), and the propagation verdict.
- Gate #1 is an AskUserQuestion checkpoint presented BY THE ORCHESTRATOR after execution (executor prepares the decision summary; the orchestrator asks). The user approves or adjusts before Phase 19 logo generation begins.

### Logo constraints to encode in the audit's Section 8 (feeds Phase 19)
- NO rectangular background/container shapes behind logomarks — marks break boundaries; negative space via fill-rule="evenodd" punched holes.
- Logotype optically TIGHT to the mark; main lockup has NO subtitle/slogan (separate subtitle variant allowed).
- Integrated logotype-only treatments (motif worked INTO letterforms) are wanted as first-class options, not just icon-left-of-text.
- The audit should evaluate the brand book's 4 logo directions (Cinder Mark, Trace Vesicle Mark, Cutaway Cone Mark, Aperture/Vesicle Mark) against scalability (16px favicon), monochrome survival, and distinctiveness, and rank them.

### Repo hygiene
- Everything new lives under `brandbook/` (self-contained). SVG/text only; <500KB total budget for the whole milestone. The audit doc and tools count against the budget.
- `prompts/scoria-brand-book-deep-research.md` stays untouched as historical input.

### Claude's Discretion
- Exact section ordering/formatting of pressure-test.md (follow the prompt's 14-section structure; Threadline's pressure-test.md is a format precedent but Scoria's may be deeper).
- Whether the Decisions Locked content lives at the top of pressure-test.md or as a clearly-marked final section.
- Contrast-script implementation details (output format, how pairings are enumerated).
- How deeply to analyze each of the ~26 stress-test surfaces (depth proportional to relevance; favicon/README/HexDocs/dashboard matter most).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Audit inputs
- `prompts/brand-book-pressure-test-prompt.md` — the verbatim 14-section audit prompt to execute (THE spec for pressure-test.md's structure)
- `prompts/scoria-brand-book-deep-research.md` — the brand book under audit (1,618 lines)
- `prompts/sztheory-elixir-dna.md` — szTheory suite DNA (multi-library architecture lens, Section 10)

### Implementation truth to audit against
- `assets/css/02-tokens.css` — shipped dashboard tokens (primitive + semantic; implements brand book §5/§6/§8/§12)
- `test/support/ds06_baseline.txt` — raw-color drift guard baseline (do NOT modify this phase)

### Suite precedent (read-only, outside repo)
- `/Users/jon/projects/threadline/brandbook/brand-book.md` — sibling library brand guide
- `/Users/jon/projects/threadline/brandbook/pressure-test.md` — sibling audit format precedent
- `/Users/jon/projects/threadline/brandbook/README.md` — maintenance-rules precedent

### Milestone context
- `/Users/jon/.claude/plans/we-have-scoria-brand-book-deep-research-majestic-penguin.md` — approved milestone plan (requirements BRAND-01..09, phase breakdown, logo methodology)

</canonical_refs>

<specifics>
## Specific Ideas

- Threadline's pressure-test.md is ~15KB; Scoria's should be at least as substantive (the brand book under audit is 3× larger than Threadline's was).
- The brand book's four tagline candidates appear in its positioning section; the primary is "Trace the run. Prove the change. Ship the agent." — the lock should confirm or replace with rationale.
- Known palette risk areas to check: Pumice-500 (#88786D) as "muted labels" on Basalt-950 (#11100F) likely sits near the AA boundary; Sulfur warning (#FFD166) on light surfaces; Molten-400 (#FF7A4D) as text; trace-purple pairings.
- The user's anti-pattern list for logos came from experience: "AI seems to always force a rectangular BG shape onto these logomarks and i do NOT like that."

</specifics>

<deferred>
## Deferred Ideas

- Logo generation tooling and options gallery — Phase 19.
- tokens.json/tokens.css authoring — Phase 21 (the audit SPECIFIES the token direction; Phase 21 builds it).
- brand-book.md rewrite — Phase 21 (the audit's verdicts drive it).
- Any dashboard CSS edits — Phase 22 conditional BRAND-09, only if verdict = required.

</deferred>

---

*Phase: 18-pressure-test-audit-decision-lock*
*Context gathered: 2026-06-11 via plan-mode session + approved milestone plan*
