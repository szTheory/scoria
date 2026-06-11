# Requirements: Scoria — v2.17 Vesicle (Brand System)

**Defined:** 2026-06-11
**Core Value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.
**Milestone goal:** Ship a pressure-tested, repo-canonical Scoria brand system in `brandbook/` — audited brand book, locked design tokens, a user-chosen programmatically generated logo system, and a professional standalone HTML brand book — wired into README, dashboard favicon/mark, and Hex/GitHub/HexDocs copy, without destabilizing the shipped v3.0 design-system work.

> Interjected milestone: v3.0 Control Room is paused at the phase 12/13 boundary (snapshot: `.planning/milestones/v3.0-REQUIREMENTS-paused.md`). Approved milestone plan: `/Users/jon/.claude/plans/we-have-scoria-brand-book-deep-research-majestic-penguin.md`. Source brand book: `prompts/scoria-brand-book-deep-research.md` (treated as a seed, not gospel). Sibling precedent: `/Users/jon/projects/threadline/brandbook/` (rhyme, don't clone). Suite lens: `prompts/sztheory-elixir-dna.md`.

## v1 Requirements

### Audit & Decisions

- [x] **BRAND-01**: A maintainer can read `brandbook/pressure-test.md` containing the full 14-section pressure-test of the brand book: every element tagged KEEP/TIGHTEN/REWORK/ADD/REMOVE, a 1–10 scorecard across 15 dimensions, surface stress tests (GitHub/HexDocs/dashboard/terminal/favicon/social), gaps ranked by severity, a programmatic WCAG-AA contrast verdict on all documented token pairings, a suite-coherence assessment vs the Threadline brandbook and szTheory DNA, and an explicit verdict on whether `assets/css/02-tokens.css` requires propagation (material failures only).
- [x] **BRAND-02**: The user has approved a Decisions Locked section (final tagline, palette/typography deltas if any, naming, dashboard-propagation verdict) before any logo or asset generation begins.

### Logo System

- [x] **BRAND-03**: The user can choose a logo direction from an options gallery presenting ≥6 genuinely distinct programmatic SVG mark+lockup options and ≥2 integrated logotype-only studies — rendered on dark AND light grounds at 256/64/32/16px with a monochrome row and in-situ mocks (browser-tab favicon strip, 24px dashboard sidebar, README header band) — with a ranked recommendation and a "none of these → second round" escape. Constraints enforced: zero rectangular background shapes (evenodd-punched negative space), logotype optically tight to the mark, no subtitle in the main lockup.
- [x] **BRAND-04**: The chosen direction is refined into a complete committed variant set: `logo-primary.svg` (dark), `logo-primary-light.svg`, `logo-mark.svg`, `logo-monochrome.svg` (currentColor), `logo-lockup-subtitle.svg`, `logotype-integrated.svg`, `favicon.svg` (simplified pixel-snapped path), `social-card.svg` — each with tight viewBoxes, clear-space/min-size rules, and a manual optical-correction pass.

### Canonical Brandbook

- [x] **BRAND-05**: A maintainer can use a self-contained `brandbook/` directory as the canonical brand source: `README.md` (maintenance rules), `brand-book.md` (post-audit rewrite, no filler), `pressure-test.md`, `tokens.json`, `tokens.css` (naming reconciled with `assets/css/02-tokens.css`), logo SVGs, `examples/*.svg` (palette, typography, components, terminal, readme-header, landing-hero, docs-page), and reproducible generation tooling in `brandbook/tools/` — SVG/text only, total < 500KB, zero binaries.
- [x] **BRAND-06**: A reviewer can open `brandbook/index.html` directly from `file://` as a professional, standalone HTML brand book covering identity, logo system, color, typography, tokens, voice/microcopy, UI guidance, and landing/docs blueprints — with no load-bearing network dependencies.

### Integration

- [ ] **BRAND-07**: The finalized brand is live on real surfaces: README header uses the chosen lockup (GitHub dark/light-aware) with an aligned badge row; the `/scoria` dashboard serves the new `favicon.svg` and the new mark in the sidebar brand slot (`lib/scoria_web/components/layouts.ex`); `mix.exs` package description, GitHub repo description, and HexDocs front copy use the finalized voice.

### Quality Gate

- [ ] **BRAND-08**: The milestone passes a scripted final quality gate: all documented fg/bg token pairs meet WCAG AA (≥4.5:1 normal / ≥3:1 large); 16px favicon legibility and monochrome-with-holes-intact reviews pass; no `<rect>` backgrounds in any logo SVG (grep-enforced) and all marks use `fill-rule="evenodd"`; `index.html` works offline; `du -s brandbook/` < 500KB with an html/md/json/css/svg-only extension allowlist; tokens.json ↔ tokens.css ↔ brand-book.md hex values are consistent; `mix test` is green including the DS-06 baseline (untouched unless conditional propagation fired).

### Conditional

- [ ] **BRAND-09** *(fires only if BRAND-01's verdict requires it)*: Material contrast/accessibility/coherence failures found by the audit are propagated into `assets/css/02-tokens.css`, the precompiled `priv/static` CSS, and a deliberately regenerated `test/support/ds06_baseline.txt` in one atomic plan, with the full test suite green and no semantic custom-property renames.

## Future Requirements

Deferred to later milestones (acknowledged, not in this roadmap).

- **BRAND-MOTION**: Brand-motion guidelines applied beyond the dashboard (docs site, landing page animations) — v3.0 Phase 16 owns dashboard motion.
- **BRAND-SITE**: An actual marketing landing page / docs site build-out — this milestone ships the *blueprint sections* in the brand book only.
- **BRAND-SWAG**: Sticker/print collateral — only if a real event need appears.
- **BRAND-SUITE**: Cross-library brand architecture formalization for the szTheory suite (shared grid/badge/docs patterns extracted from Threadline + Scoria precedents).

## Out of Scope

| Feature | Reason |
|---------|--------|
| Building a marketing website or docs site | Brand book includes blueprints; building pages is a separate milestone. |
| Binary raster assets (PNG exports, font files) | Repo-size discipline; SVG/text-first. Fonts already self-hosted under `priv/fonts/` for the dashboard. |
| Cosmetic re-theming of the shipped dashboard | `assets/css/02-tokens.css` changes only on material audit failures (BRAND-09); avoids thrash to v3.0's token gateway + DS-06 ratchet. |
| Mascots, 3D renders, AI-generated raster imagery | Off-brand (calm field-engineer archetype), not source-controllable, craft risk. |
| Renaming the library or changing feature naming | "Scoria" and feature names (Trace Explorer, Eval Workbench, …) are validated; audit may TIGHTEN copy, not rename. |
| v3.0 phases 13–17 work | Paused milestone; resumes after v2.17 archive. |

## Traceability

Each requirement maps to exactly one phase. Phase numbering continues from v3.0's reserved block (11–17); v2.17 takes phases 18–22.

| Requirement | Phase | Status |
|-------------|-------|--------|
| BRAND-01 | Phase 18 — Pressure-test audit + decision lock | Complete |
| BRAND-02 | Phase 18 — Pressure-test audit + decision lock | Complete |
| BRAND-03 | Phase 19 — Logo divergence + user choice | Complete |
| BRAND-04 | Phase 20 — Logo convergence: full variant set | Complete |
| BRAND-05 | Phase 21 — Tokens + brand book + standalone HTML | Complete |
| BRAND-06 | Phase 21 — Tokens + brand book + standalone HTML | Complete |
| BRAND-07 | Phase 22 — Integration + final quality gate | Pending |
| BRAND-08 | Phase 22 — Integration + final quality gate | Pending |
| BRAND-09 | Phase 22 — Integration + final quality gate (conditional plan) | Conditional |

**Coverage:**
- v1 requirements: 8 (+1 conditional)
- Mapped to phases: 9 ✓
- Unmapped: 0 ✓

---
*Requirements defined: 2026-06-11*
*Last updated: 2026-06-11 at v2.17 milestone start*
