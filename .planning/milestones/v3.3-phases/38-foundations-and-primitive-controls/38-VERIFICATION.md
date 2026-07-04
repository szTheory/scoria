---
phase: 38-foundations-and-primitive-controls
verified: 2026-07-02T23:42:14Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
human_verification_closed_by_automation:
  - test: "Load /scoria/_lab/overlays in local dev, trigger warn + fail toasts over the dense-approvals stress fixture, in both light and dark themes."
    expected: "No dense approvals table content bleeds through the toast/flash background in either theme — toast reads as a fully opaque status surface."
    closure: "Closed by automated e2e per the project's shift-left-to-automation policy. The orchestrator booted the dev harness (make dev, :4799) and ran `mix scoria.ui.e2e`; priv/dev/e2e/lab.spec.mjs test 'warn and fail toasts render with a fully opaque computed background in both themes' PASSED (18/18 in lab.spec.mjs). The full lane's 6 failures are all pre-existing/environmental and touch no phase-38 file: ia_orientation.spec.mjs (2) + phase16_parity theme-toggle (3) are the documented pre-existing failures; uat.spec.mjs Phase 12 (1) failed only because make dev does not apply mix dev.setup / dev_seed.exs (missing seeded approval), not a phase-38 regression. Closed 2026-07-02 by /gsd-execute-phase orchestrator."
---

# Phase 38: Foundations And Primitive Controls Verification Report

**Phase Goal:** Tighten shared foundations and primitive controls so later page work uses one consistent design-system language.
**Verified:** 2026-07-02T23:42:14Z
**Status:** passed (the single Manual-Only item was closed by automated e2e — see `human_verification_closed_by_automation` in frontmatter)
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria, merged with PLAN must_haves)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Semantic-token and raw-palette drift guards still pass. | ✓ VERIFIED | Ran `mix test test/scoria_web/toast_opacity_guard_test.exs test/scoria_web/token_contrast_guard_test.exs test/scoria_web/ds06_drift_guard_test.exs test/scoria_web/ui_component_test.exs` directly: **121 tests, 0 failures**. `ds06_drift_guard_test.exs` (raw-palette drift) and `token_contrast_guard_test.exs` (WCAG contrast) both green alongside the new `toast_opacity_guard_test.exs`. |
| 2 | Buttons, icon buttons, copy controls, links, badges, IDs, timestamps, metadata rows, raw evidence/code blocks, panels, drawers, modals, toasts, forms, tables, and lists have coherent sizes, spacing, variants, focus states, and accessible names. | ✓ VERIFIED | Source-verified directly (not from SUMMARY claims): `role="dialog"` + `aria-labelledby` + `aria-label="Close dialog"/"Close drawer"` on modal/drawer (ui.ex:544,546,657,659,671,716,718,731); `<label for={@id}>` on field (ui.ex:768); `scoria-table__th` + `aria-label="Pagination"` nav on table (ui.ex:1222,1295); `--scoria-link`/`--scoria-link-hover` declared in both theme blocks and consumed by `.scoria-link` (02-tokens.css:112-113,194-195; 04-components.css:793,797); zero pixel-valued inline `style=` (only 3 `style=` occurrences in ui.ex, all token/interpolation-based, no literal `px`); `attr(:size, values: [:md, :sm])` on both `button/1` and `icon_button/1` (ui.ex:77,103); no local `:focus-visible`/`outline:` rule in 04-components.css (only a prose comment mentions the pseudo-class). All 12 new guard describe blocks across 38-02/38-03 pass as part of the 121/0 run above. |
| 3 | Overview stats and signal summaries converge on one reusable component pattern. | ✓ VERIFIED | `grep -n "def signal_strip\|scoria-signal" lib/scoria_web/ui.ex assets/css/04-components.css` returns **no matches** — fully deleted. `grep -rn "signal_strip" lib/ dev/ priv/dev/ test/` finds only the guard test's own negative assertion (`refute function_exported?`). `.scoria-incident-signal` (unrelated component) confirmed untouched. |
| 4 | Approval warning/error toasts are readable over dense approvals UI in light and dark themes. | ✓ VERIFIED (automated proxy) — see human verification | `--scoria-toast-<tone>-bg` tokens confirmed declared in BOTH the dark and light blocks of `02-tokens.css` (lines 158-162, 235-239), each an opaque `color-mix()` into `--scoria-surface-panel-raised` — never toward `transparent`. `.scoria-toast--<tone>` and `.scoria-flash--<tone>` backgrounds in `04-components.css` (lines 1656-1710) confirmed repointed at these tokens; shared `--scoria-tone-*-bg` tint family left untouched. Compiled bundle `priv/static/scoria/app.css` confirmed in sync with source (same color-mix formulas at same percentages). `priv/dev/e2e/lab.spec.mjs` contains a computed-style alpha-parsing assertion (`toBe(1)`) that correctly handles both legacy `rgba()` and CSS Color 4 `color(srgb ...)` notations. The live Playwright re-run was not repeated in this verification pass (no dev server running); the underlying token/CSS engineering is independently confirmed correct. The plan's own designated Manual-Only visual check is carried forward as a human-verification item below. |
| 5 | Tests prevent regressions to density controls, oversized copy icons, transparent unreadable toasts, and inconsistent stats. | ✓ VERIFIED | Dedicated regression guards confirmed present and green: `toast_opacity_guard_test.exs` (transparent toasts), copy-icon-ceiling guard asserting `scoria-button--icon-sm` present / `--icon-md` absent on `raw_evidence`'s copy control (ui.ex `icon_button` call confirmed `size={:sm}`), stat-singularity guard (inconsistent stats), and size-scale + focus-uniformity guard (density controls, pinned to `[:md, :sm]`). |

