---
phase: 54
slug: docs-accuracy-conformance-check
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-18
---

# Phase 54 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir, mix test) |
| **Config file** | `test/test_helper.exs` / `mix.exs` (existing — no install needed) |
| **Quick run command** | `mix test test/scoria/observe/conformance_test.exs` |
| **Full suite command** | `mix test` |
| **Contract subset** | `mix test test/scoria/adoption_surface_test.exs test/scoria/ai_doc_contract_test.exs` |
| **Estimated runtime** | ~5s (conformance file) · full suite existing baseline |

---

## Sampling Rate

- **After every task commit:** Run the quick run command (conformance file) and, for DOCS-01 tasks, the contract subset.
- **After every plan wave:** Run `mix test` (full suite must stay green — no new warnings above `.planning/WARNING-BASELINE.md`).
- **Before `/gsd-verify-work`:** Full suite green + `mix format --check-formatted`.
- **Max feedback latency:** ~5 seconds (conformance file alone).

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 54-02-* | 02 | 1 | DOCS-02 | — | Conformance test RED when an unlisted key/kind appears (negative self-test bites) | unit | `mix test test/scoria/observe/conformance_test.exs` | ❌ W0 | ⬜ pending |
| 54-01-* | 01 | 1 | DOCS-01 | — | Contract guards accept the honest claim string, still block every `export`-bearing phrase | unit | `mix test test/scoria/adoption_surface_test.exs test/scoria/ai_doc_contract_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Exact task IDs assigned by the planner; DOCS-02 test file is created by this phase (❌ W0 until then), contract test files already exist (✅).*

---

## Wave 0 Requirements

- [ ] `test/scoria/observe/conformance_test.exs` — new ExUnit case (`Scoria.Observe.ConformanceTest`, `@moduletag :conformance`); this IS the DOCS-02 deliverable, not a stub.

*Contract tests (`adoption_surface_test.exs`, `ai_doc_contract_test.exs`) already exist and auto-cover the new claim string via their `@comparison_safe_current_claims` / `@required_llms_paths` loops — no new assertion file needed for DOCS-01.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| New guide prose reads honest / does not overclaim beyond the D-10 locked sentence | DOCS-01 | Prose quality is not machine-checkable beyond the guard substring | Reviewer reads `guides/capabilities/trace-observability.md`; confirm no `export`-as-current-claim language |

*All falsifiable behaviors (claim-string presence, banned-phrase blocks, key/kind conformance) have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (conformance_test.exs)
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
