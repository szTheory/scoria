---
phase: 53
slug: operator-evidence-and-lane-guidance
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-27
---

# Phase 53 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit bundled with Elixir 1.19.5 |
| **Config file** | `config/test.exs`; `test/test_helper.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/phoenix_example_source_test.exs test/scoria/handoff_example_source_test.exs` |
| **Full suite command** | `MIX_ENV=test mix test test/scoria/runtime_test.exs test/scoria/adoption_surface_test.exs test/scoria/phoenix_example_source_test.exs test/scoria/handoff_example_source_test.exs test/scoria_web/live/workflow_live_test.exs` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run the most targeted command from the per-task map.
- **After every plan wave:** Run `MIX_ENV=test mix test test/scoria/runtime_test.exs test/scoria/adoption_surface_test.exs test/scoria/phoenix_example_source_test.exs test/scoria/handoff_example_source_test.exs test/scoria_web/live/workflow_live_test.exs`
- **Before `$gsd-verify-work`:** Full phase command must be green.
- **Max feedback latency:** 90 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 53-01-01 | 01 | 1 | EVID-01 | T-53-01 | Curated readback stays on `Scoria.get_run_detail/1`; no raw workflow internals are exposed. | runtime + LiveView | `MIX_ENV=test mix test test/scoria/runtime_test.exs test/scoria_web/live/workflow_live_test.exs` | ✅ | ⬜ pending |
| 53-01-02 | 01 | 1 | EVID-01 | T-53-02 | Empty, pending, and completed delegated states remain visible and do not imply handoff is required for first adoption. | LiveView | `MIX_ENV=test mix test test/scoria_web/live/workflow_live_test.exs` | ✅ | ⬜ pending |
| 53-02-01 | 02 | 1 | DOCS-01 | T-53-03 | Public docs preserve default-lane-first wording and bounded handoff as optional same-run escalation. | docs invariant | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs` | ✅ | ⬜ pending |
| 53-02-02 | 02 | 1 | DOCS-01 | T-53-04 | Docs avoid placeholder Phase 54 proof commands and preserve the `v2.2` lane hierarchy. | docs invariant | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs` | ✅ | ⬜ pending |
| 53-03-01 | 03 | 1 | EVID-01, DOCS-01 | T-53-05 | Source/docs drift checks pin public API fragments and session/run ID wording without snapshot tooling. | source-fragment + docs invariant | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/phoenix_example_source_test.exs test/scoria/handoff_example_source_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements:

- [x] `test/scoria/adoption_surface_test.exs` — public docs invariant checks.
- [x] `test/scoria/phoenix_example_source_test.exs` — Phoenix example source-fragment checks.
- [x] `test/scoria/handoff_example_source_test.exs` — bounded handoff source-fragment checks.
- [x] `test/scoria/runtime_test.exs` — curated runtime readback behavior.
- [x] `test/scoria_web/live/workflow_live_test.exs` — operator evidence rendering and states.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all MISSING references.
- [x] No watch-mode flags.
- [x] Feedback latency < 90s.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-05-27
