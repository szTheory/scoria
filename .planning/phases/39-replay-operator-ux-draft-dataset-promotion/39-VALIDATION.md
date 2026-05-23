---
phase: 39
slug: replay-operator-ux-draft-dataset-promotion
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-23
---

# Phase 39 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/scoria/runtime_view_test.exs test/scoria_web/live/workflow_live_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~45 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test` for the task-local files called out in each plan.
- **After every plan wave:** Run `mix test`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 39-01-01 | 01 | 1 | RPLY-03 | T-39-01 | Replay provenance strip and comparison notebook render from durable DTO truth rather than raw metadata inspection. | LiveView | `mix test test/scoria/runtime_view_test.exs test/scoria_web/live/workflow_live_test.exs` | ✅ | ⬜ pending |
| 39-02-01 | 02 | 2 | DATA-01 | T-39-02 | Promotion uses a frozen workflow evidence snapshot for original or replay variants and records durable dataset-item metadata. | integration | `mix test test/scoria_web/live/dataset_live/promote_component_test.exs test/scoria/eval_test.exs` | ✅ | ⬜ pending |
| 39-03-01 | 03 | 3 | DATA-02 | T-39-03 | Sealed datasets remain immutable and baseline promotion must route through approval semantics instead of direct insertion. | workflow/integration | `mix test test/scoria/workflows_test.exs test/scoria/workflows/remote_approval_projection_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Replay notebook hierarchy stays operator-readable on desktop and mobile after structured evidence replaces raw `inspect/1` blocks. | RPLY-03 | The current test suite can prove presence and state transitions, but not full layout readability. | Open `/scoria/workflows/:id` with a replay run and confirm provenance strip, comparison toggle, and evidence cards stay legible at desktop and narrow widths. |
| Baseline lane copy clearly distinguishes direct draft promotion from approval-gated sealed baselines. | DATA-02 | Copy accuracy and operator comprehension are still visual/content checks. | Open the promotion surface with both open and sealed datasets present and confirm sealed rows are visible, disabled, and explicitly labeled as approval-required. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or existing coverage lanes
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-23
