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
| **Quick run command** | `mix test test/scoria/runtime_view_test.exs test/scoria/eval_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~24 seconds |

---

## Sampling Rate

- **After every task commit:** Run the task-local smoke command in that task's `<verify>` block.
- **After every plan wave:** Run `mix test`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Target task-local latency:** under 30 seconds
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 39-01-01 | 01 | 1 | RPLY-03 | T-39-01 | Replay provenance strip and comparison notebook render from durable DTO truth rather than raw metadata inspection. | runtime smoke | `mix test test/scoria/runtime_view_test.exs` | ✅ | ⬜ pending |
| 39-02-01 | 02 | 2 | RPLY-03 | T-39-02 | Workflow page renders replay provenance and grouped comparison evidence from runtime DTOs. | LiveView smoke | `mix test test/scoria_web/live/workflow_live_test.exs` | ✅ | ⬜ pending |
| 39-03-01 | 03 | 3 | DATA-01 | T-39-09 | Open-draft promotion inserts one immutable dataset item snapshot for the selected source variant. | eval smoke | `mix test test/scoria/eval_test.exs` | ✅ | ⬜ pending |
| 39-03-02 | 03 | 3 | DATA-01 | T-39-10 | Promotion modal preserves the flat workflow-source contract and fails safely if a draft target seals before submit. | component smoke | `mix test test/scoria_web/live/dataset_live/promote_component_test.exs` | ✅ | ⬜ pending |
| 39-04-01 | 04 | 4 | DATA-02 | T-39-11 | Sealed baseline requests persist as workflow approvals with inspectable lineage and no dataset-item insert. | workflow smoke | `mix test test/scoria/workflows/dataset_promotion_test.exs test/scoria/workflows/remote_approval_projection_test.exs` | ✅ | ⬜ pending |
| 39-04-02 | 04 | 4 | DATA-02 | T-39-17 | Modal shows approval-required sealed baselines and requires explicit confirmation before sending a baseline request. | LiveComponent smoke | `mix test test/scoria_web/live/dataset_live/promote_component_test.exs` | ✅ | ⬜ pending |
| 39-05-01 | 05 | 5 | RPLY-03, DATA-01 | T-39-13 | Replay promotion contract carries the correct source checkpoint lineage plus replay metadata. | runtime smoke | `mix test test/scoria/runtime_view_test.exs` | ✅ | ⬜ pending |
| 39-05-02 | 05 | 5 | DATA-01 | T-39-15 | Replay dataset-item persistence uses the runtime/LiveView contract instead of synthetic params. | eval smoke | `mix test test/scoria/eval_test.exs` | ✅ | ⬜ pending |

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
- [x] Task-local smoke lanes target < 30s
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-23
