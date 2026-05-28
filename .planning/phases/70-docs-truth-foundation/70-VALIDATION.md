---
phase: 70
slug: docs-truth-foundation
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-28
---

# Phase 70 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix |
| **Config file** | `mix.exs` (`cli/0` preferred_envs) |
| **Quick run command** | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/ci_policy_contract_test.exs test/mix/tasks/test.install_contract_test.exs` |
| **Full suite command** | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test.adoption` |
| **Estimated runtime** | ~60s quick · ~5–15m full adoption lane |

---

## Sampling Rate

- **After every task commit:** Run the task's `<automated>` verify command
- **After every plan wave:** Run quick run command above
- **Before `/gsd-verify-work`:** `mix test.adoption` green with Postgres on 55432
- **Max feedback latency:** 120 seconds (quick suite)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------|-------------------|--------|
| 70-01-01 | 01 | 1 | INST-DX-01 | unit | `mix test test/mix/tasks/test.install_contract_test.exs` | ⬜ pending |
| 70-01-02 | 01 | 1 | DOCS-03 | unit | `mix test --only adopter_doc_contract` (if tagged) or module compile | ⬜ pending |
| 70-02-01 | 02 | 2 | DOCS-03 | doc+unit | `rg -n 'shipped through' README.md` → no match | ⬜ pending |
| 70-03-01 | 03 | 3 | DOCS-04 | unit | `mix test test/scoria/ci_policy_contract_test.exs` | ⬜ pending |
| 70-03-02 | 03 | 3 | DOCS-03 | unit | `mix test test/scoria/adoption_surface_test.exs` | ⬜ pending |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No new framework install.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| README readability | DOCS-03 | Subjective prose polish allowed (D-01 discretion) | Skim banner + Install upgrade subsection for scannability |
| Gate map table layout | DOCS-04 | Markdown table not asserted column-by-column | Open `docs/operator_verification.md` § CI gate map |

---
