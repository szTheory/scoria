---
phase: 40
slug: accessibility-motion-and-responsive-proof
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-03
---

# Phase 40 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `40-RESEARCH.md` § Validation Architecture (D-07 two-lane proof model).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework (Lane A — browserless)** | ExUnit (`mix test`), `async: true` |
| **Framework (Lane B — browser)** | Playwright `@playwright/test` 1.60.0, chromium project only |
| **Config file** | Lane A: none (plain `ExUnit.Case`); Lane B: `priv/dev/e2e/playwright.config.mjs` |
| **Quick run command** | `mix test test/scoria_web/` (targeted: the specific new/changed guard file) |
| **Full suite command** | `mix test` (Lane A) + CI `e2e` job (`mix scoria.ui.e2e`) |
| **Estimated runtime** | Lane A: sub-second (async source-scans). Lane B: ~1–3 min per CI e2e job |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/scoria_web/` (or the specific changed guard file) — sub-second, per D-04.
- **After every plan wave:** Full Lane A (`mix test`) + full Lane B (`mix scoria.ui.e2e --base-url http://localhost:4799/scoria` against a running `make dev`, or push and let the required CI `e2e` job run).
- **Before `/gsd-verify-work`:** Both `verify` and `e2e` CI jobs green (existing `ci-gate needs:[verify,e2e]` hard-fail, `.github/workflows/ci.yml:127-146`).
- **Max feedback latency:** Lane A < 5s; Lane B bounded by CI e2e job (~1–3 min).

> **Two-bucket rule (D-04, load-bearing):** any new Lane B assertion on a not-yet-fixed surface MUST be a non-throwing collector (`console.warn` + `testInfo.attach()`) until its fix lands in the SAME commit. Never let a new `expect()` merge ahead of its fix — it red-walls the required gate. Bans `test.fail()` and `expect.soft` as warning mechanisms.

---

## Per-Task Verification Map

| Req ID | Behavior | Test Type | Primary Owner (D-07) | Automated Command | File Exists |
|--------|----------|-----------|----------------------|-------------------|-------------|
| A11Y-01 | Drawer + modal tab-in / trap / Esc / restore-to-trigger | e2e (Playwright) | keyboard-e2e | `npx --prefix priv/dev playwright test drawer_focus.spec.mjs modal_focus.spec.mjs` | ❌ W0 |
| A11Y-01 | Focus not obscured by sticky approval footer (SC 2.4.11) | e2e | keyboard-e2e | drawer spec, `boxesIntersect(focusedRect, footerRect)` | ❌ W0 (needs `boxesIntersect`) |
| A11Y-01 | Live-patch focus survival on open drawer (D-13) — **warning-grade collector** | e2e | keyboard-e2e | drawer spec; `console.warn` + `testInfo.attach()`, no throwing `expect()` | ❌ W0 |
| A11Y-01 | Tables/disclosures/copy-controls/forms structural contract | browserless (LiveViewTest/source-scan) | source-scan | `mix test test/scoria_web/` | ⚠️ pattern exists, new assertions |
| A11Y-02 | Contrast/ARIA/name-role-value, **both themes** | e2e (axe-core) | axe | `npx --prefix priv/dev playwright test a11y_axe.spec.mjs` | ❌ W0 |
| A11Y-02 | Icon-button names, no color-only status, native-semantics presence (D-08) | browserless (source-scan) | source-scan | `mix test test/scoria_web/` (new guard, model on `ui_drift_guard_test.exs`) | ❌ W0 |
| A11Y-02 | Contrast confirmatory floor, both themes | browserless (pure-Elixir luminance) | source-scan (confirmatory) | `mix test test/scoria_web/token_contrast_guard_test.exs` | ✅ exists, dual-theme |
| MOTION-01 | Tokenized durations/eases except allow-list; keyframes transform/opacity/border-color only; no new `@keyframes` outside `05-motion.css` | browserless (source-scan) | source-scan | `mix test` (new guard, model on `ui_drift_guard_test.exs`) | ❌ W0 |
| MOTION-01 | Reduced-motion collapses computed `animationDuration`/`transitionDuration` | e2e | direct computed-style | `npx --prefix priv/dev playwright test` (extend proven `emulateMedia` pattern) | ⚠️ pattern exists, extend |
| RESP-01 | No document h-overflow at 6 widths × ~4 representative pages | e2e | responsive-scan | `npx --prefix priv/dev playwright test responsive_scan.spec.mjs` | ❌ W0 |
| RESP-01 | No essential element clipped off-viewport (curated selectors) at 320/375/768 | e2e | responsive-scan | responsive_scan spec | ❌ W0 |
| RESP-01 | Table overflow contained not leaked; `:mobile_summary` swap correctness | e2e | responsive-scan | responsive_scan spec (generalize `phase16_parity.spec.mjs`) | ⚠️ 1 page proven, generalize |
| RESP-01 | No fixed/floating region covering nav (excl. sticky footer / palette / mobile-nav / scrims) | e2e | responsive-scan | responsive_scan spec, `boxesIntersect` | ❌ W0 |
| RESP-01 | 24px min target at ≤375 (regression floor, NOT axe target-size) | e2e | responsive-scan | responsive_scan spec | ❌ W0 |

