---
phase: 51
slug: default-lane-verifier-hardening-and-support-truth-re-closeout
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-26
---

# Phase 51 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit on Elixir `1.19.5` |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/mix/tasks/test.adoption_test.exs --trace` |
| **Full suite command** | `MIX_ENV=dev mix scoria.release_preview && MIX_ENV=test mix test.adoption` |
| **Estimated runtime** | ~20 seconds |

---

## Sampling Rate

- **After every task commit:** Run the smallest seam-specific verifier first: `MIX_ENV=test mix test test/mix/tasks/test.adoption_test.exs --trace` for adoption-task boundary changes, `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs --trace` for docs drift-guard changes, or `MIX_ENV=test mix test test/mix/tasks/scoria.install_test.exs --trace` for installer wording changes
- **After every plan wave:** Run `MIX_ENV=test mix test test/scoria/host_app_consumer_proof_test.exs --trace` plus the focused source-truth/task tests for the touched seam
- **Before `$gsd-verify-work`:** `MIX_ENV=dev mix scoria.release_preview && MIX_ENV=test mix test.adoption` must be green
- **Max feedback latency:** 20 seconds for task-level smoke checks, 180 seconds for the phase gate

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 51-01-01 | 01 | 1 | DOCS-02 | T-51-01 | Generated-host proof keeps a scoped timeout and remains inside `mix test.adoption` | integration | `MIX_ENV=test mix test test/scoria/host_app_consumer_proof_test.exs --trace` | ✅ | ✅ green |
| 51-01-02 | 01 | 1 | DOCS-02 | T-51-01 | Host-proof runner reduces duplicate host-side `mix` startup without skipping public proof steps | integration | `MIX_ENV=test mix test test/scoria/host_app_consumer_proof_test.exs --trace` | ✅ | ✅ green |
| 51-02-01 | 02 | 2 | DOCS-01 | T-51-02 | README, installer output, and operator verification stay aligned on default-lane command truth | source + unit | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/mix/tasks/scoria.install_test.exs test/mix/tasks/test.adoption_test.exs --trace` | ✅ | ✅ green |
| 51-03-01 | 03 | 3 | DOCS-01, DOCS-02 | T-51-03 | `49-VERIFICATION.md` records the exact passing command chain and excludes non-canonical lanes | docs + integration | `MIX_ENV=dev mix scoria.release_preview && MIX_ENV=test mix test.adoption` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `.planning/phases/49-support-truth-and-adoption-closeout/49-VERIFICATION.md` — created from fresh command evidence during Phase 51 closeout

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Exact supported env for the repaired non-trace `mix test.adoption` rerun is captured in `49-VERIFICATION.md` | DOCS-02 | The repo currently has live PostgreSQL listeners on both `5432` and `55432`, so the artifact must record the env used for the passing proof rather than infer it from local state | Read `49-VERIFICATION.md` and confirm it names the exact command/env used for the green rerun and keeps semantic-lane env guidance scoped to `mix test.semantic_fast_path` |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 180s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-26 after fresh Phase 51 verification reruns
