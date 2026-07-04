---
phase: 36
slug: baseline-and-inventory
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-20
---

# Phase 36 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Phoenix.LiveViewTest; Playwright remains advisory/browser-truth only when proof surfaces change |
| **Config file** | `mix.exs`, `config/test.exs`, `priv/dev/e2e/playwright.config.mjs` |
| **Quick run command** | `mix test test/scoria_web/ui_component_test.exs test/scoria_web/ds06_drift_guard_test.exs test/scoria_web/ui_drift_guard_test.exs --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Estimated runtime** | quick: ~30-90 seconds; full: project-dependent |

---

## Sampling Rate

- **After every task commit:** Run the focused artifact contract once it exists, plus `mix test test/scoria_web/ds06_drift_guard_test.exs --warnings-as-errors`.
- **After every plan wave:** Run `mix test --warnings-as-errors`.
- **Before `/gsd:verify-work`:** Full suite must be green, inventory artifacts must parse, and required starting risks must be present.
- **Max feedback latency:** Prefer under 90 seconds for focused checks; full-suite latency is acceptable at wave boundaries.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 36-01-01 | 01 | 1 | BASE-01 | T-36-01 / RISK-V30-PROOF | Baseline claims cite git provenance and existing proof surfaces without executing untrusted content | artifact/source contract | `mix test test/scoria_web/design_inventory_contract_test.exs --warnings-as-errors` once created | No | pending |
| 36-01-02 | 01 | 1 | INV-01 | T-36-02 / — | Structured index enumerates foundations, primitives, component groups, pages, hooks, fixtures, tests, docs, and one-offs | artifact contract | `mix test test/scoria_web/design_inventory_contract_test.exs --warnings-as-errors` once created | No | pending |
| 36-01-03 | 01 | 1 | INV-02 | T-36-03 / — | Inventory rows use only locked `layer` and `status` enum values with unique stable IDs | artifact contract | `mix test test/scoria_web/design_inventory_contract_test.exs --warnings-as-errors` once created | No | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] `.planning/phases/36-baseline-and-inventory/36-INVENTORY.md` — maintainer-readable baseline, inventory rationale, and risk narrative.
- [ ] `.planning/phases/36-baseline-and-inventory/36-inventory.json` — canonical structured row store with stable IDs, layer/status fields, evidence, ownership, and risk refs.
- [ ] `test/scoria_web/design_inventory_contract_test.exs` or an equivalent repository-local artifact validation script — validates required row fields, enum values, unique IDs, and required risk IDs.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Advisory screenshot evidence remains advisory only | BASE-01 | Screenshot harness determinism is explicitly deferred to Phase 41 | Confirm no Phase 36 plan adds screenshot-diff CI, threshold gates, or required image comparison. |
| Inventory classification judgment | INV-01, INV-02 | Some canonical/duplicated/legacy/page-specific calls require maintainer-readable rationale | Review `36-INVENTORY.md` examples against `36-inventory.json` IDs and confirm rationale cites evidence paths. |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [ ] Wave 0 covers all missing artifact-contract references.
- [ ] No watch-mode flags.
- [ ] Feedback latency target recorded for quick checks.
- [ ] `nyquist_compliant: true` set in frontmatter after plans include the artifact contract and focused commands.

**Approval:** pending
