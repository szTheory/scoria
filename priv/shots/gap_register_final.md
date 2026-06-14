# Design-System Gap Register — Final 2026-06-13

**Run date:** 2026-06-13
**Model:** anthropic:claude-sonnet-4-5
**Baseline:** priv/shots/gap_register.md (2026-06-04)
**Final shots:** priv/shots/2026-06-13/

## Summary

- Baseline: 0 P0 / 11 P1 / 71 passing
- Final: 0 P0 / 0 P1 / 82 passing (deterministic; see checklist below)
- Net improvement: 11 P1 findings resolved
- LLM rubric re-run: not re-run (ANTHROPIC_API_KEY not set in execution environment)

> Note: The LLM critique pass was not re-run because ANTHROPIC_API_KEY was unavailable
> in the executor environment. The per-screen rubric delta table below shows baseline
> scores with "not re-run" in the Final column. The deterministic 11-P1 resolution
> checklist (Section 2) is the falsifiable proof, verifiable by code review or `mix test`
> with no API key. The screenshot capture was also partial due to a pre-existing
> approvals/modal overlay timeout (Phase 13 deferred item; priv/shots/2026-06-13/ has
> live_ops and approvals base states captured before the failure). Both limitations are
> consistent with the plan's documented fallback path (17-01-PLAN.md §Task 1 action).

## Per-Screen Rubric Delta

The 11 baseline P1 findings had baseline scores of 2/5 each. The Final column reflects
the deterministic resolution status, not a new LLM run (see note above).

| Screen | Dimension | Baseline | Final | Change |
|--------|-----------|----------|-------|--------|
| all-screens (flash) | consistency | 2/5 | not re-run (no API key) | See P1-01 checklist |
| connectors | density | 2/5 | not re-run (no API key) | See P1-02 checklist |
| eval_specs | a11y | 2/5 | not re-run (no API key) | See P1-03 checklist |
| eval_specs | density | 2/5 | not re-run (no API key) | See P1-04 checklist |
| eval_specs | responsive | 2/5 | not re-run (no API key) | See P1-05 checklist |
| prompt_release | a11y | 2/5 | not re-run (no API key) | See P1-06 checklist |
| prompt_release | density | 2/5 | not re-run (no API key) | See P1-07 checklist |
| prompt_release | responsive | 2/5 | not re-run (no API key) | See P1-08 checklist |
| prompts | a11y | 2/5 | not re-run (no API key) | See P1-09 checklist |
| prompts | density | 2/5 | not re-run (no API key) | See P1-10 checklist |
| prompts | responsive | 2/5 | not re-run (no API key) | See P1-11 checklist |

The table above covers all 9 baseline screens (live_ops, approvals, workflows, incidents,
connectors, reviews, eval_specs, prompts, prompt_release). Screens with no baseline P1s
— live_ops, approvals, workflows, incidents, reviews — scored passing (≥ 3/5) across all
9 dimensions in the 2026-06-04 baseline and are not listed in the delta rows above.

## Deterministic 11-P1 Resolution Checklist

> This checklist requires no API key. Each item is verifiable by code review or `mix test`.

- [x] P1-01 all-screens (flash) / consistency: `flash_tone_class/1` removed; `flash_group/1`
      now emits `scoria-flash--{tone}` BEM classes with no raw palette classes.
      Evidence: `lib/scoria_web/ui.ex` `flash_group/1` (search for `scoria-flash--`);
      DS-06 guard confirms `ui.ex` has zero raw palette matches (`mix test test/scoria_web/ds06_drift_guard_test.exs`).
      Resolving phase: Phase 12 (plan 12-02).

- [x] P1-02 connectors / density: shared `<.empty_state>` component with responsive padding
      replaces the fixed-height empty layout; off-canvas nav drawer eliminates the fixed
      sidebar that consumed vertical space at mobile widths.
      Evidence: `lib/scoria_web/live/connectors_live.ex` uses `<.empty_state>` from `ui.ex`;
      Phase 16 mobile-first shell and responsive padding (16-01-PLAN.md, MOTION-03).
      Resolving phase: Phase 16 (plan 16-01).

- [x] P1-03 eval_specs / a11y: focus-visible states are now hardened across all interactive
      controls via the DS-06-safe CSS focus ring convention applied in Phase 16.
      Evidence: `assets/css/04-components.css` focus-visible rules; Phase 16 a11y sweep
      (16-05-PLAN.md, MOTION-02); `mix test test/scoria_web/ds06_drift_guard_test.exs` green.
      Resolving phase: Phase 16 (plan 16-05).

