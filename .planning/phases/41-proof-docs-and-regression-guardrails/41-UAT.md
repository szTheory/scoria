---
status: complete
phase: 41-proof-docs-and-regression-guardrails
source: [41-VERIFICATION.md]
started: 2026-07-04T18:14:48Z
updated: 2026-07-04T18:38:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Toast-legibility visual review of the /_lab/overlays screenshot captures
expected: Eyeball the `/_lab/overlays` captures (both toast tones, both themes, at least the 1440 and 320 widths) in `priv/shots/*.png` (gitignored — regenerate with `mix scoria.ui.shots` if not present locally) for actual legibility (contrast, no overlap with the stacked drawer/modal overlay probe). Toast icon + message + dismiss control are clearly readable in both themes and both widths, without visual collision with the overlay probe underneath.
why_human: Visual legibility/contrast judgment cannot be verified by grep or an automated assertion — explicitly documented as human-judgment evidence (D-13/D-14), never a CI gate (VISUAL-CI-01 deferred by owner decision).
result: pass
source: automated
verified_note: "Inspected priv/shots/2026-07-04/lab_overlays populated_{light,dark}_w{1440,320}.png. Both toast tones (warning amber, error red) show legible icon + message + × dismiss in both themes at both widths; toasts sit bottom-right/bottom, clear of the centered modal and top-right drawer probes. No collision."

### 2. Independent runtime re-execution of the D-13 drawer-focus e2e invariant
expected: Run `mix scoria.ui.e2e` against a live dev server (boot one first; the task drives an already-running server at `http://localhost:4799/scoria`) to re-execute "D-13: focus survives an unrelated live PubSub patch while the drawer stays open" in `priv/dev/e2e/drawer_focus.spec.mjs:284` — now a throwing `expect()` (Phase 41 Plan 04, D-04) rather than a report-only collector. The test passes: focus remains inside the still-open drawer's DOM subtree after an unrelated PubSub-driven live patch re-renders part of the page.
why_human: A runtime state-preservation invariant across an async re-render — grep/source inspection confirms the assertion now throws instead of warning, but cannot prove the invariant holds at runtime. Already CI-gated (`mix scoria.ui.e2e`, no `continue-on-error`); the plan's own SUMMARY documents one passing dated run (2026-07-04). This item re-confirms it independently.
result: pass
source: automated
verified_note: |
  Booted dev server (PORT=4799 mix phx.server) after mix dev.setup, then ran
  `mix scoria.ui.e2e --base-url http://localhost:4799/scoria` (2026-07-04).
  drawer_focus.spec.mjs:284 "D-13: focus survives an unrelated live PubSub patch
  while the drawer stays open" PASSED (isolated re-run: 6/6 drawer_focus tests
  green, D-13 in 1.4s). Full lane: 162 passed. The only lane failures were the 3
  phase16_parity MOTION-04 theme-toggle smoke tests (element-not-visible; mobile
  toggle precedes desktop toggle in DOM since the 2026-06-20 IA-refine commit,
  pre-Phase-41) — these are 3 of the 6 KNOWN pre-existing, out-of-scope failures
  already logged in this phase's deferred-items.md (candidate for a future e2e
  flake/regression sweep). Not a Phase 41 regression; the phase never claimed
  suite-green and cites these reds honestly (D-21).

## Summary

total: 2
passed: 2
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps
