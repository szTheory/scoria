---
phase: 54
slug: executable-proof-and-closeout-truth
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-27
---

# Phase 54 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) |
| **Config file** | `mix.exs`, `test/test_helper.exs` |
| **Quick run command** | `MIX_ENV=test mix test.runtime_to_handoff` |
| **Full suite command** | `MIX_ENV=dev mix scoria.release_preview && MIX_ENV=test mix test.adoption && MIX_ENV=test mix test.runtime_to_handoff` |
| **Estimated runtime** | ~180 seconds |

---

## Sampling Rate

- **After every task commit:** Run `MIX_ENV=test mix test.runtime_to_handoff`
- **After every plan wave:** Run `MIX_ENV=test mix test.adoption && MIX_ENV=test mix test.runtime_to_handoff`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 54-01-01 | 01 | 1 | PROOF-01 | — | Runtime-to-handoff proof command executes bounded lane only | integration | `MIX_ENV=test mix test.runtime_to_handoff` | ✅ | ⬜ pending |
| 54-01-02 | 01 | 1 | PROOF-02 | — | Lane passes without semantic/knowledge/bootstrap prerequisites | integration | `MIX_ENV=test mix test.runtime_to_handoff` | ✅ | ⬜ pending |
| 54-02-01 | 02 | 2 | DOCS-02 | — | All support surfaces use one canonical command string | contract | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/phoenix_example_source_test.exs test/scoria/handoff_example_source_test.exs` | ✅ | ⬜ pending |
| 54-03-01 | 03 | 3 | PROOF-01, PROOF-02, DOCS-02 | — | Closeout chain evidence is recorded and reproducible | e2e | `MIX_ENV=dev mix scoria.release_preview && MIX_ENV=test mix test.adoption && MIX_ENV=test mix test.runtime_to_handoff` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/mix/tasks/test.runtime_to_handoff_test.exs` — command discoverability/contract test
- [ ] `lib/mix/tasks/scoria.test.runtime_to_handoff.ex` — bounded runtime-to-handoff lane task
- [ ] `lib/mix/tasks/test.runtime_to_handoff.ex` — canonical wrapper task

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| CI sequencing intent remains explicit and readable to operators | DOCS-02 | Requires human review of support language and command ordering rationale | Read `docs/operator_verification.md` and `.github/workflows/ci.yml`; confirm closeout chain order is identical and lane hierarchy wording matches README. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 180s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
