---
phase: 39-replay-operator-ux-draft-dataset-promotion
verified: 2026-05-23T13:42:17Z
status: human_needed
score: 7/7 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: 7/7
  gaps_closed: []
  gaps_remaining: []
  regressions: []
human_verification:
  - test: "Inspect the replay workflow page with a real replay run and switch between Original trace and Replay trace."
    expected: "The provenance strip, segmented toggle, grouped notebook cards, CTA helper copy, and inline notices remain clear and correctly reflect the selected source variant."
    why_human: "Visual hierarchy, copy clarity, and operator comprehension are UI qualities not fully verifiable from code or ExUnit assertions."
  - test: "Complete the promote modal flow manually for one open draft dataset and one sealed baseline dataset."
    expected: "Open-target promotion closes with the success notice and preserved replay metadata; sealed-target flow shows the confirmation copy and records an approval request without inserting a dataset item."
    why_human: "End-to-end operator flow and confirmation semantics require manual validation of the rendered LiveView behavior."
---

# Phase 39: Replay Operator UX & Draft Dataset Promotion Verification Report

**Phase Goal:** Operators can inspect replay provenance, compare outcomes, and promote reviewed traces into draft dataset items.
**Verified:** 2026-05-23T13:42:17Z
**Status:** human_needed
**Re-verification:** Yes - current tree re-check after post-review fixes

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | LiveView shows source checkpoint, overrides, execution mode, and original-vs-replay context clearly. | ✓ VERIFIED | [show.ex](/Users/jon/projects/scoria/lib/scoria_web/live/workflow_live/show.ex:34) keeps source selection in LiveView state, [show.ex](/Users/jon/projects/scoria/lib/scoria_web/live/workflow_live/show.ex:102) renders the replay provenance strip, and [workflow_live_test.exs](/Users/jon/projects/scoria/test/scoria_web/live/workflow_live_test.exs:150) exercises the replay strip, source toggle, and durable notices. |
| 2 | Operators can promote either original or replayed traces into draft dataset items backed by frozen evidence snapshots. | ✓ VERIFIED | [replay_comparison.ex](/Users/jon/projects/scoria/lib/scoria/runtime/replay_comparison.ex:122) and [replay_comparison.ex](/Users/jon/projects/scoria/lib/scoria/runtime/replay_comparison.ex:265) carry durable replay lineage plus replay metadata; [dataset_promotion.ex](/Users/jon/projects/scoria/lib/scoria/eval/dataset_promotion.ex:80) persists `source_checkpoint_id`, `replay_disposition`, and `replay_reason_code`; [eval_test.exs](/Users/jon/projects/scoria/test/scoria/eval_test.exs:132) and [promote_component_test.exs](/Users/jon/projects/scoria/test/scoria_web/live/dataset_live/promote_component_test.exs:172) assert runtime-driven replay promotions preserve that metadata. |
| 3 | Sealed datasets remain immutable, and promotion into release-driving baselines requires explicit approval flow. | ✓ VERIFIED | [workflows/dataset_promotion.ex](/Users/jon/projects/scoria/lib/scoria/workflows/dataset_promotion.ex:24) routes sealed targets through workflow approvals, [promote_component.ex](/Users/jon/projects/scoria/lib/scoria_web/live/dataset_live/promote_component.ex:103) uses the confirmation-only baseline path, and [remote_approval_projection_test.exs](/Users/jon/projects/scoria/test/scoria/workflows/remote_approval_projection_test.exs:122) proves pending baseline approvals surface through the projection boundary. |
| 4 | Replay runs expose original-versus-replay evidence from durable runtime reads instead of template-side struct inspection. | ✓ VERIFIED | [runtime.ex](/Users/jon/projects/scoria/lib/scoria/runtime.ex:75) builds `RunDetail` through runtime loaders, and [runtime_view_test.exs](/Users/jon/projects/scoria/test/scoria/runtime_view_test.exs:398) verifies the comparison DTO reads the latest persisted replay evidence. |
| 5 | A selected workflow step can be rendered from structured provenance, overrides, checkpoint/output, and safety groups. | ✓ VERIFIED | [replay_evidence_notebook_component.ex](/Users/jon/projects/scoria/lib/scoria_web/components/replay_evidence_notebook_component.ex:35) renders the grouped cards, while [show.ex](/Users/jon/projects/scoria/lib/scoria_web/live/workflow_live/show.ex:285) forwards the selected entry into the detail panel and modal state. |
| 6 | Draft promotion can read one frozen source contract for either the original trace or replay trace. | ✓ VERIFIED | [show.ex](/Users/jon/projects/scoria/lib/scoria_web/live/workflow_live/show.ex:321) forwards the selected runtime groups intact and now seeds blank notes with `""` at [show.ex](/Users/jon/projects/scoria/lib/scoria_web/live/workflow_live/show.ex:344); [workflow_live_test.exs](/Users/jon/projects/scoria/test/scoria_web/live/workflow_live_test.exs:265) confirms the opened modal no longer receives `%{}` placeholder notes. |
| 7 | The right rail renders grouped comparison evidence and durable promotion feedback instead of raw `inspect/1` dumps. | ✓ VERIFIED | [workflow_detail_panel_component.ex](/Users/jon/projects/scoria/lib/scoria_web/components/workflow_detail_panel_component.ex:42) delegates to the structured replay notebook, [show.ex](/Users/jon/projects/scoria/lib/scoria_web/live/workflow_live/show.ex:61) and [show.ex](/Users/jon/projects/scoria/lib/scoria_web/live/workflow_live/show.ex:69) accept durable promotion notices, and [workflow_live_test.exs](/Users/jon/projects/scoria/test/scoria_web/live/workflow_live_test.exs:253) asserts both notice paths render. |

