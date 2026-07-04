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

---

## Phase 41 Update (2026-07-04) — Toast Legibility & Component-Lab Coverage (D-14)

**Fresh capture dir:** `priv/shots/2026-07-04/` (gitignored — PNGs are never the committed
proof, only this index is)

Phase 41 closed the two real screenshot-matrix gaps identified in D-14: component-lab
states and toast legibility. `priv/dev/shots.mjs` and `priv/dev/contact_sheet.mjs` now
include a **new `lab_overlays` screen** (`/_lab/overlays`) — the real
`RISK-TOAST-LEGIBILITY` static toast fixture at `dev/lab/sections/overlays.ex:91-94`
(`<.toast tone={:warn}/>` + `{:fail}`), not the badge-only `states.ex` section.

**Toast-timing-safe capture strategy (D-15):** `toast/1`'s `phx-mounted={JS.hide(time:
@duration_ms)}` auto-hides after a default 4000ms. Rather than racing that timer across a
12-shot (2 themes × 6 viewports) loop, `lab_overlays` sets `freshMountPerCapture: true`,
which re-navigates and re-awaits the ready sentinel **before every single capture** — each
shot lands inside its own fresh 4000ms window. A `.scoria-toast` count sanity check runs
before each shot and logs a warning if the toast is absent (catches a silent-empty-shot
flake during authoring); it does not assert exact timing (D-15 — reset the clock, don't
race it).

**Run status:** the harness ran successfully against a local `mix phx.server` dev
instance. `mix scoria.ui.shots` captured `lab_overlays` across both themes × all 6
RESP-01 viewport widths (320/375/768/1024/1440/1920) with **zero toast-sanity warnings**
— every one of the 12 captures contains both toasts (`warn` tone: "Refund request denied:
amount exceeds tenant policy ceiling"; `fail` tone: "Approval evidence failed to load for
appr-9b1d4e2a"). Manually eyeballed `populated_dark_w1440`, `populated_light_w1440`, and
`populated_dark_w320` — both toasts are clearly legible (icon + text + dismiss button)
against the stacked drawer/modal overlay probe behind them, in both themes, at both
desktop and narrow mobile width.

**Known non-regression note:** re-running `contact_sheet.mjs --before priv/shots/2026-06-13
--after priv/shots/2026-07-04` reports 0 paired files. This is expected, not a defect: Phase
40 (D-14) widened `VIEWPORTS` from the original 2 entries (`desktop`/`mobile`) to the 6
named RESP-01 widths (`w320`..`w1920`), so filenames like `populated_dark_desktop.png`
(2026-06-13) don't literally match `populated_dark_w1440.png` (2026-07-04). The generator's
own placeholder-on-mismatch behavior handled this without crashing.

**No product code changed:** `lib/scoria_web/ui.ex`'s `toast/1` auto-hide behavior is
unchanged (D-01) — only the capture script's navigation timing adapted. No pixel-diff or
CI screenshot assertion was added (VISUAL-CI-01 stays deferred); this remains
human-reviewable evidence, never a gate (D-13).
