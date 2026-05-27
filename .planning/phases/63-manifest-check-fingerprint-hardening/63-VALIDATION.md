---
phase: 63
slug: manifest-check-fingerprint-hardening
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-27
---

# Phase 63 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix) |
| **Config file** | `mix.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/scoria/install/ test/mix/tasks/scoria.install_check_test.exs` |
| **Full suite command** | `MIX_ENV=test mix test test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.install_check_test.exs test/scoria/install/mode_equivalence_test.exs test/scoria/adoption_surface_test.exs` |
| **Estimated runtime** | ~30–90 seconds |

---

## Sampling Rate

- **After every task commit:** Run task `<automated>` verify command
- **After every plan wave:** Run quick run command
- **Before `/gsd-verify-work`:** Full suite command must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 63-01-01 | 01 | 1 | INST-07 | — | Planner does not merge manifest into live fingerprint | unit | `rg 'put_new\(:fingerprint, manifest_entry' lib/scoria/install/planner.ex; test $? -ne 0` | ✅ | ✅ green |
| 63-01-02 | 01 | 1 | INST-07 | — | manifest_state on plan entries/plan root | unit | `MIX_ENV=test mix test test/scoria/install/mode_equivalence_test.exs` | ✅ | ✅ green |
| 63-01-03 | 01 | 1 | INST-07 | — | Maintainer moduledocs on Manifest/Planner | grep | `rg '@moduledoc' lib/scoria/install/manifest.ex lib/scoria/install/planner.ex` | ✅ | ✅ green |
| 63-02-01 | 02 | 1 | INST-07 | — | JSON manifest metadata additive | unit | `MIX_ENV=test mix test test/scoria/install/report_test.exs` | ✅ | ✅ green |
| 63-02-02 | 02 | 1 | INST-07 | — | Human manifest line in render_human | unit | `rg 'manifest' lib/scoria/install/report.ex` (report tests cover render) | ✅ | ✅ green |
| 63-02-03 | 02 | 1 | INST-07 | — | mix help documents apply freshness | cli | `mix help scoria.install \| rg 'Apply freshness\|freshness'` | ✅ | ✅ green |
| 63-03-01 | 03 | 2 | INST-07 | — | Tampered manifest does not change check exit | integration | `MIX_ENV=test mix test test/mix/tasks/scoria.install_check_test.exs` | ✅ | ✅ green |
| 63-03-02 | 03 | 2 | INST-07 | — | Absent manifest compliant host exit 0 | integration | `MIX_ENV=test mix test test/mix/tasks/scoria.install_check_test.exs` (manifest absent case in same file) | ✅ | ✅ green |
| 63-03-03 | 03 | 2 | INST-07 | — | Operator doc pins | unit | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs` | ✅ | ✅ green |
| 63-03-04 | 03 | 2 | INST-07 | — | Stale apply gate unchanged | integration | `MIX_ENV=test mix test test/mix/tasks/scoria.install_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/support/scoria/host_install_fixtures.ex` — subprocess host fixtures
- [x] `test/scoria/install/mode_equivalence_test.exs` — dry-run/check parity + manifest_state
- [x] `test/scoria/install/report_test.exs` — report projection tests
- [x] `test/mix/tasks/scoria.install_check_test.exs` — tri-state + manifest tamper cases

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | — | — | — |

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-27 (Phase 65 Nyquist closeout — reconciled from 63-VERIFICATION.md)

## Validation Audit 2026-05-27
| Metric | Count |
|--------|-------|
| Gaps found | 10 stale pending rows + 2 false-positive W0 markers |
| Resolved | 10 + 2 (reconciled to 63-VERIFICATION.md; 63-01-02 command aligned to mode_equivalence_test) |
| Escalated | 0 |
| Source artifact | `.planning/phases/63-manifest-check-fingerprint-hardening/63-VERIFICATION.md` |
