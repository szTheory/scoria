# Scoria logo — variant spec & optical-correction pass

How the 8-variant root set at `brandbook/` derives from the canonical artwork —
the porous-cinder mark fused into the wordmark as the 'o'. The geometry is
**canonical**: every variant recolors, derives, snaps, or tunes; none redraws a
silhouette or hole coordinate. This document records the manual optical-correction
review (numerically) and the clear-space / min-size rules that `brand-book.md`
consumes.

---

## 1. Single-vs-two-tone primary decision — SHIP TWO-TONE

**Call:** the primary lockup (`logo-primary.svg` / `logo-primary-light.svg`) ships
**two-tone** — surface-ink letters with the mark-'o' in the brand accent:

| Surface | Letters | Mark-'o' |
| --- | --- | --- |
| Dark (`logo-primary.svg`) | White-Hot `#FFF9F3` | Ember-500 `#E65A32` |
| Light (`logo-primary-light.svg`) | Basalt-950 `#11100F` | Scoria-600 `#B94F31` |

The ember accent is reserved for the primary lockup's 'o' — nowhere else.

**Ink-density justification (the proxy that gates the call).** The risk with a
two-tone accent glyph is that the accented 'o' reads as *bolder* than its
neighbours rather than as a deliberate focal accent. The measured ink densities:

- Mark-'o' (after the root-hole micro-tune r 13→14.6): **0.61**
- Round letters ('o' reference): **0.57**

A 0.61 vs 0.57 gap is **~7%** — within the band where the two-tone color contrast
reads as *intentional accent*, not as extra weight. Without the root-hole tune the
mark ran ~11% bolder (0.61 would have been ~0.68 against 0.57), which is why the
micro-tune was applied at glyph scale and is preserved verbatim here.
The color difference, not a weight difference, carries the accent — confirmed
deliberate, not a heavier glyph.

`logo-monochrome.svg` and `logotype-integrated.svg` are **single-tone** by
definition (one `currentColor` fill) — the two-tone call applies to the primary
pair only. A `PRIMARY_TWO_TONE` flag in `lib/root-variants.mjs` flips the whole
pair to single-tone if a future review overrides this call.

---

## 2. Overshoot / baseline note — mark sits in the x-height band, no clip/float

The substituted mark-'o' must occupy the same x-height band as Plex's humanist
'o' (which overshoots slightly past the x-height and baseline) so it neither looks
clipped (too small) nor floating (mis-centered). Measured occupancy of the mark
in the fused lockup (the canonical mark-group transform, recomputed for this review):

- **x: 111.22 → 167.87** — the 'o' advance slot is 111.4 → 167.7; the mark fills
  it with 0.2u of breathing room each side. No collision with 'c' (ends 109.4) or
  'r' (starts 174.6).
- **y: −53.38 → 1.18** — this IS the x-height band (Plex 'o' bbox −53.40 → 1.20,
  overshoot included). The mark spans it top-to-bottom: not clipped, not floating.
- **width 56.64u vs the 'o' advance 56.30u** — a 0.34u difference, so kerning is
  undisturbed and the word reads as one fused object.

No adjustment required — the canonical placement already satisfies the overshoot
and baseline criteria. Recorded here as the optical confirmation.

---

## 3. logotype-integrated lineage — BYTE-IDENTICAL to logo-monochrome

`logotype-integrated.svg` is shipped **byte-identical** to `logo-monochrome.svg`.

Rationale: the fused lockup *is* the integrated logotype (the mark fused as the 'o' makes the
wordmark and mark a single object). The canonical "typemark" deliverable is
therefore the single-color (`currentColor`) form of that fused lockup — which is
exactly `logo-monochrome.svg`. Maintaining two separate tunings would create two
sources of truth for one artwork; instead `logotypeIntegrated()` calls
`logoMonochrome()` so the files stay identical and downstream consumers can alias
one to the other. Primary and integrated share lineage — they differ only in
colorway (two-tone vs single `currentColor`), not in geometry.

---

## 4. Favicon legibility — 3 holes, all ≥1.5px at 16px, even 16-grid snap

`favicon.svg` re-emits the mark's `holes16` 3-hole simplification with the outer
silhouette copied verbatim from its source preset (preserved in `candidates/TV-1-fav.svg`,
a historical generation artifact) and the three hole
subpaths replaced by circles snapped to **even integers on the 16-unit grid**
(centers AND radii rounded to the nearest even value via `Math.round(n/2)*2`).

Hole radii at 16px render (viewBox height 96.07 → scale 16/96.07 ≈ 0.1666):

| Hole | r (preset → snapped) | radius at 16px |
| --- | --- | --- |
| root (upper-left) | 12 → 12 | **2.00px** |
| mid (center) | 10.5 → 10 | **1.67px** |
| leaf (lower-right) | 10 → 10 | **1.67px** |

All three clear the **≥1.5px** legibility floor at 16px. Exactly 3 hole subpaths
(M-count − 1 = 3). File is **734 bytes** on disk — under the 1KB budget — achieved
by stripping `<title>`/`<desc>` to a minimal `aria-label="Scoria favicon"`.

---

## 5. Clear space

**Ship rule: clear space = cap-height / 2 around the lockup bounding box.**

The lockup cap-height (the 'S'/'c'/'r' cap band) is **76.8u** in the lockup
coordinate space (viewBox `2.9 -75.6 284 77.8`, the cap band running y −74.6 → 1.2).
Clear space is therefore **≈38.4u** of empty margin on all four sides of the lockup
bounding box — no other element, text, or edge intrudes within that margin.

*Alternate:* an acceptable looser phrasing is "the largest vesicle = unit *v*;
keep 1.5*v* around the lockup." The largest vesicle (the root hole) is ≈14.6u at
glyph scale; 1.5*v* ≈ 21.9u — a *tighter* margin than cap-height/2. We ship the
**cap-height/2 (≈38.4u)** rule because it scales with the lockup rather than with
a single internal feature and gives the fused mark more room to read at small sizes.

---

## 6. Minimum sizes

| Asset | Min size (ship) | Note |
| --- | --- | --- |
| Primary lockup | **≥120px wide** | a ≥112px floor is technically workable, but ≥120 ships for the fused mark's small-size hole legibility. |
| Mark alone (`logo-mark.svg`) | **≥20px** | below this the trace-tree holes start merging. |
| Favicon | **exact at 16px and 32px** | the `holes16` simplification is tuned for 16px; 32px renders the same path crisply. |

---

## 7. LOGO-01..07 binding confirmation

All 8 root SVGs obey the locked structural rules — **no `<rect>`** (the single
`social-card.svg` card-ground rect is the documented exemption: the card IS a
bounded artwork, not a logo background), **`fill-rule="evenodd"`** on every logo
path (mark holes punched), **no active strokes**, **tight viewBoxes** near origin
(social-card is the bounded `0 0 1280 640` canvas, exempt from the tight-origin
bound), and **all coordinates ≤2 decimal places**. Enforced by the ROOT-* checks
in `verify-logos.mjs` (exit 0).
