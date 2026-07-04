---
phase: 38
slug: foundations-and-primitive-controls
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-07-02
---

# Phase 38 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (`mix test`) + Playwright (`mix scoria.ui.e2e`, config `playwright.config.mjs`, testMatch `**/*.spec.mjs`) |
| **Config file** | `test/test_helper.exs` (ExUnit) + `playwright.config.mjs` (Playwright) — both pre-existing, no new config |
| **Quick run command** | `SCORIA_DB_PORT=55432 mix test test/scoria_web/ui_component_test.exs test/scoria_web/ds06_drift_guard_test.exs test/scoria_web/token_contrast_guard_test.exs test/scoria_web/toast_opacity_guard_test.exs` |
| **Full suite command** | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test --warnings-as-errors` + `mix scoria.ui.e2e --base-url http://localhost:4799/scoria` |
| **Estimated runtime** | ~30s ExUnit quick run; ~60–90s full suite + e2e |

---

## Sampling Rate

- **After every task commit:** Run the quick run command (focused component + guard tests).
- **After every plan wave:** Run `mix scoria.ui.e2e` (deterministic Playwright, `waitForReady`, no fixed sleeps) against the extended `lab.spec.mjs`.
- **Before `/gsd-verify-work`:** Full ExUnit suite (`mix test --warnings-as-errors`) AND `mix scoria.ui.e2e` must be green.
- **Max feedback latency:** ~30 seconds (quick run).

---

## Per-Task Verification Map

| Requirement | Criterion / Decision | Test Type | Automated Command | File Exists | Status |
|-------------|----------------------|-----------|-------------------|-------------|--------|
| DS-01 | Crit 1 — raw-palette/drift guards stay green | unit | `mix test test/scoria_web/ds06_drift_guard_test.exs test/scoria_web/token_contrast_guard_test.exs` | ✅ existing | ⬜ pending |
| DS-04 | Crit 4 / D-01,D-02,D-04 — toast tone tokens resolve opaque (no `transparent` composite, alpha=1) in both themes | unit | `mix test test/scoria_web/toast_opacity_guard_test.exs` | ❌ W0 (new CSS-source guard) | ⬜ pending |
| DS-04 | Crit 4 — toast visibly opaque over dense-approvals fixture, light + dark | e2e | `mix scoria.ui.e2e` (extend dense-approvals+toast describe block) | 🔶 extend `priv/dev/e2e/lab.spec.mjs` | ⬜ pending |
| DS-03 | Crit 3 / D-05,D-08 — exactly one canonical stat component; no `.scoria-signal*` emission | unit | `mix test test/scoria_web/ui_component_test.exs` | 🔶 extend | ⬜ pending |
| DS-02/DS-03 | Crit 2 / D-09 — copy controls never render `scoria-button--icon-md` (capped at `:sm`) | unit | `mix test test/scoria_web/ui_component_test.exs` | 🔶 extend | ⬜ pending |
| DS-02 | Crit 2 / D-13,D-14 — controls use only `:md`/`:sm`; no ad-hoc pixel sizing | unit | `mix test test/scoria_web/ui_component_test.exs` | 🔶 extend | ⬜ pending |
| DS-02 | Crit 2 / D-15,D-16 — uniform token-bound focus/disabled/loading; no local `outline:` override | unit | `mix test test/scoria_web/ui_component_test.exs` | 🔶 extend | ⬜ pending |
| DS-02/DS-03 | Crit 2 / D-12 — every copy control has an accessible "Copy <thing>" name; `raw_evidence` copy-status has `aria-live` | unit | `mix test test/scoria_web/ui_component_test.exs` | 🔶 extend | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/scoria_web/toast_opacity_guard_test.exs` — NEW CSS-source guard for DS-04/Crit 4 (regex-scan each theme block in `assets/css/02-tokens.css`; assert new `--scoria-toast-*` tone bg declarations contain no `transparent` and no `rgba(...)` with alpha < 1). Kept separate from `token_contrast_guard_test.exs` because that guard *flunks* on any `color-mix()`-valued token in its checked pairs.
- [ ] Extend `test/scoria_web/ui_component_test.exs` with describe blocks: stat singularity (D-05/D-08), copy-icon ceiling (D-09), density scale (D-13/D-14), focus/disabled uniformity spot-check (D-15/D-16), copy accessible-name + `aria-live` (D-12).
- [ ] Extend `priv/dev/e2e/lab.spec.mjs` dense-approvals+toast describe block with a computed-style alpha assertion (`getComputedStyle(...).backgroundColor` alpha === 1) in both `data-theme="light"` and `"dark"`.

*No new framework install — ExUnit and Playwright are fully wired.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Subjective toast legibility over dense UI (final visual judgment) | DS-04 | Alpha/contrast automatable, but final "reads clearly" judgment is human | Load `/scoria/_lab` overlays section, trigger warn+fail toasts over the dense-approvals fixture in both themes, confirm no bleed-through |

*All primary behaviors also have automated verification; the manual check is confirmatory only.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (toast-opacity guard + e2e alpha assertion)
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-07-02 (strategy finalized; `wave_0_complete` flips true once execution creates the guard files)