- [x] P1-04 eval_specs / density: Eval Workbench converted to shared-component `<.table>`
      with density toggle and responsive overflow; viewport underutilization resolved by
      the shared table's compact-by-default behavior.
      Evidence: `lib/scoria_web/live/eval_specs_live.ex` uses `<ScoriaWeb.UI.table/1>`;
      Phase 14 Eval Workbench conversion (14-05-PLAN.md).
      Resolving phase: Phase 14 (plan 14-05).

- [x] P1-05 eval_specs / responsive: fixed sidebar replaced by mobile-first off-canvas nav
      drawer (Hooks.MobileNav) so the layout adapts correctly at 375px width.
      Evidence: `lib/scoria_web/components/layouts/app.html.heex` off-canvas drawer;
      `assets/js/scoria.js` MobileNav hook; Phase 16 responsive shell (16-01-PLAN.md, MOTION-03).
      Resolving phase: Phase 16 (plan 16-01).

- [x] P1-06 prompt_release / a11y: focus-visible hardening applied across all interactive
      controls in the Prompt Registry and Release Workbench; status not conveyed by color
      alone (text labels alongside indicators); Edit links have visible focus affordance.
      Evidence: `assets/css/04-components.css` focus-visible rules; Phase 16 a11y sweep
      (16-05-PLAN.md, MOTION-02).
      Resolving phase: Phase 16 (plan 16-05).

- [x] P1-07 prompt_release / density: Prompt Release Workbench converted to shared `<.table>`
      compact density; `<.id>` middle-truncation component eliminates UUID column overflow.
      Evidence: `lib/scoria_web/live/prompt_release_live.ex` uses `ScoriaWeb.UI.table/1`
      and `ScoriaWeb.UI.id/1`; Phase 14 Prompt Registry/Release conversion (14-06-PLAN.md).
      Resolving phase: Phase 14 (plan 14-06).

- [x] P1-08 prompt_release / responsive: mobile summary adoption via `mobile_summary` slot
      on `<.table>` plus off-canvas nav drawer; layout adapts at 375px.
      Evidence: `lib/scoria_web/live/prompt_release_live.ex` table `mobile_summary` slot;
      Phase 16 mobile summary (16-04-PLAN.md) and responsive shell (16-01-PLAN.md, MOTION-03).
      Resolving phase: Phase 16 (plans 16-01, 16-04).

- [x] P1-09 prompts / a11y: focus-visible indicators now visible on all interactive elements
      in the Prompt Registry; focus ring CSS applied via Phase 16 a11y sweep.
      Evidence: `assets/css/04-components.css` focus-visible rules; Phase 16 a11y sweep
      (16-05-PLAN.md, MOTION-02).
      Resolving phase: Phase 16 (plan 16-05).

- [x] P1-10 prompts / density: Prompt Registry converted to shared `<.table>` with density
      controls; `<.id>` middle-truncation component eliminates UUID horizontal overflow;
      System Message truncation handled by the table's cell rendering.
      Evidence: `lib/scoria_web/live/prompts_live.ex` uses `ScoriaWeb.UI.table/1` and
      `ScoriaWeb.UI.id/1`; Phase 14 Prompt Registry conversion (14-06-PLAN.md).
      Resolving phase: Phase 14 (plan 14-06).

- [x] P1-11 prompts / responsive: mobile-first off-canvas nav drawer replaces fixed sidebar;
      `<.table>` viewport-overflow fix applied (table scrolls horizontally at narrow widths
      rather than breaking the layout).
      Evidence: `lib/scoria_web/components/layouts/app.html.heex` off-canvas drawer;
      Phase 16 table viewport overflow fix (16-02-PLAN.md) and responsive shell (16-01-PLAN.md, MOTION-03).
      Resolving phase: Phase 16 (plans 16-01, 16-02).

## Raw-Color-Zero Assertion

Raw palette class count: **0**

Enforcement: `test/scoria_web/ds06_drift_guard_test.exs` — three assertions:
1. "raw palette count never regresses (DS-06 ratchet)" — scans lib/scoria_web/**/*.{ex,heex}
2. "baseline is not stale — no file sits below its committed baseline (WR-01)"
3. "lib/scoria_web/ui.ex has zero raw palette matches"

Baseline: `test/support/ds06_baseline.txt` is empty — zero headroom. Any raw palette class
introduction fails `mix test` automatically.

Run: `mix test test/scoria_web/ds06_drift_guard_test.exs` — must be green before PROOF-01 is closed.

> Known empty-state limitation: reviews, eval_specs, prompts, and prompt_release screens are
> non-tenant-scoped in the shots.mjs SCREENS manifest and therefore capture populated-only states.
> Missing empty-state shots for these screens are not a gap — they reflect the harness design,
> documented in docs/MAINTAINERS.md §Empty-state limitation.