**Score:** 7/7 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/scoria/runtime/replay_comparison.ex` | Replay comparison contract with corrected lineage and latest-evidence selection | ✓ VERIFIED | Uses the latest checkpoint/event/approval per step and resolves replay source lineage from durable source refs. |
| `lib/scoria/runtime/run_detail.ex` | Curated runtime DTO | ✓ VERIFIED | Still exposes `comparison_by_step` and `replay_provenance_strip` for the workflow page. |
| `lib/scoria/runtime.ex` | Runtime detail loader and source-run resolution | ✓ VERIFIED | Loads run trees and delegates replay comparison building behind the runtime boundary. |
| `lib/scoria_web/live/workflow_live/show.ex` | Workflow-page replay UX and promotion handoff | ✓ VERIFIED | Keeps selected source state, forwards the selected runtime contract intact, and seeds blank notes correctly. |
| `lib/scoria_web/components/workflow_detail_panel_component.ex` | Detail shell and CTA | ✓ VERIFIED | Preserves the shell and delegates the comparison body to the notebook component. |
| `lib/scoria_web/components/replay_evidence_notebook_component.ex` | Structured comparison notebook | ✓ VERIFIED | Renders grouped evidence cards with typed empty states and source-toggle copy. |
| `lib/scoria_web/components/remote_invocation_evidence_component.ex` | Concrete remote-evidence component for the workflow page branch | ✓ VERIFIED | New component now exists and is wired from the workflow page, closing the missing-module review issue. |
| `lib/scoria/eval.ex` | Public eval promotion boundary | ✓ VERIFIED | Exposes `preview_workflow_source_promotion/1` and `promote_workflow_source/1`. |
| `lib/scoria/eval/dataset_promotion.ex` | Frozen workflow-source snapshot insert | ✓ VERIFIED | Persists replay metadata from `safety` first, with provenance fallback. |
| `lib/scoria/workflows.ex` | Public workflow approval boundary | ✓ VERIFIED | Guards cross-run approval requests before mutating run or step state. |
| `lib/scoria/workflows/dataset_promotion.ex` | Sealed-baseline approval service | ✓ VERIFIED | Rejects open targets and reuses workflow approvals for sealed baselines. |
| `lib/scoria/workflows/remote_approval_projection.ex` | Approval lineage projection | ✓ VERIFIED | Projects baseline approval lineage and replay fields for operator inspection. |
| `lib/scoria_web/live/dataset_live/promote_component.ex` | Promotion modal behavior | ✓ VERIFIED | Splits open vs sealed targets, preserves operator input, and sends success or approval notices upstream. |
| Phase 39 test files | Regression coverage | ✓ VERIFIED | Current runtime, workflow, eval, projection, LiveView, and component tests cover the fixed post-review paths. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `lib/scoria/runtime.ex` | `lib/scoria/runtime/replay_comparison.ex` | `get_run_detail!/1` resolves source run tree and builds comparison data | ✓ WIRED | [runtime.ex](/Users/jon/projects/scoria/lib/scoria/runtime.ex:75) calls `ReplayComparison.build/2` and `ReplayComparison.provenance_strip/1`. |
| `lib/scoria/runtime/replay_comparison.ex` | `lib/scoria_web/live/workflow_live/show.ex` | Selected comparison entry becomes workflow-page `promotion_context` | ✓ WIRED | [replay_comparison.ex](/Users/jon/projects/scoria/lib/scoria/runtime/replay_comparison.ex:122) emits the persisted replay fields that [show.ex](/Users/jon/projects/scoria/lib/scoria_web/live/workflow_live/show.ex:321) forwards intact. |
| `lib/scoria_web/live/workflow_live/show.ex` | `lib/scoria_web/live/dataset_live/promote_component.ex` | `promotion_context` passes selected source variant and grouped runtime evidence into the modal | ✓ WIRED | [show.ex](/Users/jon/projects/scoria/lib/scoria_web/live/workflow_live/show.ex:285) assigns `promotion_context`, and [show.ex](/Users/jon/projects/scoria/lib/scoria_web/live/workflow_live/show.ex:214) mounts the component with it. |
| `lib/scoria_web/live/dataset_live/promote_component.ex` | `lib/scoria/eval/dataset_promotion.ex` | Open dataset submit promotes the selected workflow source | ✓ WIRED | [promote_component.ex](/Users/jon/projects/scoria/lib/scoria_web/live/dataset_live/promote_component.ex:71) submits to `Eval.promote_workflow_source/1`. |
| `lib/scoria_web/live/dataset_live/promote_component.ex` | `lib/scoria/workflows/dataset_promotion.ex` | Sealed baseline action requests approval | ✓ WIRED | [promote_component.ex](/Users/jon/projects/scoria/lib/scoria_web/live/dataset_live/promote_component.ex:119) submits to `Workflows.request_baseline_promotion/1`. |
| `lib/scoria/workflows.ex` | workflow approval persistence | Cross-run guard prevents approval corruption before mutations | ✓ WIRED | [workflows.ex](/Users/jon/projects/scoria/lib/scoria/workflows.ex:318) validates `step.run_id == run.id`; [workflows_test.exs](/Users/jon/projects/scoria/test/scoria/workflows_test.exs:243) and [dataset_promotion_test.exs](/Users/jon/projects/scoria/test/scoria/workflows/dataset_promotion_test.exs:84) cover both public entry points. |
| `lib/scoria_web/live/workflow_live/show.ex` | `lib/scoria_web/components/remote_invocation_evidence_component.ex` | Workflow page renders remote invocation evidence section when approvals exist | ✓ WIRED | [show.ex](/Users/jon/projects/scoria/lib/scoria_web/live/workflow_live/show.ex:209) now targets the concrete component at [remote_invocation_evidence_component.ex](/Users/jon/projects/scoria/lib/scoria_web/components/remote_invocation_evidence_component.ex:1). |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `lib/scoria/runtime/replay_comparison.ex` | `comparison_by_step.*.replay.provenance` | Replay run tree plus durable checkpoint/event/approval source refs | Yes | ✓ FLOWING |
| `lib/scoria_web/live/workflow_live/show.ex` | `promotion_context` | `detail.comparison_by_step` selected entry | Yes | ✓ FLOWING |
| `lib/scoria/eval/dataset_promotion.ex` | Dataset item `metadata` | `promotion_context.provenance`, `safety`, and `promotion_snapshot` | Yes | ✓ FLOWING |
| `lib/scoria/workflows/dataset_promotion.ex` | Approval request arguments | Modal `promotion_context` plus sealed dataset lookup | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Runtime DTO uses latest durable replay evidence and preserves replay lineage | `mix test test/scoria/runtime_view_test.exs` | `12 tests, 0 failures` | ✓ PASS |
| Workflow approval boundary rejects cross-run IDs instead of corrupting unrelated runs | `mix test test/scoria/workflows_test.exs test/scoria/workflows/dataset_promotion_test.exs` | `15 tests, 0 failures` | ✓ PASS |
| Workflow page renders replay provenance, source toggle, durable notices, and blank modal notes | `mix test test/scoria_web/live/workflow_live_test.exs` | `6 tests, 0 failures` | ✓ PASS |
| Replay promotion metadata persists end to end and sealed approvals project correctly | `mix test test/scoria/eval_test.exs test/scoria_web/live/dataset_live/promote_component_test.exs test/scoria/workflows/remote_approval_projection_test.exs` | `18 tests, 0 failures` | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `RPLY-03` | `39-01`, `39-02`, `39-05` | Operator can inspect replay provenance and compare replay output against the original run, including source checkpoint, overrides, and execution-mode evidence. | ✓ SATISFIED | [show.ex](/Users/jon/projects/scoria/lib/scoria_web/live/workflow_live/show.ex:102), [replay_comparison.ex](/Users/jon/projects/scoria/lib/scoria/runtime/replay_comparison.ex:101), and [workflow_live_test.exs](/Users/jon/projects/scoria/test/scoria_web/live/workflow_live_test.exs:150) show the runtime-driven comparison surface is wired and tested. |
| `DATA-01` | `39-03`, `39-05` | Operator can promote an original or replayed trace into a draft dataset item backed by a frozen evidence snapshot. | ✓ SATISFIED | [dataset_promotion.ex](/Users/jon/projects/scoria/lib/scoria/eval/dataset_promotion.ex:80), [eval_test.exs](/Users/jon/projects/scoria/test/scoria/eval_test.exs:132), and [promote_component_test.exs](/Users/jon/projects/scoria/test/scoria_web/live/dataset_live/promote_component_test.exs:172) prove replay metadata and frozen evidence survive the real runtime/UI contract. |
| `DATA-02` | `39-04` | Sealed datasets remain immutable, and promotion into release-driving baseline datasets always requires explicit operator approval. | ✓ SATISFIED | [promote_component.ex](/Users/jon/projects/scoria/lib/scoria_web/live/dataset_live/promote_component.ex:103), [workflows/dataset_promotion.ex](/Users/jon/projects/scoria/lib/scoria/workflows/dataset_promotion.ex:24), and [remote_approval_projection_test.exs](/Users/jon/projects/scoria/test/scoria/workflows/remote_approval_projection_test.exs:122) confirm the immutable approval-only lane. |

All Phase 39 requirement IDs declared in plan frontmatter are accounted for in `.planning/REQUIREMENTS.md`. No orphaned Phase 39 requirement IDs were found.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `lib/scoria_web/live/workflow_live/show.ex` | 17 | `assign_async/3` background query can outlive the LiveView test owner and log sandbox disconnect noise | ⚠️ Warning | The scoped LiveView test passes, but teardown still emits owner-exited DB noise after `mix test test/scoria_web/live/workflow_live_test.exs`. |
| `test/scoria_web/live/workflow_live_test.exs` | 113 | Only the empty remote-evidence branch is covered; no positive render test for non-empty approval evidence | ℹ️ Info | The missing-module regression is fixed by the new component, but a future rendering regression in the approval-present branch would not be caught by current Phase 39 tests. |

### Human Verification Required

### 1. Replay Comparison UX

**Test:** Open a real replay run at `/scoria/workflows/:id`, switch between `Original trace` and `Replay trace`, and inspect the right rail.
**Expected:** The provenance strip, grouped evidence cards, and CTA helper copy all stay aligned with the selected source variant and remain understandable without reading raw JSON.
**Why human:** Visual hierarchy, readability, and operator comprehension are not fully captured by code structure or text assertions.

### 2. Promotion Modal Flow

**Test:** Use the promote modal once with an open draft dataset and once with a sealed baseline dataset.
**Expected:** The open-target path finishes with the success notice and preserved replay metadata; the sealed-target path shows the confirmation copy and records an approval request without inserting a dataset item.
**Why human:** This is a rendered operator flow with confirmation semantics and interaction quality that automated tests only approximate.

### Gaps Summary

The post-review code fixes are present and working in the current tree. The approval boundary now rejects cross-run IDs before any workflow mutation, replay comparison reads the latest durable checkpoint/event/approval evidence for a step, the workflow page opens promotion with blank notes instead of `%{}`, and the missing remote-evidence module now exists and is wired into the page.

Status remains `human_needed` because the remaining checks are UX-only: replay comparison clarity and the rendered promote/approval flow still require manual validation with a real replay run and live datasets.

---

_Verified: 2026-05-23T13:42:17Z_
_Verifier: Claude (gsd-verifier)_
