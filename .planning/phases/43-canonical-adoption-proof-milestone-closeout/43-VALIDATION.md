---
phase: 43
slug: canonical-adoption-proof-milestone-closeout
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-24
---

# Phase 43 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Ecto SQL Sandbox |
| **Config file** | `test/test_helper.exs`, `config/test.exs` |
| **Quick run command** | `mix test.adoption` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~90 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test.adoption`
- **After every plan wave:** Run `mix test.adoption`, plus any targeted `mix test ...` repro commands needed for broader-suite classification
- **Before `$gsd-verify-work`:** `mix test.adoption` must be green and `43-CLOSEOUT.md` must classify current `mix test` failures against the locked blocker triggers
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 43-01-01 | 01 | 1 | ADPT-02 | T-43-01 / T-43-02 | Canonical proof command remains limited to the runtime-first bounded adoption lane and excludes optional knowledge setup | integration + source guard | `mix test test/mix/tasks/test.adoption_test.exs test/scoria/adoption_surface_test.exs` | ✅ | ⬜ pending |
| 43-01-02 | 01 | 1 | ADPT-02 | T-43-03 | Runtime facade, operator evidence, and bounded-handoff lineage stay explicitly covered in the adoption lane | integration | `mix test test/scoria/adoption_surface_test.exs test/scoria/handoff_example_source_test.exs test/scoria/runtime_integration_test.exs test/scoria/runtime_test.exs test/mix/tasks/test.adoption_test.exs` | ✅ | ⬜ pending |
| 43-02-01 | 02 | 2 | ADPT-02 | T-43-04 / T-43-05 | Canonical closeout ledger records the proof command, dated result, and explicit blocker-trigger classification without transcript dumping | documentation + command classification | `sh -lc 'mix test.adoption && (mix test > /tmp/phase43-mix-test.log 2>&1 || true) && rg -n \"^## Closeout Decision$|^## Canonical Proof Lane$|^## Alignment Evidence$|^## Broader Suite Context$|^## Recommendation$\" .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CLOSEOUT.md'` | ❌ W0 | ⬜ pending |
| 43-02-02 | 02 | 2 | ADPT-02 | T-43-06 | Roadmap, requirements, and state all mirror the final closeout decision and completion state | documentation | `sh -lc 'rg -n \"^- \\[x\\] \\*\\*ADPT-02\\*\\*|^\\| ADPT-02 \\| Phase 43 \\| Complete \\|\" .planning/REQUIREMENTS.md && rg -n \"^- \\[x\\] \\*\\*Phase 43: Canonical Adoption Proof & Milestone Closeout\\*\\*|^\\| 43\\. Canonical Adoption Proof & Milestone Closeout \\| 2/2 \\| Complete\" .planning/ROADMAP.md && rg -n \"stopped_at: Phase 43 complete \\(2/2\\)|\\*\\*Phase:\\*\\* 43|\\*\\*Status:\\*\\* (Complete|Ready for milestone closeout)\" .planning/STATE.md'` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing infrastructure covers all phase requirements.
- [ ] `.planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CLOSEOUT.md` — created by Plan 43-02 before final closeout verification

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Broader `mix test` failure classification against the explicit blocker-trigger list | ADPT-02 | The command output can be automated, but deciding whether a failure touches compile stability, migrations, public runtime facade, bounded-handoff behavior, docs/source adoption fragments, or security/trust invariants requires maintainer judgment captured in the ledger | Run `mix test`, summarize failing files/tests in `43-CLOSEOUT.md`, and classify each failure against the D-14/D-15 trigger list from `43-CONTEXT.md` |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-24
