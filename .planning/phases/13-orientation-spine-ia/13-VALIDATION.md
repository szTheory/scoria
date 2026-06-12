---
phase: 13
slug: orientation-spine-ia
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-11
---

# Phase 13 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix LiveViewTest |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/scoria_web/dashboard_nav_test.exs test/scoria_web/router_test.exs test/scoria_web/ui_component_test.exs test/scoria_web/ds06_drift_guard_test.exs` |
| **Full suite command** | `mix test test/scoria_web/` |
| **Estimated runtime** | ~30-90 seconds for focused web suite; full project suite is longer |

---

## Sampling Rate

- **After every task commit:** Run the focused test for the changed slice plus `mix test test/scoria_web/ds06_drift_guard_test.exs`
- **After every plan wave:** Run `mix test test/scoria_web/`
- **Before `$gsd-verify-work`:** Run `mix test`
- **Max feedback latency:** ~90 seconds for web-slice feedback

---

## Per-Task Verification Map

> Task IDs are provisional until plans are written; the planner finalizes them.

| Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|----------|-----------|-------------------|-------------|--------|
| IA-01 | Sidebar groups are Operate / Improve / Configure; Connectors is Configure; `WorkflowLive.Index` activates Runs; stubs activate their nav item | unit + route | `mix test test/scoria_web/dashboard_nav_test.exs test/scoria_web/router_test.exs` | ❌ W0 (`dashboard_nav_test.exs`) | ⬜ pending |
| IA-02 | `/scoria` renders Home copy, exact identity line, nonzero attention cards or all-clear, day-0 empty copy, and existing live trace stream still works | LiveView | `mix test test/scoria_web/live/orchestrator_live_test.exs test/scoria_web/live/orchestrator_live_integration_test.exs` | ✅ | ⬜ pending |
| IA-03 | Object pages render parent crumb, truncated copyable object ID, identity row, and optional allowlisted origin chip | component + LiveView | `mix test test/scoria_web/ui_component_test.exs test/scoria_web/live/workflow_live_test.exs` | ✅ | ⬜ pending |
| IA-04 | Layout renders accessible command palette markup/data from nav SSOT; visible `Cmd+K` hint and `?` overlay are present | component/Layout + manual keyboard lane | `mix test test/scoria_web/ui_component_test.exs test/scoria_web/live/orchestrator_live_test.exs` | ✅ | ⬜ pending |
| IA-05 | Review/run/release surfaces expose consistent next-step verbs and preserve `?from=` context where applicable | LiveView | `mix test test/scoria_web/live/review_queue_live_test.exs test/scoria_web/live/workflow_live_test.exs test/scoria_web/live/prompt_live_test.exs` | ✅ | ⬜ pending |
| IA-06 | Five reserved capabilities appear as Soon in nav/palette and route to one honest shared stub page | unit + route + LiveView | `mix test test/scoria_web/dashboard_nav_test.exs test/scoria_web/router_test.exs test/scoria_web/live/coming_soon_live_test.exs` | ❌ W0 (`dashboard_nav_test.exs`, `coming_soon_live_test.exs`) | ⬜ pending |
| DS-06 | Phase 13 does not grow raw Tailwind palette usage | unit | `mix test test/scoria_web/ds06_drift_guard_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/scoria_web/dashboard_nav_test.exs` — unit coverage for nav groups, active keys, stub metadata, command metadata, and base derivation.
- [ ] `test/scoria_web/live/coming_soon_live_test.exs` — LiveView coverage for the shared stub page once the route/module exists.
- [ ] Existing `test/scoria_web/router_test.exs` extended for `/scoria/coming/:screen`.
- [ ] Existing `test/scoria_web/ui_component_test.exs` extended for `object_header/1` and any palette/stub shell components.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `Cmd+K` / `Ctrl+K` opens palette, Escape closes, and focus returns to invoker | IA-04 | Browser focus trap and global keyboard listener behavior are client-side | Boot dashboard, press shortcut, inspect focus, close with Escape, confirm focus restoration. |
| `g` chords navigate and time out after 1.5s | IA-04 | Chord timing lives in `assets/js/scoria.js` | Press `g h`, `g a`, `g r`, `g i`, `g c`, `g q`, `g e`, `g p`; verify expected screen and timeout behavior. |
| Palette filtering uses aliases, hides empty sections, and does not hijack inputs/IME | IA-04 | Vanilla hook filtering is browser-side | Type `runs`; verify matching row. Focus a form field and confirm owned shortcuts do not fire. |
| Palette/open-close motion respects `prefers-reduced-motion` | IA-04 | CSS media query behavior requires browser rendering | Toggle reduced motion in browser/devtools and confirm opacity transition is skipped or minimized. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s for focused web suite
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
