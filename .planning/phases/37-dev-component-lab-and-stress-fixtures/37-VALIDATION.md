---
phase: 37
slug: dev-component-lab-and-stress-fixtures
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-02
---

# Phase 37 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) + Playwright (`priv/dev/e2e/*.spec.mjs`) |
| **Config file** | `mix.exs` / `priv/dev/e2e/` (existing — no Wave 0 install) |
| **Quick run command** | `mix test --no-start test/scoria_web/` |
| **Full suite command** | `mix test` then `mix scoria.ui.e2e` |
| **Estimated runtime** | ~30–90 seconds (ExUnit) |

---

## Sampling Rate

- **After every task commit:** Run `mix test --no-start test/scoria_web/`
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full suite + `mix scoria.ui.e2e` must be green
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

*Populated by the planner from PLAN.md tasks. Each lab guard/coverage test maps to a
requirement (LAB-01 / LAB-02 / FIXT-01) and uses source-scan ExUnit (regex over `dev/**/*.ex`)
or `priv/dev/e2e/lab.spec.mjs`.*

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 37-01-01 | 01 | 1 | LAB-01 | — | Lab excluded from `scoria_dashboard/2` + `package.files` | unit (source-scan) | `mix test --no-start test/scoria_web/` | ❌ W0 | ⬜ pending |

---

## Wave 0 Requirements

- [ ] `priv/dev/e2e/lab.spec.mjs` — lab route load / theme / reduced-motion / viewport probes (`test.fixme` for unproven bits — the `e2e` job is a required CI gate)
- [ ] Lab guard/coverage ExUnit test(s) under `test/scoria_web/` — source-scan pattern per `ds06_drift_guard_test.exs` (never `alias` a `dev/` module from `test/`)

*Existing ExUnit + Playwright infrastructure otherwise covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual "ugly data"/stress legibility judgement | LAB-02 | Subjective visual inspection is the lab's purpose; not asserted pixel-by-pixel (D-30 no screenshot-diff gate) | Run `make dev`, open `/scoria/_lab`, walk state bands + viewport simulator per `docs/MAINTAINERS.md` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
