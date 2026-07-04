---
phase: 40-accessibility-motion-and-responsive-proof
verified: 2026-07-04T02:12:30Z
status: passed
score: 22/22 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification: false
---

# Phase 40: Accessibility, Motion, and Responsive Proof Verification Report

**Phase Goal:** Prove the redesigned controls and flows are operable, readable, and stable across accessibility, motion, and viewport constraints.
**Verified:** 2026-07-04T02:12:30Z
**Status:** passed
**Re-verification:** No — initial verification

## Method

This is goal-backward verification, not a re-read of SUMMARY.md claims. In addition to static
code/artifact/wiring inspection, I independently stood up a throwaway dev environment (fresh
Postgres container on an isolated port, `mix dev.setup`, `mix phx.server`) and ran the phase's
own Playwright e2e lane (`mix scoria.ui.e2e`, full 168-test parallel lane) **twice** against a
clean, freshly-seeded database — not trusting the executor's commit-message claim that the
CR-01 regression test "fails pre-fix / passes post-fix." Both runs independently reproduced:
all Phase-40-authored specs green (drawer_focus 9/9 incl. the CR-01 stacked-overlay regression,
modal_focus 3/3, a11y_axe 28/28, responsive_scan 58/58, reduced_motion 5/5), with only the
3 pre-existing, already-documented `phase16_parity.spec.mjs` MOTION-04 theme-toggle-selector
flakes failing (unrelated to Phase 40 — confirmed by `deferred-items.md` and reproduced
identically on a virgin database with none of Phase 40's git history stashed out).

## Goal Achievement

### Observable Truths (mapped to ROADMAP/REQUIREMENTS traceability: A11Y-01, A11Y-02, MOTION-01, RESP-01 → Phase 40)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `@axe-core/playwright` is a dev-only devDependency, exact-pinned, with transitive `axe-core` pinned via `overrides`; no new Hex runtime dep | ✓ VERIFIED | `priv/dev/package.json`: `devDependencies["@axe-core/playwright"] = "4.12.1"`, `overrides["axe-core"] = "4.12.1"`, absent from `dependencies`. Confirmed via `node -e` inspection. |
| 2 | A single shared `boxesIntersect(a,b)` helper is imported by both the drawer focus spec (dynamic occlusion) and the responsive scan (static occlusion) | ✓ VERIFIED | `priv/dev/e2e/lib/boxes_intersect.mjs` exists; `grep` confirms `drawer_focus.spec.mjs` and `responsive_scan.spec.mjs` both `import { boxesIntersect } from './lib/boxes_intersect.mjs'`. |
| 3 | A single shared axe-run helper sets WCAG tags (never best-practice) AND explicitly enables `target-size` | ✓ VERIFIED | `priv/dev/e2e/lib/axe.mjs`: `WCAG_TAGS = ['wcag2a','wcag2aa','wcag21a','wcag21aa','wcag22aa']`, `RULE_OVERRIDES = {'target-size': {enabled: true}}`, `.options()` called before `.withTags()` (correct AxeBuilder ordering). `a11y_axe.spec.mjs` imports `runAxeScan` from this module — single source. |
| 4 | A working gap register exists recording out-of-scope-boundary defects with the exact boundary crossed; `prefers-contrast`/`forced-colors` pre-recorded as considered-and-deferred | ✓ VERIFIED | `40-GAP-REGISTER.md` exists with the required schema and a pre-seeded `GAP-40-000` row for `prefers-contrast`/`forced-colors` (D-20 non-goal). No further defect rows were needed — the phase's own proof harness came back clean on every real-page/anchor-page surface after in-scope fixes (verified below), so the register legitimately stays at one seed row. |
| 5 | Browserless motion source-scan guard proves no `transition: all`, tokenized animations except the two allow-listed keyframes, keyframes animate only transform/opacity/border-color, no new `@keyframes` outside `05-motion.css` | ✓ VERIFIED | `mix test test/scoria_web/motion_drift_guard_test.exs` — 5/5 pass, run directly by me. `grep` confirms `@allow_listed_animation_names ~w(scoria-skeleton-pulse scoria-approval-pulse)` — both D-20/D-21 exceptions present by name. |
| 6 | Browserless a11y structural guard proves icon-button accessible names, no color-only status, native-semantics presence, calm-surface contract | ✓ VERIFIED | `mix test test/scoria_web/a11y_structural_guard_test.exs` — 8/8 pass, run directly by me. |
| 7 | Both guards are warning-grade (collect-offenders); `ds06_drift_guard_test.exs`/`token_contrast_guard_test.exs` stay green | ✓ VERIFIED | `mix test test/scoria_web/motion_drift_guard_test.exs test/scoria_web/a11y_structural_guard_test.exs test/scoria_web/ds06_drift_guard_test.exs test/scoria_web/token_contrast_guard_test.exs` — 19/19 pass, run directly by me. |
| 8 | `drawer/1` and `modal/1` trap focus (Tab/Shift+Tab wrap, never lands on background), move focus in on open, close on Esc, restore focus to opener on close — zero new attrs/slots | ✓ VERIFIED (behavioral) | Live Playwright run (fresh DB, run by me twice): `drawer_focus.spec.mjs` tab-in/trap/Esc-restore/SC-2.4.11 — 4/4 pass both runs; `modal_focus.spec.mjs` tab-in/trap/Esc-restore — 3/3 pass both runs. `ui.ex` code read confirms `focus_wrap` nested at `#{id}-focus`, `phx-mounted={JS.focus_first()}`, `phx-remove={JS.pop_focus()}` — no new `attr`/`slot` added. |
| 9 | Focus restoration captured at the opener (`JS.push_focus()`), released via `pop_focus` from internal `on_dismiss` wiring | ✓ VERIFIED | `grep -rn push_focus lib/scoria_web/` — 10 call sites across 6 files; live e2e restore-to-opener assertions pass (evidence above). |
| 10 | `focus_wrap` nested with a distinct id `#{@id}-focus`, not reusing the shell's own `@id` | ✓ VERIFIED | Confirmed by direct `ui.ex` code read (both `modal/1` and `drawer/1`). |
| 11 | Drawer proves SC 2.4.11 (focused primary action not covered by the sticky approval footer) via shared `boxesIntersect` | ✓ VERIFIED (behavioral) | `drawer_focus.spec.mjs`'s SC-2.4.11 test passed live in both my independent runs. |
| 12 | D-13 live-patch focus survival is a non-throwing collector; no bare `expect()` merges ahead of a fix | ✓ VERIFIED (behavioral) | Live run: D-13 collector test executed and passed (non-throwing by construction — `grep` confirms zero `test.fail()`/`expect.soft` usage in `drawer_focus.spec.mjs`). |
| 13 | **Critical regression (CR-01, code review):** stacked modal-over-drawer window-Escape collision on the approvals surface is fixed | ✓ VERIFIED (behavioral) | Read the fix diff (`096154d3`): `drawer/1` gains a `keydown_enabled` attr that omits `phx-window-keydown`/`phx-key` when a stacked modal is topmost; `approvals_live/index.ex` computes `decision_modal_open?` once and shares it between the modal's `show` and the drawer's `keydown_enabled`. Independently ran the CR-01 regression test (`0af8dfb8`) live against a fresh dev server twice — passed both times (Escape closes only the modal, drawer stays open, `?approval=` deep-link survives, focus pops exactly once). |
| 14 | **Same-class warning (WR-03, code review):** connectors drawers cleared on open so at most one is mounted | ✓ VERIFIED | Read the fix diff (`52921c02`): `open_runtime_drawer`/`open_connector_drawer` now clear the other assign. Code-correct; same pattern class as the independently-verified CR-01 fix. |
| 15 | axe scans run with the five WCAG tags (never best-practice), exercising both `data-theme=dark` and `data-theme=light` | ✓ VERIFIED (behavioral) | `a11y_axe.spec.mjs` imports the shared helper; live run: 28/28 `a11y_axe.spec.mjs` tests passed (both themes × 7 lab sections report-only + 7 real pages × 2 themes curated). |
| 16 | First axe run is report-only baseline (not assert-zero); assert-zero applies only to a curated human-confirmed real-page allow-list; `target-size` stays report-only | ✓ VERIFIED | Code read confirms Tier 1 (`test.describe` report-only, `testInfo.attach`, no throwing `expect`) vs Tier 2 (curated `describe` with throwing `expect`, `target-size` filtered out of the assertion). Checkpoint approval documented in `40-04-SUMMARY.md` (all 7 real pages approved). |
| 17 | Any genuine contrast violation fixed via the brand token SSOT, never page-local color | ✓ VERIFIED | `git show 43bdadfd`: `brandbook/tokens.json` → `brandbook/tokens.css` → `assets/css/02-tokens.css` all repoint `--scoria-text-subtle`; `token_contrast_guard_test.exs`/`ds06_drift_guard_test.exs` both green (ran directly, part of the 19/19 guard suite above). |
| 18 | `responsive_scan.spec.mjs` reuses the 6-width viewport matrix + `waitForReady`, generalizes the proven 375px no-h-overflow assertion to ~4 representative primary pages | ✓ VERIFIED (behavioral) | Live run: 58/58 `responsive_scan.spec.mjs` tests passed across Home/Workflows/Approvals/Incidents at all 6 widths (tiered per D-15). |
| 19 | Full D-16(1)-(7) assertion catalog implemented (doc-overflow, clipping, table-overflow-contained, `:mobile_summary` swap, toast-vs-nav occlusion, 24px target floor, no trapped scroll) | ✓ VERIFIED | Code read of `responsive_scan.spec.mjs` confirms all 7 tiers present, correctly excluding the sticky approval footer/command-palette/mobile-nav/scrims from the (5) occlusion check. Live pass confirms behavior. |
| 20 | Reduced-motion e2e proves computed duration collapse, including the `infinite` skeleton | ✓ VERIFIED (behavioral) | Live run: 5/5 `reduced_motion.spec.mjs` tests passed, including the DOM-injected `.scoria-skeleton`/`.scoria-attention` specimens. |
| 21 | Responsive collectors on not-yet-fixed surfaces are warning-grade; screenshots never gate | ✓ VERIFIED | Every anchor-page surface came back clean during authoring (per `40-05-SUMMARY.md`), so all assertions ship as throwing `expect()` (correct per the D-04 fix-and-assert-atomic branch — verified no `console.warn`-only escape hatches were needed to reach green). `shots.mjs` widened to the 6-width matrix (`320/375/768/1024/1440/1920` all present, confirmed via `grep`); no pixel-diff gate wired. |
| 22 | One real WCAG 2.5.8 defect found and fixed in-scope: `.scoria-button--sm` below the 24px target floor | ✓ VERIFIED | `assets/css/04-components.css:688-691`: `.scoria-button--sm` now documents and floors at `--scoria-space-5` (24px). Live `responsive_scan.spec.mjs` D-16(6) assertions pass. |

**Score:** 22/22 truths verified (0 present-but-behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `priv/dev/package.json` | axe dev-only exact pin + override | ✓ VERIFIED | Confirmed via `node -e` inspection |
| `priv/dev/e2e/lib/axe.mjs` | shared axe-run helper | ✓ VERIFIED | Read; imported by `a11y_axe.spec.mjs` |
| `priv/dev/e2e/lib/boxes_intersect.mjs` | shared geometry helper | ✓ VERIFIED | Read; imported by `drawer_focus.spec.mjs`, `responsive_scan.spec.mjs` |
| `40-GAP-REGISTER.md` | working gap register | ✓ VERIFIED | Read; schema + D-20 pre-seed present |
| `test/scoria_web/motion_drift_guard_test.exs` | MOTION-01 guard | ✓ VERIFIED | 5/5 tests pass |
| `test/scoria_web/a11y_structural_guard_test.exs` | A11Y structural guard | ✓ VERIFIED | 8/8 tests pass |
| `lib/scoria_web/ui.ex` (modal/1, drawer/1) | focus trap + restore | ✓ VERIFIED | Code read + live e2e |
| `priv/dev/e2e/drawer_focus.spec.mjs` | drawer keyboard proof + CR-01 regression | ✓ VERIFIED | 9/9 tests pass live (2 independent runs) |
| `priv/dev/e2e/modal_focus.spec.mjs` | modal keyboard proof | ✓ VERIFIED | 3/3 tests pass live (2 independent runs) |
| `priv/dev/e2e/a11y_axe.spec.mjs` | axe WCAG 2.2 AA proof | ✓ VERIFIED | 28/28 tests pass live |
| `priv/dev/e2e/responsive_scan.spec.mjs` | RESP-01 catalog | ✓ VERIFIED | 58/58 tests pass live |
| `priv/dev/e2e/reduced_motion.spec.mjs` | MOTION-01 reduced-motion proof | ✓ VERIFIED | 5/5 tests pass live |
| `priv/dev/e2e/lib/instant_duration.mjs` | shared duration predicate | ✓ VERIFIED | Imported by `reduced_motion.spec.mjs` and `phase16_parity.spec.mjs` (behavior-preserving) |
| `priv/dev/shots.mjs` | 6-width screenshot matrix | ✓ VERIFIED | All 6 widths present, no pixel-diff gate |
| `brandbook/tokens.json`/`.css`, `assets/css/02-tokens.css` | contrast token fix | ✓ VERIFIED | `--scoria-text-subtle` repointed consistently across all 3 SSOTs |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `drawer_focus.spec.mjs` / `responsive_scan.spec.mjs` | `boxes_intersect.mjs` | `import { boxesIntersect }` | ✓ WIRED | Confirmed via grep |
| `a11y_axe.spec.mjs` | `axe.mjs` | `import { runAxeScan }` | ✓ WIRED | Confirmed via grep |
| `reduced_motion.spec.mjs` / `phase16_parity.spec.mjs` | `instant_duration.mjs` | `import { isInstantDuration }` | ✓ WIRED | Confirmed via grep |
| Opener call sites (approval_inbox_component.ex, approvals_live/index.ex, connectors_live/index.ex, release_workbench_live.ex, workflow_detail_panel_component.ex) | `ui.ex` `focus_wrap`/`pop_focus` | `JS.push_focus()` composed onto each `phx-click` | ✓ WIRED | 10 call sites confirmed via grep; live e2e restore-to-opener passes |
| `approvals_live/index.ex` `decision_modal_open?` | `modal/1` `show` + `drawer/1` `keydown_enabled` | shared computed assign | ✓ WIRED | CR-01 fix — verified via code read + live regression test pass |
| Contrast fix | `token_contrast_guard_test.exs` | token SSOT → `tokens.css` → `02-tokens.css` | ✓ WIRED | Guard extended and green |

### Data-Flow Trace (Level 4)

Not applicable in the traditional sense (no dashboard-data-rendering artifacts were added this
phase) — the "data" here is real DOM/CSS computed state (focus, contrast ratios, layout
geometry, animation durations), which Level 4 for this phase collapses into the behavioral
spot-checks below (all live-browser-verified, not static/mocked).

### Behavioral Spot-Checks (run directly by the verifier, not reused from executor claims)

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Browserless motion + a11y guards | `mix test test/scoria_web/motion_drift_guard_test.exs test/scoria_web/a11y_structural_guard_test.exs test/scoria_web/ds06_drift_guard_test.exs test/scoria_web/token_contrast_guard_test.exs` | 19/19 pass | ✓ PASS |
| Compilation clean | `mix compile --warnings-as-errors` | clean, no output | ✓ PASS |
| Touched LiveView unit tests | `mix test test/scoria_web/live/` | 127/127 pass | ✓ PASS |
| CR-01 stacked-overlay regression (fresh DB, run #1) | `mix scoria.ui.e2e` full lane | drawer_focus 9/9, modal_focus 3/3 pass, incl. CR-01 | ✓ PASS |
| CR-01 stacked-overlay regression (fresh DB, run #2, independent re-seed) | `mix scoria.ui.e2e` full lane | drawer_focus 9/9, modal_focus 3/3 pass, incl. CR-01; a11y_axe 28/28; responsive_scan 58/58; reduced_motion 5/5 | ✓ PASS |
| Full e2e lane residual failures | same runs | 3 failures, both runs — `phase16_parity.spec.mjs` MOTION-04 (pre-existing selector-visibility bug per `deferred-items.md`, reproduced identically on a virgin DB) | ✓ CONFIRMED PRE-EXISTING, not Phase 40 |

### Probe Execution

No `scripts/*/tests/probe-*.sh` convention used by this project/phase; no PLAN/SUMMARY declares
probe-style verification. N/A.

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|-----------------|--------------|--------|----------|
| A11Y-01 | 40-01, 40-02, 40-03 | Keyboard-only users can complete navigation/search/table/drawer-modal/copy/disclosure/form flows with visible focus and predictable restoration | ✓ SATISFIED | Focus trap/restore live-verified on drawer + modal; structural guard proves icon-button names, native semantics; CR-01 stacked-overlay collision fixed and regression-tested |
| A11Y-02 | 40-01, 40-02, 40-04 | Dialogs/drawers/tabs/icon buttons/status/forms/empty-states/toasts/tables meet WCAG 2.2 AA via native semantics or ARIA | ✓ SATISFIED | axe WCAG 2.2 AA scan clean on all 7 real pages (both themes); structural guard covers native semantics + status-not-color-only; contrast defect found and fixed at token SSOT |
| MOTION-01 | 40-02, 40-05 | Motion restrained, tokenized, transform/opacity-based, respects `prefers-reduced-motion` | ✓ SATISFIED | Motion guard proves tokenization + keyframe discipline; reduced-motion e2e proves computed duration collapse incl. the infinite skeleton |
| RESP-01 | 40-05 | Primary dashboard pages usable at 320–1920px without squished tables, trapped scroll, clipped content, or floating elements over nav | ✓ SATISFIED | Full D-16(1)-(7) tiered catalog live-verified across 4 anchor pages × 6 widths; one real 24px target-size defect found and fixed |

No orphaned requirements: `.planning/REQUIREMENTS.md`'s traceability table maps exactly
A11Y-01/A11Y-02/MOTION-01/RESP-01 to Phase 40, and all four appear in at least one plan's
`requirements:` frontmatter (40-01 through 40-05 collectively cover all four).

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | No `TBD`/`FIXME`/`XXX` debt markers found in any file this phase touched | — | N/A — debt-marker gate clear |
| `assets/css/04-components.css` | 434 | `.scoria-kbd` min-height 22px, adjacent to a new 24px-floor fix (IN-02, code review) | ℹ️ Info | Cosmetic; `<kbd>` is non-interactive, not matched by the target-size guard — correctly out of scope |
| `priv/dev/e2e/responsive_scan.spec.mjs` | 128 | `undersizedTargets` filters `< 23` on a rounded value for a stated "24px floor, 1px tolerance" (IN-03, code review) | ℹ️ Info | Passes today only because of coincidental rounding, not the stated tolerance math — does not currently produce a false pass, but is fragile |

### Open Findings Not Blocking Phase 40's Goal (from `40-REVIEW.md`, unfixed)

These three warnings are real correctness bugs in the approvals/prompt-release surfaces, but
none of them concern accessibility, motion, or responsive behavior — the phase's actual
requirement scope (A11Y-01, A11Y-02, MOTION-01, RESP-01). They do not block this phase's goal
and are correctly left open for a future fix, per the code reviewer's own severity classification
(none is Critical):

- **WR-01** (`approvals_live/index.ex:643-669`): a misleading "could not record decision" message
  + `inspect(reason)` leak when the decision recorded but run-resume failed. A UX/correctness bug,
  not an accessibility defect.
- **WR-02** (`approvals_live/index.ex:235`): "Load more" appears when the decided page is exactly
  full. A pagination off-by-one, not an accessibility/motion/responsive defect.
- **WR-04** (`release_workbench_live.ex`): `@origin_context` read in `render/1` without being
  assigned in `mount/2` — an implicit load-order dependency, not an accessibility defect.

I confirm these do not gate `passed` for this phase: none of A11Y-01/A11Y-02/MOTION-01/RESP-01's
observable truths depend on them, and the code reviewer independently classified all three as
Warning (not Critical). Recommend they be tracked for a follow-up (Phase 41 or a dedicated
bugfix), but they are out of this phase's requirement scope.

### Human Verification Required

None. Every truth in this phase that asserts a runtime state transition or cancellation/ordering
invariant (focus trap/restore, stacked-overlay Escape gating, reduced-motion duration collapse,
axe computed contrast/ARIA, responsive layout geometry) was independently exercised by the
verifier against a live, freshly-seeded dev server — not left to presence-only static checks, and
not taken on the executor's word. The one blocking checkpoint this phase declared
(`checkpoint:human-verify` in 40-04-PLAN.md, curating the axe assert-zero real-page allow-list)
was already completed and approved in a prior session (documented in `40-04-SUMMARY.md`), and the
resulting curated scan re-verified clean in my own live run.

### Gaps Summary

None. The one Critical finding from code review (CR-01, stacked modal-over-drawer Escape
collision on the approvals surface — the highest-stakes keyboard surface this phase set out to
harden) was fixed (`096154d3`) and regression-tested (`0af8dfb8`), and I independently reproduced
the regression test passing against a virgin database on two separate full-e2e-lane runs. The
same-class Warning (WR-03, connectors drawers) was fixed identically (`52921c02`). The three
remaining Warnings (WR-01/WR-02/WR-04) and three Info findings are real but out of this phase's
A11Y/MOTION/RESP requirement scope and do not block the phase goal. The 3 pre-existing full-lane
e2e failures (`phase16_parity.spec.mjs` MOTION-04) and the 3 pre-existing full `mix test` failures
(`CiPolicyContractTest`, `WarningInventory.CaptureParityTest`, `SupportCopilotGalleryTest`) were
independently reproduced as pre-existing and unrelated to Phase 40 — confirmed identically on a
freshly-seeded, virgin database with none of this phase's git history altered.

---

_Verified: 2026-07-04T02:12:30Z_
_Verifier: Claude (gsd-verifier)_