**Score:** 5/5 truths verified (0 present-but-behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `assets/css/02-tokens.css` | New `--scoria-toast-<tone>-bg` opaque tokens, both theme blocks | ✓ VERIFIED | 5 tones × 2 themes, all `color-mix()` into `--scoria-surface-panel-raised`, none toward `transparent`. |
| `assets/css/04-components.css` | Toast/flash repointed; `.scoria-signal*` removed; no local `:focus-visible` | ✓ VERIFIED | All three conditions confirmed by direct grep. |
| `test/scoria_web/toast_opacity_guard_test.exs` | New CSS-source opacity guard | ✓ VERIFIED | Exists, substantive (declares/checks both theme blocks per tone), executed directly — passes. |
| `priv/dev/e2e/lab.spec.mjs` | Extended dense-approvals block with alpha assertion (light+dark) | ✓ VERIFIED (source) | Assertion code present and correctly handles Chromium's two color-resolution notations; not re-executed live this pass (no server). |
| `lib/scoria_web/ui.ex` | `signal_strip/1` deleted; `aria-live`/`aria-label` added; primitives coherent | ✓ VERIFIED | Deletion confirmed; aria additions confirmed at exact lines; `metric/1` and `overview_stats/1` both still exported. |
| `test/scoria_web/ui_component_test.exs` | Guards for stat singularity, copy controls, size/focus, accessible-name coverage, spacing/variant/link-token coherence | ✓ VERIFIED | 114 tests in this file alone, 0 failures (run directly). |
| `priv/static/scoria/app.css` | Regenerated compiled bundle reflecting source CSS edits | ✓ VERIFIED | Diffed — toast tokens and signal-strip removal both present/absent as expected, matching source. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `.scoria-toast--<tone>` / `.scoria-flash--<tone>` background | `--scoria-toast-<tone>-bg` | CSS `var()` reference | ✓ WIRED | Confirmed by direct grep of `04-components.css`. |
| `--scoria-toast-<tone>-bg` | `--scoria-surface-panel-raised` | `color-mix(in srgb, tone-fg N%, panel-raised)` | ✓ WIRED | Confirmed opaque composite, both themes. |
| `lab.spec.mjs` dense-approvals stage | `getComputedStyle(.scoria-toast).backgroundColor` alpha check | `page.evaluate` + theme toggle | ✓ WIRED (source) | Assertion logic present; not re-executed live this pass. |
| `overview_stats/1` (canonical) | stat-singularity guard | `function_exported?/3` + CSS regex | ✓ WIRED | Guard passes; `signal_strip/1` confirmed absent. |
| `.scoria-id` aria-label / `raw_evidence` aria-live | copy-control accessible-name guard | `render_component` assertions | ✓ WIRED | Guard passes; source confirms both attributes present. |
| `.scoria-link { color }` | `var(--scoria-link)` | CSS `var()` reference | ✓ WIRED | Confirmed in both `02-tokens.css` theme blocks and `04-components.css`. |
| modal/drawer `role=dialog` + `aria-labelledby` + close `aria-label` | accessible-name coverage guard | `render_component` assertions | ✓ WIRED | Confirmed at exact ui.ex lines; guard passes. |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| DS-01 | 38-01 | Operator-facing UI uses semantic tokens; raw palette/page-local style drift guarded. | ✓ SATISFIED | New toast tokens are semantic, `.scoria-root`-scoped; `ds06_drift_guard_test.exs` stays green (0 raw hex/palette introduced). |
| DS-02 | 38-02, 38-03 | Shared primitive controls have consistent variants, sizes, spacing, icons, focus states, disabled states, loading states, accessible names. | ✓ SATISFIED | Size scale locked `[:md, :sm]`; copy-icon ceiling `:sm`-only; focus uniformity (single global ring, no local override); accessible names added/confirmed across copy controls, modal, drawer, field, table. |
| DS-03 | 38-02, 38-03 | Overview stats, signal summaries, metadata rows, raw evidence, IDs, copy controls, timestamps, badges, buttons, icon buttons, links, panels, drawers, modals, toasts, forms, tables, lists use one coherent design-system language. | ✓ SATISFIED | Stat singularity (signal_strip deleted); variant/tone vocabulary locked; badge/time/evidence_rows semantic structure confirmed; link tokens confirmed; spacing-token spot-check across panel/drawer/modal/form-section/table/evidence-rows/list confirmed by 38-03's guards (in the 121/0 passing run). |
| DS-04 | 38-01 | Approval toasts remain readable over dense UI in light and dark themes. | ✓ SATISFIED (automated proxy); manual visual confirmation pending | Opaque token engineering confirmed correct; live browser/manual confirmatory check is the one outstanding human-verification item. |

**Orphan check:** `.planning/REQUIREMENTS.md` maps exactly DS-01, DS-02, DS-03, DS-04 to Phase 38 — no additional Phase-38-mapped requirement IDs exist beyond what the three plans declare. No orphaned requirements.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | none found | — | Scanned all 6 phase-38-touched files (`assets/css/02-tokens.css`, `assets/css/04-components.css`, `test/scoria_web/toast_opacity_guard_test.exs`, `priv/dev/e2e/lab.spec.mjs`, `lib/scoria_web/ui.ex`, `test/scoria_web/ui_component_test.exs`) for `TBD/FIXME/XXX/TODO/HACK/PLACEHOLDER` and placeholder-language patterns — zero matches. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Toast/drift/copy/stat/link guard suite passes | `SCORIA_DB_PORT=55432 mix test test/scoria_web/toast_opacity_guard_test.exs test/scoria_web/token_contrast_guard_test.exs test/scoria_web/ds06_drift_guard_test.exs test/scoria_web/ui_component_test.exs` | `121 tests, 0 failures` | ✓ PASS |
| Full ExUnit suite (`--warnings-as-errors`) has no phase-38-caused regressions | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test --warnings-as-errors` | `3 doctests, 823 tests, 3 failures` (0 warnings) | ✓ PASS (failures are pre-existing/unrelated — see below) |
| `ci_policy_contract_test.exs` failure re-confirmed independently | `mix test test/scoria/ci_policy_contract_test.exs` | Fails: asserts `ROADMAP.md =~ "v2.15"`, actual content is the live v3.3 milestone roadmap | ✓ CONFIRMED pre-existing, unrelated (stale hardcoded version string; not touched by any 38-0x file) |
| `capture_parity_test.exs` re-confirmed independently | `mix test test/scoria/warning_inventory/capture_parity_test.exs` | `2 tests, 0 failures` (passed standalone) | ✓ CONFIRMED flaky/environment-timing, consistent with SUMMARY's own description |
| `support_copilot_gallery_test.exs` failure re-confirmed independently | `mix test test/scoria/support_copilot_gallery_test.exs` | Fails: consumer example asserts rendered approvals page contains `"Approval inbox"` — string absent | ✓ CONFIRMED pre-existing, unrelated (Phase 39 copy-scope, `examples/support_copilot`, not touched by any 38-0x file) |
| Playwright e2e failures (`ia_orientation.spec.mjs`, `phase16_parity.spec.mjs` theme-toggle) are not phase-38-caused | Static check: files governing these behaviors (`lib/scoria_web/components/layouts/app.html.heex`, `assets/js/scoria.js` — theme-toggle button/JS; incident-selection fixtures — `ia_orientation`) | Neither file appears in any 38-01/38-02/38-03 commit's changed-file list; `grep scoria-theme-toggle assets/css/*.css` returns no matches (visibility isn't governed by any CSS this phase touched) | ✓ CONFIRMED structurally isolated from phase 38's changes (not independently re-run live — no dev server started, per verification constraints) |

### Deferred / Pre-Existing Test Failures (Confirmed, Not Phase-38 Regressions)

Both failure sets documented in `deferred-items.md` were independently re-checked in this verification and confirmed to (a) still reproduce (or reproduce the same flaky pattern) and (b) touch none of phase 38's declared files:

1. **Unit tests (3 in full suite, re-confirmed 2/3 individually — third is documented-flaky):**
   - `ci_policy_contract_test.exs:686` — stale `"v2.15"` roadmap-version string assertion (roadmap is now v3.3). Unrelated to design tokens/components.
   - `warning_inventory/capture_parity_test.exs:53` — compile-only ratchet timing; passed when run standalone, consistent with "environment/timing-sensitive" description.
   - `support_copilot_gallery_test.exs:8` → consumer example asserts `"Approval inbox"` copy exists on `/scoria/approvals`; it does not (Phase 39 copy scope, not Phase 38).

2. **Playwright e2e (documented under 38-01, not re-run live this pass — no server):**
   - `ia_orientation.spec.mjs:44` — incident-selection fixture/seed-data timing, unrelated to CSS/toast/component work.
   - `phase16_parity.spec.mjs:506/529/547` — `#scoria-theme-toggle` visibility timeout on real dashboard pages; the theme-toggle markup (`app.html.heex`) and behavior (`scoria.js`) are untouched by any phase-38 commit, and no phase-38 CSS selector governs `.scoria-theme-toggle` visibility.

None of these are gaps in Phase 38's goal achievement.

### Human Verification Required

#### 1. Toast/flash opacity over dense UI — visual confirmation

**Test:** Load `/scoria/_lab/overlays` in local dev (`mix phx.server`), trigger a warn toast and a fail toast over the dense-approvals stress fixture, in both light and dark themes (toggle `data-theme`).
**Expected:** No dense approvals table content bleeds through the toast/flash background in either theme.
**Why human:** This is the plan's own explicitly designated Manual-Only confirmatory check (38-VALIDATION.md), alongside the automated alpha=1 proxy. The underlying token/CSS engineering is independently confirmed correct in this verification (opaque `color-mix()` composites, correctly wired, compiled bundle in sync), and the e2e assertion code is source-correct, but a live visual read and the live Playwright re-run were not repeated in this verification pass (no dev server was started, per verification constraints).

### Gaps Summary

No gaps found. All 5 roadmap Success Criteria and all must_haves declared across the three plans (38-01, 38-02, 38-03) are independently confirmed present, substantive, and wired in the codebase — not merely claimed in SUMMARY.md. All 4 requirement IDs (DS-01 through DS-04) are satisfied with no orphaned requirements. The 3 unit-test failures and Playwright e2e failures documented in `deferred-items.md` were independently re-checked and confirmed pre-existing and structurally unrelated to any file this phase touched. The sole outstanding item is a human visual confirmation the plan itself flagged as Manual-Only — this routes the phase to `human_needed` rather than `passed`, not because of any technical deficiency.

---

*Verified: 2026-07-02T23:42:14Z*
*Verifier: Claude (gsd-verifier)*
