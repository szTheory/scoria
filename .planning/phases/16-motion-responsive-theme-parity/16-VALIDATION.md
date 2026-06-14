---
phase: 16
slug: motion-responsive-theme-parity
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-13
---

# Phase 16 - Validation Strategy

Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit / Phoenix LiveViewTest plus Playwright `@playwright/test` 1.60.0 |
| **Config file** | `priv/dev/e2e/playwright.config.mjs` |
| **Quick run command** | `mix test test/scoria_web/ui_component_test.exs test/scoria_web/ds06_drift_guard_test.exs test/scoria_web/ui_drift_guard_test.exs` |
| **Full suite command** | `mix test` plus `mix scoria.ui.e2e` with the dev server running |
| **Estimated runtime** | Targeted ExUnit under 60s; browser suite depends on dev server startup |

---

## Sampling Rate

- **After every task commit:** Run the targeted ExUnit file for touched components plus `mix test test/scoria_web/ds06_drift_guard_test.exs`.
- **After every plan wave:** Run `mix test test/scoria_web`; add `mix scoria.ui.e2e` when shell, table, JavaScript, theme, or viewport behavior changes.
- **Before `$gsd-verify-work`:** `mix test` and `mix scoria.ui.e2e` must be green against a seeded dev server.
- **Max feedback latency:** One targeted automated check per task; no three consecutive tasks may rely only on manual inspection.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 16-W0-01 | 16-06 | 0 | MOTION-01, MOTION-03, MOTION-04 | T-16-03 / T-16-04 | Browser checks stay targeted and do not create broad CI denial-of-service risk | e2e | `mix scoria.ui.e2e` | Missing `priv/dev/e2e/phase16_parity.spec.mjs` | pending |
| 16-W0-02 | 16-02, 16-06 | 0 | MOTION-02, MOTION-03 | T-16-01 / T-16-03 | HEEx row summaries remain escaped; mobile nav preserves keyboard access | component/e2e | `mix test test/scoria_web/ui_component_test.exs && mix scoria.ui.e2e` | Partial existing coverage | pending |
| 16-W0-03 | 16-06 | 0 | MOTION-04 | - | Theme tokens preserve WCAG AA contrast in light and dark modes | source/browser | `mix scoria.ui.e2e` plus optional contrast guard | Optional guard missing | pending |

---

## Wave 0 Requirements

- [ ] `priv/dev/e2e/phase16_parity.spec.mjs` - targeted browser proof for MOTION-01 through MOTION-04.
- [ ] `ScoriaWeb.UI.table/1` component assertions for any new overflow or mobile summary API.
- [ ] Optional token contrast guard if the planner accepts the D-31 contrast-guard decision from context.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual polish review for restrained brand-tied motion | MOTION-01 | Browser automation can verify timing/properties/reduced-motion, but final brand fit is judgment-based | Review changed interactions in light and dark themes; reject fire/sparkle/bounce motifs, infinite loops, or motion above 200ms |
| Responsive information density review | MOTION-03 | Automation can catch overflow, but not whether the mobile table summary preserves useful scanning order | Check 375px, md, lg, and xl viewports for shell navigation, dashboard tables, and high-traffic forms |

---

## Validation Sign-Off

- [x] All tasks have automated verification or explicit Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verification.
- [x] Wave 0 covers all missing references listed above.
- [x] No watch-mode flags are used in verification commands.
- [x] Feedback latency stays bounded by targeted ExUnit or targeted Playwright checks.
- [x] `nyquist_compliant: true` set in frontmatter after verification coverage is proven.

**Approval:** approved
