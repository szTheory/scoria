---
status: testing
phase: 41-proof-docs-and-regression-guardrails
source: [41-VERIFICATION.md]
started: 2026-07-04T18:14:48Z
updated: 2026-07-04T18:14:48Z
---

## Current Test

number: 1
name: Toast-legibility visual review of the /_lab/overlays screenshot captures
expected: |
  Toast icon + message + dismiss control are clearly readable in both light and
  dark themes, at both desktop (1440) and narrow-mobile (320) widths, without
  visual collision with the stacked drawer/modal overlay probe underneath.
awaiting: user response

## Tests

### 1. Toast-legibility visual review of the /_lab/overlays screenshot captures
expected: Eyeball the `/_lab/overlays` captures (both toast tones, both themes, at least the 1440 and 320 widths) in `priv/shots/*.png` (gitignored — regenerate with `mix scoria.ui.shots` if not present locally) for actual legibility (contrast, no overlap with the stacked drawer/modal overlay probe). Toast icon + message + dismiss control are clearly readable in both themes and both widths, without visual collision with the overlay probe underneath.
why_human: Visual legibility/contrast judgment cannot be verified by grep or an automated assertion — explicitly documented as human-judgment evidence (D-13/D-14), never a CI gate (VISUAL-CI-01 deferred by owner decision).
result: [pending]

### 2. Independent runtime re-execution of the D-13 drawer-focus e2e invariant
expected: Run `mix scoria.ui.e2e` against a live dev server (boot one first; the task drives an already-running server at `http://localhost:4799/scoria`) to re-execute "D-13: focus survives an unrelated live PubSub patch while the drawer stays open" in `priv/dev/e2e/drawer_focus.spec.mjs:284` — now a throwing `expect()` (Phase 41 Plan 04, D-04) rather than a report-only collector. The test passes: focus remains inside the still-open drawer's DOM subtree after an unrelated PubSub-driven live patch re-renders part of the page.
why_human: A runtime state-preservation invariant across an async re-render — grep/source inspection confirms the assertion now throws instead of warning, but cannot prove the invariant holds at runtime. Already CI-gated (`mix scoria.ui.e2e`, no `continue-on-error`); the plan's own SUMMARY documents one passing dated run (2026-07-04). This item re-confirms it independently.
result: [pending]

## Summary

total: 2
passed: 0
issues: 0
pending: 2
skipped: 0
blocked: 0

## Gaps
