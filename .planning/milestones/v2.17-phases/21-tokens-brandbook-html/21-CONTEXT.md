# Phase 21: Tokens + brand book + standalone HTML - Context

**Gathered:** 2026-06-11
**Status:** Ready for planning
**Source:** Gates #1/#2 locked decisions + audit verdicts + shipped Phase 20 variant set

<domain>
## Phase Boundary

Author the canonical brandbook content artifacts: `brandbook/tokens.json` + `brandbook/tokens.css`, the post-audit `brandbook/brand-book.md` rewrite, `brandbook/examples/*.svg` (7 specimens), the professional standalone `brandbook/index.html`, and `brandbook/README.md` (maintenance rules). NO integration into README/dashboard/mix.exs (Phase 22). No new logo artwork (Phase 20 shipped it).

</domain>

<decisions>
## Implementation Decisions

### Locked inputs (binding — do not re-litigate)
- Tagline: **"AI ops for Phoenix apps."** (primary). "Trace the run. Prove the change. Ship the agent." = hero-headline treatment only. Hierarchy per pressure-test.md §Decisions Locked.
- One-liner: "Scoria is the Phoenix-native AI ops layer for LLM traces, evals, prompt versions, and tool governance."
- Palette: NO deltas — hex values identical to `assets/css/02-tokens.css` primitives. Typography: IBM Plex Sans + JetBrains Mono.
- Logo system: the 8 shipped root SVGs + `brandbook/tools/variant-spec.md` (clear-space cap-height/2, min-sizes). LK-B "Mark-as-o" fused lockup is the primary; mark-left "classic" lockups are NOT part of the system.
- Naming: "Scoria", never "Scoria AI". Feature names unchanged.

### tokens.json + tokens.css
- Mirror Threadline's shape (tokens.json structured object; tokens.css plain `:root` custom properties) but with Scoria's two-tier discipline: primitives (basalt/char/graphite/pumice/tuff/ash/scoria/ember/molten/cinder + functional accent pairs) AND semantic roles (surface/text/border/action/focus/code/callout + state tokens: default/hover/active/focus/disabled/selected/success/warning/error/info/subtle/muted) per the audit's SECTION 7 spec.
- Naming reconciled with `assets/css/02-tokens.css`: same primitive names WITHOUT the `--scoria-` prefix requirement decision — actually KEEP the `--scoria-` prefix in tokens.css so values are copy-pasteable into any host page without collision, and document that `assets/css/02-tokens.css` (`.scoria-root`-scoped) remains the dashboard runtime SSOT while `brandbook/tokens.css` (`:root`-scoped) is the docs/marketing SSOT. Hex values MUST be identical (Phase 22 gate checks tokens.json ↔ tokens.css ↔ brand-book.md consistency; also verify against 02-tokens.css).
- Typography/spacing/radius/motion tokens included (from brand book §6/§8/§12 as audited).

### brand-book.md (the post-audit rewrite — all killer no filler)
- This REPLACES the 1,618-line deep-research doc as the canonical guide. Target: dense, buildable, ~about Threadline's brand-book.md length ×1.5–2 (roughly 400–700 lines). The deep-research doc stays in prompts/ as history; pressure-test.md stays as QA record.
- Structure (apply every KEEP/TIGHTEN/REWORK verdict from the audit): identity & positioning (essence, audience, archetype, naming, tagline hierarchy, one-liner + ready-to-use copy blocks from audit §10), logo system (the 8 variants, usage + misuse rules, clear-space/min-size from variant-spec.md), color (primitives + semantic roles + the contrast table verdicts; the text-subtle constraint warning), typography (Plex/JetBrains, weights, scale), voice & microcopy (calm/exact/useful, say-this-not-this, error/success/empty-state styles), UI guidance (states, components pointer to ui.ex), landing/docs blueprints (audit §11), accessibility rules, do/don't list.
- Copy blocks must be the FINAL ready-to-paste versions (Hex description, GitHub description, README opener, hero headline/subhead, CTAs, 3 feature blurbs, 3 why-this-exists bullets, example error/empty/success microcopy, release-note style) — Phase 22 consumes these verbatim.