*Status per task tracked in PLAN.md `<verify>` blocks: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `priv/dev/package.json` + lockfile — add `@axe-core/playwright` exact-pinned + `overrides` pin on transitive `axe-core` (D-05). Prerequisite for the axe spec.
- [ ] `priv/dev/e2e/lib/boxes_intersect.mjs` — shared `boxesIntersect(a,b)` helper imported by both `drawer_focus.spec.mjs` (D-11 dynamic occlusion) and `responsive_scan.spec.mjs` (D-16(5) static occlusion) (D-17).
- [ ] `priv/dev/e2e/a11y_axe.spec.mjs` — A11Y-02 axe scan, both themes, report-only baseline first (D-06). Must set `rules: { 'target-size': { enabled: true } }` explicitly (research finding: disabled by default in axe-core 4.12.1) — kept report-only.
- [ ] `priv/dev/e2e/drawer_focus.spec.mjs` + `priv/dev/e2e/modal_focus.spec.mjs` (or combined) — A11Y-01 keyboard-driving. Fix-and-assert-atomic with the D-10 focus fix.
- [ ] `priv/dev/e2e/responsive_scan.spec.mjs` — RESP-01; generalizes `phase16_parity.spec.mjs`. Independent of D-10.
- [ ] `test/scoria_web/motion_drift_guard_test.exs` — MOTION-01 static scan; model on `ui_drift_guard_test.exs`. **Allow-list BOTH `scoria-skeleton-pulse` AND `scoria-approval-pulse` by animation-name** (research finding — else false-RED on landing).
- [ ] `test/scoria_web/a11y_structural_guard_test.exs` — A11Y-02 D-08 structural assertions (icon-button names, color-only-status, native-semantics presence).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Screenshot contact-sheet (6-width) visual review | RESP-01 | Screenshots never gate (font-AA/timing flaky, D-14) — human evidence only | Widen `priv/dev/shots.mjs` to 6 viewports, render via `contact_sheet.mjs`, eyeball for clipping/squish |
| axe report-only baseline curation (which real pages ratchet to assert-zero) | A11Y-02 | Baseline needs human inspection before ratcheting (D-06) | Read attached baseline violation breakdown; curate the assert-zero allow-list of seeded real pages |

---

## Validation Sign-Off

- [ ] All tasks have `<verify>` (automated) or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (new spec/guard files above)
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s (Lane A) / bounded by CI e2e (Lane B)
- [ ] Two-bucket rule honored: every new hard `expect()` ships fix-and-assert-atomic; warning-grade = non-throwing collector
- [ ] `nyquist_compliant: true` set in frontmatter (at plan finalization)

**Approval:** pending
