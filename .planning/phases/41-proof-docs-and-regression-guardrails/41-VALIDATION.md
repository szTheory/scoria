---
phase: 41
slug: proof-docs-and-regression-guardrails
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-04
---

# Phase 41 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) + Node/Playwright screenshot harness (`mix scoria.ui.e2e`) |
| **Config file** | `test/test_helper.exs`; e2e via `mix scoria.ui.e2e` |
| **Quick run command** | `{quick command — planner to set per plan, e.g. mix test test/scoria_web/...}` |
| **Full suite command** | `mix test` (+ `mix scoria.ui.e2e` for browser proof) |
| **Estimated runtime** | ~{N} seconds |

---

## Sampling Rate

- **After every task commit:** Run `{quick run command}`
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** {N} seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| {N}-01-01 | 01 | 1 | PROOF-{XX} | T-41-01 / — | {expected secure behavior or "N/A"} | unit | `{command}` | ✅ / ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Planner: populate one row per task, mapping to PROOF-01/02/03. The two D-16b crash fixes each get a regression-test row whose assertion fails today (red) and passes after the fix.*

---

## Wave 0 Requirements

*If none: "Existing infrastructure covers all phase requirements."*

- [ ] Confirm existing ExUnit + `mix scoria.ui.e2e` infrastructure covers phase requirements (no new framework install expected — scope fence D-01: no new runtime deps).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| {behavior} | PROOF-{XX} | {reason} | {steps} |

*If none: "All phase behaviors have automated verification."*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < {N}s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
