# Phase 40 Gap Register (working artifact)

**Status:** working draft, opened in Plan 40-01 (Task 3). This is **not** the final polished
register — Phase 41 owns the final version that separates fixed-in-40 from explicitly-deferred
(D-03). This document only accumulates entries as later Phase 40 plans surface out-of-scope
defects; it does not attempt to be complete on the day it's created.

## Purpose (D-01/D-02/D-03)

Phase 40 fixes every defect its proof harness surfaces **except** defects whose only fix crosses a
locked out-of-scope boundary. Those out-of-scope defects get recorded here the moment they're
found — with enough repro detail that Phase 41 (or a future milestone) can act on them without
re-discovering them from scratch.

**The defer line is scope, not size (D-02).** A tedious-but-mechanical fix (e.g. threading
`focus_wrap` through another opener call site) stays in-scope. A trivial-looking fix that requires
crossing a locked boundary does not. The discriminator is `.planning/REQUIREMENTS.md`'s out-of-scope
list, not story points or fix-difficulty.

**⚠ A flood of entries here is an escalate/replan signal, not a workload to silently absorb.**
Phases 36–39 banked accessibility-by-construction (design-system adoption, copy/status
consolidation, focus/motion contract work). If this register starts accumulating *many* defects
that all require primitive-vocabulary changes, that indicates something upstream regressed — stop,
escalate, and replan rather than dumping the backlog on Phase 41 or quietly fixing it out-of-scope
here.

## The locked out-of-scope boundaries (D-01)

An entry belongs in this register (not fixed in Phase 40) only if its only fix requires one of:

1. A new or changed primitive **vocabulary** (e.g. a new `<.status_label>` value, a new component
   variant/slot/attr contract).
2. A public macro or `.scoria-root` change (the adopter-facing surface).
3. A new **runtime** dependency (Hex package reaching a shipped host app — `@axe-core/playwright`
   is dev-only and does not count).
4. An architecture or approval-semantics rewrite.

Anything else — however tedious — is fixed in Phase 40, not registered here.

## Register

| ID | Requirement | Surface/Page | Viewport / AT | Repro Steps | Boundary Crossed | Status |
|----|-------------|---------------|----------------|-------------|-------------------|--------|
| GAP-40-000 | A11Y-02 (non-goal, D-20) | Global (all pages, both themes) | `prefers-contrast: more` / Windows High Contrast (`forced-colors: active`) | N/A — not exercised by this phase's proof harness by design. Any adopter host running under Windows High Contrast Mode or a `prefers-contrast: more` user setting is out of this phase's proof scope. | New primitive vocabulary (a distinct high-contrast token layer) would be required to support this properly; explicitly deferred rather than a defect. | considered-and-deferred (non-goal, not a defect) |

_No further rows yet — this register opens empty of real defects at Plan 40-01. Wave 2 plans
(axe scan, drawer/modal focus, responsive scan, motion guard) append rows here as their proof
surfaces out-of-scope findings._

## Row schema (for future entries)

- **ID:** `GAP-40-NNN`, sequential.
- **Requirement:** `A11Y-01` / `A11Y-02` / `MOTION-01` / `RESP-01`.
- **Surface/Page:** the LiveView route or component where the defect was observed.
- **Viewport / AT:** the viewport width (320/375/768/1024/1440/1920) and/or assistive technology
  context (keyboard-only, axe scan, screen reader if applicable) the defect was found under.
- **Repro Steps:** concrete steps (or the failing spec/test name) to reproduce.
- **Boundary Crossed:** which of the four D-01 boundaries the only known fix would cross — quote
  the exact boundary, don't paraphrase loosely, so Phase 41 can triage without re-deriving intent.
- **Status:** `registered` (found, not yet actioned) or `fixed-in-40` (turned out to be in-scope
  after all and was fixed inline instead of deferred — use this to correct an earlier registration,
  don't silently delete the row).
