# Phase 38: Foundations And Primitive Controls - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-02
**Phase:** 38-Foundations And Primitive Controls
**Areas discussed:** Toast/flash legibility, Copy-control affordance, Stats convergence, Size & density scale
**Mode note:** User stepped away after the gray-area selection prompt (60s no-response). Per workflow
guidance, areas were resolved with recommended design-system defaults grounded in the existing tokens,
`ScoriaWeb.UI`, and Phase 36/37 decisions. Decisions are revisable — re-run `/gsd-discuss-phase 38`
("Update it") to steer differently before planning.

---

## Toast/flash legibility (Criterion 4 · RISK-TOAST-LEGIBILITY)

| Option | Description | Selected |
|--------|-------------|----------|
| Opaque surface + tone accent | Toast body on solid `--scoria-surface`; status via border/dot/text | ✓ |
| Keep tint, composite over opaque base + backdrop blur | Preserve tone tint but block bleed-through with a base layer | (partial — allowed as impl detail) |
| Stronger scrim/shadow only | Elevate without changing background opacity | |

**Choice:** Opaque toast tokens (D-01/D-02), same treatment for floating flashes (D-03), proven in
light+dark against the Phase 37 dense-approvals/toast-overlay fixture (D-04). Verified defect root:
translucent `--scoria-tone-*-bg` `color-mix(...transparent)` tints rendered directly by `.scoria-toast`.

---

## Stats convergence (Criterion 3)

| Option | Description | Selected |
|--------|-------------|----------|
| Converge on `overview_stats/1` | Collapse the duplicate `signal_strip/1` into one component; keep `metric/1` distinct | ✓ |
| Converge on `signal_strip/1` | Keep signal_strip as canonical instead | |
| Fold metric/1 in too | Single mega-stat component | |

**Choice:** One canonical stat component, recommended `overview_stats/1` (D-05/D-06); `metric/1` stays
separate (D-07); migrate call sites off legacy `.scoria-signal*` (D-08). Verified: `overview_stats` and
`signal_strip` are near-identical `<dl>` label/value/detail/tone patterns.

---

## Copy-control affordance (Criterion 2/5 · "oversized copy icons")

| Option | Description | Selected |
|--------|-------------|----------|
| `:sm` scale, always-visible, inline confirm | Capped glyph, ghost weight, "Copied" inline, accessible name | ✓ |
| Hover-reveal copy icons | Only show on hover | (rejected — hides from touch/keyboard) |
| Toast on every copy | Spawn a toast for each copy | (rejected — toast spam) |

**Choice:** `:sm` icon scale with capped glyph (D-09), always-visible ghost affordance (D-10), inline
confirmation over toast-per-copy (D-11), accessible name on every copy control (D-12).

---

## Size & density scale (Criterion 2/5 · "density controls")

| Option | Description | Selected |
|--------|-------------|----------|
| Keep two-tier `:md`/`:sm` | Comfortable default + compact; token spacing; no new tiers | ✓ |
| Add a third tier (`:lg`/`:xs`) | Expand the scale | (rejected — drift risk) |
| User-facing density toggle | Runtime compact/comfortable switch | (out of scope) |

**Choice:** Two-tier scale preserved (D-13), comfortable `:md` default with `:sm` for inline/dense (D-14),
uniform token-bound focus (D-15) and disabled/loading states (D-16), guarded by regression tests (D-17)
without weakening DS-06 / contrast guards (D-18), proven against the Component Lab (D-19).

---

## Claude's Discretion

Exact new token names, remove-vs-alias for `signal_strip`, precise copy-glyph capping mechanism, and
test file placement — left to downstream agents provided D-01..D-19 hold. No vocabulary expansion.

## Deferred Ideas

- Approval decision history & drawer decision-first redesign → Phase 39.
- Keyboard focus order/trap/restore, WCAG 2.2 AA sweep, motion + reduced-motion proof, responsive proof → Phase 40.
- Screenshot-diff CI (`VISUAL-CI-01`), PhoenixStorybook (`STORYBOOK-01`) → deferred.
- Third control size tier → not added; revisit only on real need.
