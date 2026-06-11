# Phase 22: Integration + final quality gate - Context

**Gathered:** 2026-06-11
**Status:** Ready for planning
**Source:** Locked decisions + brand-book.md copy blocks + surface survey

<domain>
## Phase Boundary

Wire the finalized brand onto real surfaces (README header + badges, dashboard favicon + sidebar mark, mix.exs/GitHub/HexDocs copy), run the scripted final quality gate, and leave the milestone ready for audit/archive. BRAND-09 conditional does NOT fire (propagation: not-required, gate #1). NO dashboard CSS/token changes; NO ds06_baseline.txt changes.

</domain>

<decisions>
## Implementation Decisions

### README header (repo root README.md)
- Replace the plain `# Scoria` H1 with a centered brand header: GitHub dark/light-aware logo via `<picture>` — `<source media="(prefers-color-scheme: dark)" srcset="brandbook/logo-primary.svg">` + `<img src="brandbook/logo-primary-light.svg" alt="Scoria" width="~360">`. Tagline line "AI ops for Phoenix apps." beneath (plain text or small markdown). Keep an `# Scoria` heading OR an alt-equipped image serving as the accessible title — note HexDocs renders README as docs main page: relative image paths break on hexdocs.pm unless the files ship in the package. DECISION: keep images by absolute GitHub raw URLs? NO — prefer relative paths for GitHub plus adding `brandbook/logo-primary.svg`, `brandbook/logo-primary-light.svg`, `brandbook/favicon.svg` to the Hex package files list ONLY IF cheap; otherwise accept that hexdocs strips the picture element and ensure the README still reads correctly without the image (alt text + the H1 kept). Keep it simple and robust: retain `# Scoria` H1 below the picture block, so every renderer degrades gracefully.
- Badge row: KEEP existing badges (CI, Hex.pm, Hex Docs, License, Elixir, Phoenix) — they are functional and already consistent; no new badge styling work (audit verdict KEEP).
- Replace the README opening paragraph with the brand-book.md "README opener" copy block (final, paste verbatim). Do not restructure the rest of the README.

### Dashboard favicon + sidebar mark
- `lib/scoria_web/components/layouts.ex` `brand_mark/1` (the `scoria-brand__mark` 24×24 SVG): replace the placeholder cinder blob + circles with the REAL TV-1 mark — adapt the shipped `brandbook/logo-mark.svg` path into a 24×24 viewBox single evenodd path, `fill="var(--scoria-ember-500)"`, no stroke (current placeholder uses stroke + opacity layers; the real mark is a solid evenodd punch). Keep the `scoria-brand__mark` class + attr API unchanged. DS-06 guard: use CSS vars only, no raw palette classes.
- Favicon: there is currently NO favicon wiring in ScoriaWeb layouts (grep found none). Add a `<link rel="icon" type="image/svg+xml" href={...}>` to the dashboard root layout pointing at a NEW static asset `priv/static/favicon.svg` (copy of brandbook/favicon.svg) served through Scoria's existing static pipeline (check how priv/static assets are referenced — `~p` sigil or Plug.Static path under /scoria assets; follow the existing CSS/JS asset linking pattern in the layout). If the host-app integration makes dashboard favicon injection fragile (host pages own <head> in some embedding modes), wire it in Scoria's own root layout only and document the boundary.
- `mix test` must stay green (DS-06 baseline untouched; LiveView tests unaffected by markup-only mark swap — verify).

### Hex/GitHub/HexDocs copy (paste from brand-book.md copy blocks verbatim)
- `mix.exs` `description/0`: replace with the final Hex.pm package description from brand-book.md (the one-liner-derived block).
- GitHub repo description via `gh repo edit --description "..."` (current: "Phoenix-native AI application quality layer with observability, evaluations, workflows, and knowledge grounding." → final brand copy).
- HexDocs front: `docs main: "readme"` — the README opener update above IS the HexDocs front copy. No extra docs file needed.
- Do NOT bump @version or touch deps/CHANGELOG (release-please owns that).

### Final quality gate (scripted — a single brandbook/tools/quality-gate.mjs or shell sequence, committed)
1. `node brandbook/tools/contrast-check.mjs` — all documented pairs ≥4.5:1 normal / ≥3:1 large (0 FAIL).
2. `node brandbook/tools/verify-logos.mjs` — exit 0 (structural: no-rect, evenodd, favicon size, budget <500KB).
3. `node brandbook/tools/check-consistency.mjs` — 4-source hex agreement.
4. Extension allowlist: every file under brandbook/ (excluding tools/node_modules) matches html|md|json|css|svg|mjs|gitignore|lock — zero binaries.
5. index.html offline: zero http(s) refs (xmlns excepted), all src= resolve.
6. 16px favicon legibility + monochrome-holes-intact: structural checks scripted; visual confirmation rolled into the milestone UAT (user already approved at Phase 20 ship-it).
7. `mix test` green (full default suite incl. DS-06 ratchet) — run AFTER the layouts.ex change.
8. README renders: verify relative image paths exist; (GitHub dark/light visual check = milestone UAT item).

### Closeout (after gate passes — orchestrator-owned, not in plans)
- /gsd:verify-work UAT → milestone audit → archive v2.17 → resume v3.0. Plans should NOT do these.

### Claude's Discretion
- Exact README header composition (centered vs left; width).
- How the favicon link is injected (root layout vs html head component) following existing asset patterns.
- quality-gate as one mjs script vs documented shell sequence (prefer one script: `node brandbook/tools/quality-gate.mjs` running/aggregating all checks incl. spawning mix test, exit 0/1).

</decisions>

<canonical_refs>
## Canonical References

- `brandbook/brand-book.md` — §copy blocks (README opener, Hex description, GitHub description — paste verbatim)
- `brandbook/logo-primary.svg`, `logo-primary-light.svg`, `logo-mark.svg`, `favicon.svg` — shipped assets
- `lib/scoria_web/components/layouts.ex` — brand_mark/1 (~line 15-35) + root layout asset-link patterns
- `README.md` (root) — current header/badges/opening (lines 1-12)
- `mix.exs` — description/0 (~line 118), docs main: "readme"
- `test/support/ds06_baseline.txt` — must remain untouched
- Current GitHub description: "Phoenix-native AI application quality layer with observability, evaluations, workflows, and knowledge grounding."

</canonical_refs>

<specifics>
## Specific Ideas

- The TV-1 mark's full-size path is in brandbook/logo-mark.svg; the 24×24 adaptation can reuse the favicon's 3-hole simplified geometry (brandbook/favicon.svg) if the full 4-hole mark muddies at 24px — judge by hole radii ≥1.5px at 24px.
- layouts.ex `brand_mark` doc comment should keep describing the mark ("Porous-cinder brand mark...") — update wording to reference TV-1 Span rail.

</specifics>

<deferred>
## Deferred Ideas

- BRAND-09 propagation (does not fire). Marketing site build. PNG exports. Hex package files-list addition for brandbook assets (only if README image handling demands it and it is cheap — otherwise note as future).

</deferred>

---

*Phase: 22-integration-quality-gate*
*Context gathered: 2026-06-11*
