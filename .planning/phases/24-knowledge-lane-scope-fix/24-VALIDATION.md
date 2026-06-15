---
phase: 24
slug: knowledge-lane-scope-fix
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-15
---

# Phase 24 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (stdlib, Elixir 1.19.5) |
| **Config file** | `test/test_helper.exs` (existing) |
| **Quick run command** | `mix test test/scoria/knowledge_lane_contract_test.exs` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Knowledge lane command** | `mix test.knowledge --warnings-as-errors` |
| **Estimated runtime** | Quick: <5s · Knowledge lane: scoped (post-fix) · Full: minutes |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/scoria/knowledge_lane_contract_test.exs`
- **After every plan wave:** Run `mix test.knowledge --warnings-as-errors` (proves the scoped lane) + the SC#4 contract tests
- **Before `/gsd:verify-work`:** `mix test test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs` green AND scoped knowledge lane green
- **Max feedback latency:** <10 seconds for the contract-test loop

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 24-01-* | 01 | 1 | KNOW-01 | — | N/A | contract | `mix test test/scoria/knowledge_lane_contract_test.exs` | ❌ W0 (deliverable) | ⬜ pending |
| 24-01-* | 01 | 1 | KNOW-01 | — | N/A | runtime guard | `SCORIA_TEST_INCLUDE_KNOWLEDGE=true mix test.knowledge` | ❌ W0 (deliverable) | ⬜ pending |
| 24-01-* | 01 | 1 | KNOW-01 | — | N/A | contract | `mix test test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Success Criteria → Test Map

| SC# | Behavior | Test Type | Automated Command | File Exists? |
|-----|----------|-----------|-------------------|-------------|
| SC#1 | Knowledge lane runs only the 6 knowledge-tagged files | log-inspection | `mix test.knowledge --warnings-as-errors` (line/file count drops vs full-suite re-run) | N/A (CI log) |
| SC#1 (proxy) | `knowledge_test_files/0` returns exactly 6 files | contract | `mix test test/scoria/knowledge_lane_contract_test.exs` | No — deliverable |
| SC#2 | CI YAML contract string `mix test.knowledge --warnings-as-errors` unchanged; filter injected inside the mix task, never in YAML | contract | `mix test test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs` | Yes |
| SC#3 | Every knowledge-tagged test still runs (no silent exclusion); 5-of-6 partial loss is caught | contract + runtime guard | `mix test test/scoria/knowledge_lane_contract_test.exs` + `after_suite total > 0` | No — deliverable |
| SC#4 | `ci_policy_contract_test` + `verification_lanes_test` green | contract | `mix test test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs` | Yes |

---

## Wave 0 Requirements

- [ ] `test/scoria/knowledge_lane_contract_test.exs` — covers SC#1 proxy + SC#3 (D-03 deliverable, not a pre-existing gap)
- [ ] Layer-2 `after_suite` guard in `test/test_helper.exs` — covers SC#3 runtime guard (D-02 deliverable)

*The "gaps" for this phase ARE the deliverables — there is no pre-existing test infrastructure to augment; we create it.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Knowledge lane wall-clock reclaims ~22 min in real CI | KNOW-01 | Requires a real CI run; local timing is not representative | Inspect the `knowledge` lane duration + log file/line count in a post-merge CI run vs the pre-fix baseline |

*SC#1's exact-file proxy and SC#3's guard are automated; only the real-CI wall-clock reclaim is observed manually.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
