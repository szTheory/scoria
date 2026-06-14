# Phase 20: Logo convergence — full variant set - Context

**Gathered:** 2026-06-11
**Status:** Ready for planning
**Source:** Gate #2 outcomes (rounds 1 + 2) + approved milestone plan

<domain>
## Phase Boundary

Refine the user-chosen direction — **TV-1 "Span rail" mark + LK-B "Mark-as-o" fused lockup** — into the complete committed variant set at `brandbook/` ROOT, with clear-space/min-size rules, a manual optical-correction pass, and pruning of losing candidates. Ends with a lightweight confirm checkpoint (screenshot/visual strip, a 2-minute "ship it" — NOT a second gallery). NO tokens/brand-book/index.html (Phase 21), NO integration into README/dashboard (Phase 22).

</domain>

<decisions>
## Implementation Decisions

### Locked direction (gate #2, binding)
- Mark: **TV-1 "Span rail"** (`brandbook/tools/candidates/TV-1-mark.svg`) — tight vertical trace-tree hole hierarchy, closed silhouette. Geometry stays; optical micro-tuning only.
- Primary lockup: **LK-B "Mark-as-o"** (`brandbook/tools/candidates/LK-B-lockup.svg`) — the TV-1 mark sits AS the 'o' of "Scoria" (x-height sized, advance preserved, holes = counter). This fused treatment IS the brand's primary logo.
- Rejected: TYPE-1/TYPE-2 ring-o/porous-a studies; LK-A/C/D/E/F lockup variations. Classic mark-left lockup (LK-A) was NOT selected — do not ship it as a variant.

### Variant set (BRAND-04 census → brandbook/ root)
| File | Content |
|---|---|
| `logo-primary.svg` | LK-B fused lockup, dark-surface colorway (letters White-Hot #FFF9F3; the mark-'o' MAY be Ember-500 #E65A32 per audit §8 "reserve ember 'o' for primary" — craft pass decides single vs two-tone, document the call) |
| `logo-primary-light.svg` | Same lockup, light-surface colorway (letters Basalt-950 #11100F or Scoria-900; mark-'o' Scoria-600 #B94F31 if two-tone) |
| `logo-mark.svg` | TV-1 mark alone, brand color via currentColor default or Ember fill — match Threadline conventions (title/desc, role="img") |
| `logo-monochrome.svg` | LK-B fused lockup, single `currentColor` fill, holes intact |
| `logo-lockup-subtitle.svg` | LK-B + "AI ops for Phoenix apps." set beneath in IBM Plex Sans (outlined paths, smaller size, tracking open) — the ONLY variant with a subtitle |
| `logotype-integrated.svg` | The fused wordmark in single-color form (= monochrome-style primary; since LK-B IS the integrated logotype, this file is the canonical "typemark" deliverable — document that primary and integrated share lineage) |
| `favicon.svg` | TV-1 `holes16` 3-hole simplified path, pixel-grid snapped for 16px rendering, ≤1KB |
| `social-card.svg` | 1280×640, Basalt-950 ground (allowed here — the card IS a bounded artwork, not a logo background), LK-B lockup + tagline "AI ops for Phoenix apps." + hex/GitHub hint text; text outlined or system-font fallback declared |

### Craft/optical pass requirements
- Manual optical-correction review of every variant: overshoot of the mark-'o' versus the round letters' overshoot (Plex 'o' extends slightly past baseline/x-height; the mark replacing it must not look clipped or floating), spacing rhythm around the substituted glyph, hole clearances at small sizes, two-tone weight balance (ink-density check numerically as proxy).
- LOGO-01..07 still bind: no rects, evenodd, no strokes, tight viewBoxes, coordinates ≤2 decimals.
- Clear-space + min-size spec: written as a short markdown block (goes into Phase 21's brand-book.md; for now commit as `brandbook/tools/variant-spec.md` or inline in SUMMARY) — clearspace = cap-height/2 around the lockup; min sizes: primary lockup ≥120px wide, mark ≥20px, favicon exact at 16/32px.
- Extend `verify-logos.mjs` (or add a root check) so the 8 root SVGs pass the same structural gates; social-card.svg exempt from "no rect" ONLY for its card-ground rect (documented exemption — it is a bounded canvas artwork, not a logo).

### Pruning (repo-size discipline)
- Delete losing candidates from `brandbook/tools/candidates/` (keep only TV-1 lineage files + LK-B); delete BOTH gallery HTML files (options-gallery.html ~?KB, options-gallery-round2.html ~255KB) — they served gate #2 and live on in git history.
- Keep: generator toolchain (lib/, presets.mjs — all presets stay in source for reproducibility, they are small text), smoke.mjs, verify-logos.mjs, contrast-check.mjs, package.json/lockfile.
- After pruning, `du -sk brandbook/` should land well under the 500KB BRAND-05 budget.

### Confirm checkpoint (lightweight)
- Build a SMALL `brandbook/tools/final-variants.html` strip (or reuse verify output + open the SVGs directly) showing the 8 variants on both grounds at realistic sizes; orchestrator opens it and asks a single "ship it / adjust" question. NOT another multi-option gallery. (This file is also pruned in Phase 22 if budget demands; it is small.)

### Claude's Discretion
- Single-color vs two-tone primary (document rationale; two-tone Ember 'o' is the audit's lean).
- Whether logotype-integrated.svg is byte-identical to a single-color primary or has its own tuning.
- Social-card composition details (keep calm, evidence-not-hype voice).
- Exact pixel-snapping technique for favicon.

</decisions>

<canonical_refs>
## Canonical References

- `brandbook/pressure-test.md` §SECTION 8 (logo rules LOGO-01..07, clearspace/min-size guidance, "reserve ember 'o' for the primary lockup") + §Decisions Locked + §Gate #1/#2 records
- `brandbook/tools/candidates/TV-1-mark.svg`, `TV-1-fav.svg`, `LK-B-lockup.svg` — the chosen artwork
- `brandbook/tools/presets.mjs` (TV-1 preset + holes16), `lib/*.mjs` (generation APIs), `verify-logos.mjs`
- `/Users/jon/projects/threadline/brandbook/logo-primary.svg`, `favicon.svg`, `social-card.svg` — sibling conventions (read-only)
- `.planning/phases/19-logo-divergence-user-choice/19-03-SUMMARY.md` — second-round diagnosis + LK-B craft notes (ink-density matching, advance preservation)

</canonical_refs>

<specifics>
## Specific Ideas

- The LK-B executor measured: mark at x-height = 56.7u wide vs 56.3u 'o' advance; ink density 0.61 vs letters 0.57 — these are the numbers the optical pass starts from.
- Threadline ships `logo-primary.svg` (dark) + `logo-primary-light.svg` — same census; Scoria mirrors it so suite tooling can assume the pattern.
- Favicon: snap the 3 holes to even coordinates in a 16-unit grid; verify each hole ≥1.5px radius at 16px.

</specifics>

<deferred>
## Deferred Ideas

- tokens.json/tokens.css, brand-book.md, examples/*.svg, index.html — Phase 21.
- README/dashboard/Hex integration — Phase 22.
- Final <500KB budget gate — Phase 22 (pruning here should already land it).

</deferred>

---

*Phase: 20-logo-convergence-variant-set*
*Context gathered: 2026-06-11 from gate #2 outcomes*
