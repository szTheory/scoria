---
phase: 82
slug: docs-truth-milestone-closeout
status: active
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-29
---

# Phase 82 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` test alias |
| **Quick run command** | `MIX_ENV=test mix test --warnings-as-errors test/scoria/hex_consumer_contract_test.exs test/scoria/adoption_surface_test.exs test/scoria/ci_policy_contract_test.exs` |
| **Full suite command** | `MIX_ENV=test mix test --warnings-as-errors test/scoria/hex_consumer_contract_test.exs test/scoria/adoption_surface_test.exs test/scoria/ci_policy_contract_test.exs test/scoria/support_journey_source_test.exs test/scoria/verification_lanes_test.exs` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick run command
- **After every plan wave:** Run full suite command
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 82-01-01 | 01 | 1 | DOCS-HEX-01 | — | adopter_doc_surfaces/0 API | unit | `mix test test/scoria/hex_consumer_contract_test.exs` | ✅ | ✅ green |
| 82-01-02 | 01 | 1 | DOCS-HEX-01 | — | Adopter doc fragment pins | contract | `mix test test/scoria/adoption_surface_test.exs` | ✅ | ✅ green |
| 82-01-03 | 01 | 1 | DOCS-HEX-01 | — | Maintainer gate map pins | contract | `mix test test/scoria/ci_policy_contract_test.exs` | ✅ | ✅ green |
| 82-02-01 | 02 | 2 | DOCS-HEX-01 | — | Phase verification doc | doc | Manual review `82-VERIFICATION.md` | ✅ | ✅ green |
| 82-02-02 | 02 | 2 | DOCS-HEX-01 | — | Milestone audit passed | doc | Manual review `v2.10-MILESTONE-AUDIT.md` | ✅ | ✅ green |
| 82-03-01 | 03 | 3 | DOCS-HEX-01 | — | Milestone archive complete | doc | `/gsd-complete-milestone v2.10` preflight | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No new test framework needed.

- [x] `test/scoria/hex_consumer_contract_test.exs` — dep snippet guard
- [x] `test/scoria/adoption_surface_test.exs` — extend for hex consumer pins
- [x] `test/scoria/ci_policy_contract_test.exs` — extend for gate map pins
- [x] `test/scoria/support_journey_source_test.exs` — macro pattern reference

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Milestone audit sign-off | DOCS-HEX-01 | Planning artifact review | Confirm `v2.10-MILESTONE-AUDIT.md` frontmatter `status: passed` |
| Milestone archive | DOCS-HEX-01 | GSD ceremony | Run `/gsd-complete-milestone v2.10`; verify phase dirs in `v2.10-phases/` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