### examples/*.svg (7 specimens, mirroring Threadline's census)
- palette.svg (swatch grid with hex labels, both surface groups), typography.svg (Plex/JetBrains specimen with brand text), components.svg (button/badge/callout/card mock in brand tokens), terminal.svg (dark terminal snippet mock with `mix scoria.install` + evidence-voice output), readme-header.svg (the README hero band using logo-primary artwork), landing-hero.svg (hero headline treatment: verb-triplet three-line + tagline subhead + CTAs), docs-page.svg (HexDocs-ish page mock).
- All hand-authorable SVG with `<text>` + system-fallback font stacks (Threadline precedent — examples are illustrations, not pixel-perfect product UI). Reuse the shipped logo path data where logos appear (copy `d` strings; do not redraw).
- Keep each ≤12KB; total examples/ ≤60KB.

### index.html (the professional standalone brand book — BRAND-06)
- Single file at `brandbook/index.html`, opens from `file://`. Relative references to sibling files (logo SVGs via `<img src="logo-primary.svg">`, examples via `<img src="examples/...">`) are ALLOWED and preferred over inlining everything — the brandbook directory ships as a unit. Inline only the small mark where decoration needs currentColor.
- Zero load-bearing network refs (a Google-Fonts `<link>` is permitted ONLY if the page is fully readable without it — system fallback stack first; Threadline precedent allows it but never load-bearing).
- Section skeleton (rhyme with Threadline's index.html, Scoria volcanic dark-first art direction): hero (logo + tagline + one-liner), executive judgment summary (from audit), brand DNA, logo system (all variants on both grounds + usage rules), color (interactive-ish swatch grid from tokens), typography, voice & microcopy (say/don't tables, copy blocks), UI guidance, blueprints, artifact index (what lives where in the repo), QA/quality-gate summary with the contrast table.
- Page styled WITH the brand tokens (dark-first, Basalt-950 ground, warm text, ember accents; light sections where contrast comparison demands). Professional > clever; target ≤90KB.
- Title: "Scoria Brand Book". Budget note: Phase 22 prunes final-variants.html + gallery builder scripts (~150KB), so Phase 21 may add up to ~140KB total and still land under the 500KB gate.

### brandbook/README.md
- Mirror Threadline's: what this directory is, open index.html, which files are source-of-truth (brand-book.md), maintenance rules (SVG/text only, no binaries, no font files, tools regenerate logos, dashboard runtime CSS is separate SSOT, candidates are historical), best-current-defaults summary (positioning, tagline, logo system, palette, voice one-liners).

### Claude's Discretion
- index.html visual design details (within brand tokens), exact example compositions, brand-book.md section ordering.
- tokens.json schema details (flat vs nested — prefer Threadline-compatible nesting for suite tooling).

</decisions>

<canonical_refs>
## Canonical References

- `brandbook/pressure-test.md` — §Decisions Locked + Gate records (locked copy), §6 (upgrade verdicts), §7 (token spec + contrast table), §9 (visual examples guidance), §10 (voice + copy blocks), §11 (blueprints), §12 (artifact plan), §14 (quality gate)
- `assets/css/02-tokens.css` — hex SSOT for primitives + semantic naming reference
- `brandbook/logo-*.svg`, `favicon.svg`, `social-card.svg`, `brandbook/tools/variant-spec.md` — shipped logo system
- `/Users/jon/projects/threadline/brandbook/brand-book.md`, `index.html`, `tokens.json`, `tokens.css`, `README.md`, `examples/*.svg` — sibling conventions (read-only; rhyme, don't clone)
- `prompts/scoria-brand-book-deep-research.md` — source material for sections the audit KEEPs (motion rules §12, component language §9/§10, feature naming §15)

</canonical_refs>

<specifics>
## Specific Ideas

- The contrast table from pressure-test.md §7 should appear in both brand-book.md (abbreviated: the constraints that matter) and index.html (the full verdict table is fine).
- Voice examples should use real Scoria nouns (runs, spans, evals, prompts, approvals, connectors) — e.g. "The run failed during lookup_order. The tool returned a 403 for actor usr_184."
- index.html hero: dark ground, logo-primary.svg, tagline, one-liner, then the three-line verb-triplet as the display treatment beneath — demonstrating the locked hierarchy.

</specifics>

<deferred>
## Deferred Ideas

- README/dashboard/mix.exs integration, final pruning (final-variants.html + gallery-*.mjs), <500KB gate, hex-consistency script run — Phase 22.

</deferred>

---

*Phase: 21-tokens-brandbook-html*
*Context gathered: 2026-06-11*
