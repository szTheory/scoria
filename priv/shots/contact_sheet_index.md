# Contact Sheet Index — v3.0 Control Room Milestone Close

**Baseline dir:** priv/shots/2026-06-04
**Final dir:** priv/shots/2026-06-13
**Generated:** 2026-06-13

---

## Overview

The before/after contact sheet documents the visual iteration from the Phase 11 baseline
capture (2026-06-04) to the Phase 17 final capture (2026-06-13) across all 9 dashboard
screens. The generated HTML grid (`priv/shots/contact_sheet.html`) is gitignored and
regenerable from this index. Only this committed index and the generator
(`priv/dev/contact_sheet.mjs`) are tracked in git.

**Paired screens (both dirs present):** 2 — `live_ops`, `approvals` (8 PNGs each)
**Baseline-only screens (final dir missing):** 7 — see per-screen notes below

The 7 missing screens reflect a pre-existing Phase 13 deferred item: the approvals modal
overlay capture timed out during the Plan 17-01 harness run (scrim intercepting pointer
events), halting capture after `live_ops` and `approvals`. This is documented in
`17-01-SUMMARY.md`. The deterministic 11-P1 resolution checklist in
`gap_register_final.md` is the falsifiable proof — it does not depend on screenshot
completeness.

---

## Per-Screen Delta Notes

Non-tenant-scoped screens (reviews, eval_specs, prompts, prompt_release, workflows) capture
only `populated_*` states — they do not support `?tenant=` switching and have no
`empty_*` pairs. This is a known harness limitation documented in MAINTAINERS.md
("Empty-state limitation").

| Screen | State captured | Baseline files | Final files | Notes |
|--------|---------------|----------------|-------------|-------|
| live_ops | paired (8+8) | `priv/shots/2026-06-04/live_ops/` | `priv/shots/2026-06-13/live_ops/` | Phase 16: mobile-first responsive shell, off-canvas nav drawer (Hooks.MobileNav), focus-visible hardening, light+dark parity |
| approvals | paired (8+8) | `priv/shots/2026-06-04/approvals/` | `priv/shots/2026-06-13/approvals/` | Phase 15: shared modal/notebook primitives; Phase 16: responsive shell, focus-visible, motion contract |
| workflows | baseline-only (4+0) | `priv/shots/2026-06-04/workflows/` | — not re-captured | Phase 15: shared table/drawer primitives; Phase 16: responsive table with overflow viewport; non-tenant-scoped (populated only) |
| incidents | baseline-only (8+0) | `priv/shots/2026-06-04/incidents/` | — not re-captured | Phase 14: least-iterated screen polish; Phase 16: mobile-first shell; tenant-scoped (empty+populated) |
| connectors | baseline-only (8+0) | `priv/shots/2026-06-04/connectors/` | — not re-captured | Phase 15: connector drawer/runtime drawer primitives; Phase 16: density-aware responsive table |
| reviews | baseline-only (4+0) | `priv/shots/2026-06-04/reviews/` | — not re-captured | Phase 14: review queue polish; non-tenant-scoped (populated only) |
| eval_specs | baseline-only (4+0) | `priv/shots/2026-06-04/eval_specs/` | — not re-captured | Phase 14: eval workbench polish; a11y, density, responsive improvements; non-tenant-scoped |
| prompts | baseline-only (4+0) | `priv/shots/2026-06-04/prompts/` | — not re-captured | Phase 14: prompt registry polish; a11y, density, responsive; non-tenant-scoped |
| prompt_release | baseline-only (4+0) | `priv/shots/2026-06-04/prompt_release/` | — not re-captured | Phase 14: release workbench polish; a11y, density, responsive; non-tenant-scoped |

### Phase improvements cited above

| Phase | Screens affected | Key improvement |
|-------|-----------------|-----------------|
| 12 | All | `ui.ex` component layer; DS-06 raw-color drift guard; `flash_group/1` semantic tokens |
| 13 | All | Third nav axis (Operate/Improve/Configure); Status Home; breadcrumbs; ⌘K palette |
| 14 | incidents, reviews, eval_specs, prompts, prompt_release | Least-iterated screen polish; shared `table/1`, `notebook/1` primitives |
| 15 | live_ops, approvals, workflows, connectors | High-traffic screens; `drawer/1`, `modal/1`, `notebook/1` evidence adapters |
| 16 | All | Mobile-first responsive (off-canvas nav, overflow tables, named grid classes); focus-visible a11y; motion contract; full light+dark parity |

---

## How to Regenerate

```bash
node priv/dev/contact_sheet.mjs \
  --before priv/shots/2026-06-04 \
  --after priv/shots/2026-06-13 \
  --out priv/shots/contact_sheet.html
```

For future milestone passes, substitute new baseline and final dirs — no code changes needed:

```bash
node priv/dev/contact_sheet.mjs \
  --before priv/shots/<prev-date> \
  --after priv/shots/<next-date> \
  --out priv/shots/contact_sheet.html
```

The generator pairs PNGs by `{screen}/{filename}` across the two dirs. Screens present
in `--before` but missing from `--after` render an explicit placeholder in the HTML grid
(no crash). The generated HTML is gitignored (`*.html` in `priv/shots/.gitignore`).
