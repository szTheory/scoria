# Phase 40: Accessibility, Motion, And Responsive Proof - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-03
**Phase:** 40-Accessibility, Motion, And Responsive Proof
**Areas discussed:** Proof stance, WCAG 2.2 AA proof tooling, Keyboard/focus proof depth, Responsive failure detection

> **Method:** The user directed that each gray area be resolved via deep research (subagents), through
> every relevant lens — idiom for an embedded Phoenix/Elixir library, lessons from peer libs in and
> outside the ecosystem, DX, all design pillars, brand book, JTBD/user-flow — one-shot into a coherent,
> cohesive recommendation. Four parallel research passes ran, then a fifth **red-team** pass hunted for
> where the synthesis was wrong against the actual code. The user selected all four areas for research
> and delegated the specific choices to the research + red-team process. Selections below reflect the
> hardened recommendations the user's method produced.

---

## Proof stance — when proof surfaces a defect, fix or register?

| Option | Description | Selected |
|--------|-------------|----------|
| Prove-and-fix to green | Fix defects so criteria are literally true; Phase 41 only hardens/docs/registers | ✓ (w/ scope-boundary escape valve) |
| Prove-and-register only | Build harness, record pass/fail, defer all fixes to Phase 41 | |
| Fix in-scope, defer big ones | Fix small/mechanical inline; register anything needing primitive/arch change | ✓ (as the escape valve, keyed to scope not size) |

**User's choice:** Prove-and-fix to green, with a scope-boundary escape valve (register — don't fix —
only defects whose sole fix crosses a locked out-of-scope boundary). Line drawn by scope, never effort.
**Notes:** Grounded in three repo facts: Phase 40 criteria are worded as truth-claims; Phase 41 has no
remediation budget (proof-and-lock only); Phase 39 precedent fixed in-scope + deferred only hardening.
A flood of structural defects = signal to escalate/replan, not a workload to absorb (D-02).

---

## WCAG 2.2 AA proof tooling

| Option | Description | Selected |
|--------|-------------|----------|
| axe-core in Playwright e2e | Computed WCAG scans; one dev-only dep | |
| ExUnit source-scan guards only | No dep; browserless; misses computed contrast/focus | |
| axe-core + source-scan (both) | axe for computed WCAG in e2e; guards for structural invariants in fast mix test | ✓ |

**User's choice:** Both (Option C) — `@axe-core/playwright` (dev-only in `priv/dev`, exact-pinned) in the
e2e lane + browserless ExUnit source-scan guards.
**Notes (red-team hardened):** First-run axe = **report-only baseline**, not assert-zero (the dev lab is
a specimen gallery; muted/disabled specimens fire `color-contrast`); ratchet to zero only on curated
seeded real pages. Scan **both dark and light** themes. Tags wcag2a/2aa/21a/21aa/22aa (no best-practice).
Explicit coverage map so keyboard (axe blind spot) and structural presence each have a named owner (D-07).

---

## Keyboard / focus proof depth & surfaces

| Option | Description | Selected |
|--------|-------------|----------|
| Deep on overlays, contract elsewhere | Full keyboard-driving on drawer/modal/palette; source-scan contract for calmer surfaces | ✓ |
| Deep everywhere | Automated keyboard e2e across every surface | |
| Contract/source-scan everywhere | Guards + smoke flows; no exhaustive keyboard driving | |

**User's choice:** Deep on overlays, contract elsewhere (Option A).
**Notes:** Decisive code finding — the command palette + mobile nav already have focus trap+restore, but
server-rendered `drawer/1` has NO trap/restore/autofocus and `modal/1` has only autofocus+Escape. Bundled
fix: bring drawer/modal to the palette's standard via `Phoenix.Component.focus_wrap` (no new Hex dep) or
the existing `scoria.js` helpers — adds no attr/slot, so NOT a locked-vocabulary change (D-10). Red-team
added live-patch focus survival on the live PubSub drawer as a missed target (D-13).

---

## Responsive failure detection (320/375/768/1024/1440/wide)

| Option | Description | Selected |
|--------|-------------|----------|
| Automated per-viewport assertions | Playwright asserts no-h-overflow/no-clip/no-floating-over-nav; CI gate | ✓ (the gate) |
| Screenshot contact-sheet review | Reuse shots.mjs; eyeball a contact sheet | ✓ (as evidence, not a gate) |
| Assertions + screenshot backstop | Assertions gate + captured width matrix as human evidence | ✓ |

**User's choice:** Assertions gate + screenshot contact-sheet as human evidence (Option C).
**Notes:** The 6-width scan + no-h-overflow assertion already exist in embryo (`lab.spec.mjs`,
`phase16_parity.spec.mjs`) — generalize to real primary pages. Tiered pages×widths to avoid blowup.
7-item assertion catalog (D-16). `:mobile_summary` object-stack is the default table strategy; scroll-
container fallback for wide diagnostic tables (D-18). SC 2.4.11 boundary split cleanly between keyboard
(dynamic focus occlusion) and responsive (static toast occlusion, excludes sticky footer) (D-17).

---

## Cross-cutting decision surfaced during research

**CI two-bucket rule (D-04):** because the e2e lane is a hard-fail required CI gate, warning-grade cannot
mean a throwing assertion. Hard-fail checks ship fix-and-assert atomically; warning-grade checks are
non-throwing collectors (`console.warn` + `testInfo.attach`). `test.fail()`/`expect.soft` banned as the
warning mechanism. This is the single most load-bearing mechanism in the phase.

**MOTION-01 (D-19):** given its own decision though not a presented gray area — motion is already
tokenized + reduced-motion-safe; the proof is a precise source-scan guard (allow-listing the two
documented exceptions: raw skeleton-pulse line 1610, approval-pulse border-color) + an `emulateMedia`
reduced-motion collapse assertion.

## Claude's Discretion

`focus_wrap` vs reuse-existing-hook for the overlay fix; exact spec/guard file names + placement; curated
selector sets (D-16(2)) and curated axe real-page allow-list (D-06); which ~4 primary pages anchor the
responsive scan; `boxesIntersect` helper signature; whether D-13 live-patch survival needs the private
restore hook or `focus_wrap` alone — all downstream, provided D-01..D-20 + the Proof Spine hold.

## Deferred Ideas

- Hardened/blocking guards, maintainer docs, screenshot proof, final gap register → Phase 41.
- Screenshot-diff pixel gate (VISUAL-CI-01), PhoenixStorybook (STORYBOOK-01) → later.
- `prefers-contrast`/`forced-colors` → explicit non-goal (D-20).
- Named tab-stop/SR label on the table scroll container → Phase 41.
- Any fix requiring a locked-vocabulary/macro/`.scoria-root`/runtime-dep change → register, don't fix in 40.
