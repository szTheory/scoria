# Scoria Brandbook

This directory contains the canonical Scoria brand system. It is intentionally self-contained and source-control friendly: SVG, text, Markdown, JSON, CSS, and HTML only.

Open `index.html` directly in a browser to review the visual brand book.
The Markdown files are the durable source text:

- `brand-book.md` — the canonical brand guide (identity, positioning, logo system, color, typography, voice, UI guidance, blueprints).
- `pressure-test.md` — brand QA record (audit verdicts, contrast table, decisions locked).
- `tokens.json` and `tokens.css` — docs/marketing implementation tokens (structured object + `:root` custom properties).
- `logo-primary.svg` — primary lockup for dark surfaces (LK-B Mark-as-o fused).
- `logo-primary-light.svg` — primary lockup for light surfaces (README, GitHub, documentation).
- `logo-mark.svg` — standalone mark (favicon and sidebar contexts).
- `logo-monochrome.svg` / `logotype-integrated.svg` — monochrome and integrated variants.
- `logo-lockup-subtitle.svg` — lockup with subtitle line (marketing long-form only).
- `favicon.svg`, `social-card.svg` — browser icon and social preview card.
- `examples/*.svg` — vector brand specimens (palette, typography, components, terminal, hero, docs mock).

## Two Token SSOTs

Scoria maintains **two distinct CSS token files** that serve different purposes but MUST have identical hex values:

| File | Selector | Scope | Purpose |
|------|----------|-------|---------|
| `assets/css/02-tokens.css` | `.scoria-root` | Dashboard runtime | Consumed by LiveView components at runtime |
| `brandbook/tokens.css` | `:root` | Docs and marketing | Copy-pasteable into any host page, no class coordination needed |

The dashboard runtime file uses `@layer scoria.tokens {}` and `.scoria-root` class scoping.
The brandbook file uses plain `:root` and `:root[data-theme="light"]` scoping.
The token names (`--scoria-*`) and hex values are identical in both files.

**To verify hex consistency across all sources:**

```
node brandbook/tools/check-consistency.mjs
```

This script asserts that `brandbook/tokens.css`, `assets/css/02-tokens.css`, and `brandbook/tokens.json` all agree on every primitive token hex value. Run it after editing any token file.

## Maintenance Rules

- Keep all brand artifacts in this directory unless production code explicitly needs them.
- **SVG, text, Markdown, JSON, CSS, and standalone HTML only.** No binary exports.
- Do not commit font files here. The dashboard self-hosts IBM Plex Sans and JetBrains Mono under `priv/fonts/`. This directory documents the font choices; it does not ship them.
- Do not duplicate the runtime CSS from `assets/css/`. If you change a token hex value, update **both** `assets/css/02-tokens.css` (the runtime SSOT) and `brandbook/tokens.css` (the docs SSOT), then run `node brandbook/tools/check-consistency.mjs` to confirm they agree.
- Do not edit `tokens.json` independently of `tokens.css`. The two files must stay in sync. The consistency checker covers the `raw.color` primitive block; update both files together.
- `tools/` contains Node.js scripts for logo generation and consistency checking. Run them from the repo root (e.g. `node brandbook/tools/check-consistency.mjs`).
- `tools/candidates/` contains historical exploration outputs. These are preserved for reference; do not treat them as current system files.
- Prefer SVG for all visual assets. Use `<text>` elements with system-fallback font stacks in example SVGs (not embedded font binaries).
- Keep each SVG file under 12 KB; the total `examples/` directory under 60 KB.
- Do not edit the repo-root `README.md` or `mix.exs` from this directory (Phase 22 scope).
- Never use `@import` or network font refs in `tokens.css`. The file must be self-contained.

## Best Current Defaults

**Positioning:** "AI ops for Phoenix apps."

**One-liner:** "Scoria is the Phoenix-native AI ops layer for LLM traces, evals, prompt versions, and tool governance."

**Hero headline (display treatment, three-line verb triplet):**
```
Trace the run.
Prove the change.
Ship the agent.
```

**Logo system:** LK-B Mark-as-o fused lockup is the primary. The full 8-variant set:
`logo-primary.svg` (dark), `logo-primary-light.svg` (light), `logo-mark.svg`, `logo-monochrome.svg`,
`logotype-integrated.svg`, `logo-lockup-subtitle.svg`, `favicon.svg`, `social-card.svg`.
Use the primary on dark backgrounds. Use the light variant on light/README/GitHub surfaces.
Clear-space rule: cap-height / 2 on all sides. Minimum sizes: 32px (mark), 120px width (lockup).

**Palette:** Volcanic dark-first. Ground: Basalt-950 (`#11100f`). Accent: Ember-500 (`#e65a32`). Full primitive scale in `tokens.json` `raw.color`.

**Typography:** IBM Plex Sans (UI text, all weights) + JetBrains Mono (code, traces, terminal output).

**Voice:** Calm. Exact. Useful. Senior-engineer register. Scoria, never "Scoria AI". Feature names unchanged: runs, spans, evals, prompts, approvals, connectors.
