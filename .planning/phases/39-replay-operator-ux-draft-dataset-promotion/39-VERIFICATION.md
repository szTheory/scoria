---
phase: 39-replay-operator-ux-draft-dataset-promotion
verified: 2026-05-23T12:51:44Z
status: gaps_found
score: 5/7 must-haves verified
overrides_applied: 0
gaps:
  - truth: "Operators can promote either original or replayed traces into draft dataset items backed by frozen evidence snapshots."
    status: partial
    reason: "The open-dataset promotion path works for original traces, but the actual replay promotion contract produced by the workflow page drops replay-specific metadata and misstates source checkpoint lineage before the dataset item is inserted."
    artifacts:
      - path: "lib/scoria/runtime/replay_comparison.ex"
        issue: "Replay provenance uses the replay checkpoint's id as `source_checkpoint_id` and does not include `replay_disposition` or `replay_reason_code` in the provenance group."
      - path: "lib/scoria_web/live/workflow_live/show.ex"
        issue: "Promotion context forwards the replay comparison entry as-is, so the incomplete provenance contract becomes the persisted input."
      - path: "lib/scoria/eval/dataset_promotion.ex"
        issue: "Frozen dataset metadata reads `replay_disposition` and `replay_reason_code` only from `provenance`, even though the runtime/UI contract stores those fields under `safety`."
    missing:
      - "Carry the true source checkpoint id from replay source metadata into the replay promotion contract."
      - "Persist replay disposition and replay reason code from the runtime-selected replay evidence."
      - "Add an end-to-end replay-promotion regression that starts from runtime comparison DTOs or workflow-page `promotion_context` and asserts the inserted dataset item metadata."
---

# Phase 39: Replay Operator UX & Draft Dataset Promotion Verification Report

**Phase Goal:** Operators can inspect replay provenance, compare outcomes, and promote reviewed traces into draft dataset items.
**Verified:** 2026-05-23T12:51:44Z
**Status:** gaps_found
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | LiveView shows source checkpoint, overrides, execution mode, and original-vs-replay context clearly. | ✓ VERIFIED | [lib/scoria_web/live/workflow_live/show.ex](/Users/jon/projects/scoria/lib/scoria_web/live/workflow_live/show.ex:75) loads `Runtime.get_run_detail!/1`, renders the replay provenance strip, and passes comparison DTOs into the right rail. Verified by `mix test test/scoria_web/live/workflow_live_test.exs`. |
| 2 | Operators can promote either original or replayed traces into draft dataset items backed by frozen evidence snapshots. | ✗ FAILED | Original promotions succeed, but replay promotions built from the actual workflow-page DTO lose replay metadata: [lib/scoria/runtime/replay_comparison.ex](/Users/jon/projects/scoria/lib/scoria/runtime/replay_comparison.ex:124) sets `source_checkpoint_id` from `checkpoint.id`; [lib/scoria_web/live/workflow_live/show.ex](/Users/jon/projects/scoria/lib/scoria_web/live/workflow_live/show.ex:321) forwards that provenance unchanged; [lib/scoria/eval/dataset_promotion.ex](/Users/jon/projects/scoria/lib/scoria/eval/dataset_promotion.ex:80) persists replay metadata only from `provenance`, not `safety`. |
| 3 | Sealed datasets remain immutable, and promotion into release-driving baselines requires explicit approval flow. | ✓ VERIFIED | [lib/scoria/workflows/dataset_promotion.ex](/Users/jon/projects/scoria/lib/scoria/workflows/dataset_promotion.ex:24) rejects open datasets and routes sealed targets through workflow approvals; [lib/scoria_web/live/dataset_live/promote_component.ex](/Users/jon/projects/scoria/lib/scoria_web/live/dataset_live/promote_component.ex:110) uses `request_baseline_approval` without inserting dataset items. Verified by `mix test test/scoria/workflows/dataset_promotion_test.exs test/scoria/workflows/remote_approval_projection_test.exs test/scoria_web/live/dataset_live/promote_component_test.exs`. |
| 4 | Replay runs expose original-versus-replay evidence from durable runtime reads instead of template-side struct inspection. | ✓ VERIFIED | [lib/scoria/runtime.ex](/Users/jon/projects/scoria/lib/scoria/runtime.ex:75) loads the run tree and source run, then builds `RunDetail` via [lib/scoria/runtime/replay_comparison.ex](/Users/jon/projects/scoria/lib/scoria/runtime/replay_comparison.ex:8). Verified by `mix test test/scoria/runtime_view_test.exs`. |
| 5 | A selected workflow step can be rendered from structured provenance, overrides, checkpoint/output, and safety groups. | ✓ VERIFIED | [lib/scoria_web/components/replay_evidence_notebook_component.ex](/Users/jon/projects/scoria/lib/scoria_web/components/replay_evidence_notebook_component.ex:35) renders grouped cards for `provenance`, `overrides`, `checkpoint_output`, `safety`, and `promotion_snapshot`. |
| 6 | Draft promotion can read one frozen source contract for either the original trace or replay trace. | ✗ FAILED | The original contract is coherent, but the replay contract is not. The workflow page emits replay provenance without replay disposition/reason and with `source_checkpoint_id` derived from the replay checkpoint rather than durable source lineage, so the frozen contract is incomplete for replay selections. |
| 7 | The right rail renders grouped comparison evidence and durable promotion feedback instead of raw `inspect/1` dumps. | ✓ VERIFIED | [lib/scoria_web/components/workflow_detail_panel_component.ex](/Users/jon/projects/scoria/lib/scoria_web/components/workflow_detail_panel_component.ex:12) keeps the shell/CTA while delegating grouped rendering to [lib/scoria_web/components/replay_evidence_notebook_component.ex](/Users/jon/projects/scoria/lib/scoria_web/components/replay_evidence_notebook_component.ex:8). Workflow notice rendering is present in [lib/scoria_web/live/workflow_live/show.ex](/Users/jon/projects/scoria/lib/scoria_web/live/workflow_live/show.ex:133). |

**Score:** 5/7 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/scoria/runtime.ex` | Runtime detail loader and source-run resolution | ✓ VERIFIED | Loads run tree, optional source run, and builds `RunDetail` with comparison DTOs. |
| `lib/scoria/runtime/run_detail.ex` | Curated runtime DTO | ✓ VERIFIED | Exposes step/checkpoint/event/approval maps plus `comparison_by_step` and `replay_provenance_strip`. |
| `lib/scoria/runtime/replay_comparison.ex` | Replay comparison builder | ⚠ HOLLOW | Exists and is wired, but replay provenance uses the wrong checkpoint field and omits replay metadata needed by downstream promotion persistence. |
| `lib/scoria_web/live/workflow_live/show.ex` | Workflow-page replay UX and promotion handoff | ⚠ HOLLOW | Runtime detail is loaded and rendered, but replay promotion_context forwards the incomplete provenance contract unchanged. |
| `lib/scoria_web/components/workflow_detail_panel_component.ex` | Detail shell and CTA | ✓ VERIFIED | Delegates grouped evidence rendering and disables promotion without a snapshot. |
| `lib/scoria_web/components/replay_evidence_notebook_component.ex` | Structured comparison notebook | ✓ VERIFIED | Renders grouped evidence and typed empty state. |
| `lib/scoria/eval.ex` | Public eval promotion boundary | ✓ VERIFIED | Exposes preview and promote wrappers over `DatasetPromotion`. |
| `lib/scoria/eval/dataset_promotion.ex` | Frozen workflow-source snapshot insert | ⚠ HOLLOW | Inserts immutable items, but replay metadata persistence depends on provenance fields that the real UI flow does not supply correctly. |
| `lib/scoria/workflows.ex` | Public workflow approval boundary | ✓ VERIFIED | Exposes baseline-promotion approval helpers and lineage reads. |
| `lib/scoria/workflows/dataset_promotion.ex` | Sealed-baseline approval service | ✓ VERIFIED | Uses workflow approval semantics and never mutates sealed datasets directly. |
| `lib/scoria/workflows/remote_approval_projection.ex` | Approval lineage projection | ✓ VERIFIED | Projects baseline target details and replay lineage for inbox/read models. |
| `lib/scoria_web/live/dataset_live/promote_component.ex` | Promotion modal behavior | ✓ VERIFIED | Splits open vs sealed targets, promotes open targets, and routes sealed targets through approval requests. |
| Phase 39 test files | Regression coverage | ⚠ PARTIAL | Tests pass, but replay dataset-promotion assertions use synthetic params instead of the runtime/LiveView replay contract that the page actually emits. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `lib/scoria/runtime.ex` | `lib/scoria/runtime/replay_comparison.ex` | `get_run_detail!/1` resolves source run tree and builds comparison data | ✓ WIRED | [lib/scoria/runtime.ex](/Users/jon/projects/scoria/lib/scoria/runtime.ex:75) calls `ReplayComparison.build/2` and `ReplayComparison.provenance_strip/1`. |
| `lib/scoria_web/live/workflow_live/show.ex` | `lib/scoria/runtime.ex` | Page reads runtime detail DTOs for the right rail | ✓ WIRED | [lib/scoria_web/live/workflow_live/show.ex](/Users/jon/projects/scoria/lib/scoria_web/live/workflow_live/show.ex:236) loads `Runtime.get_run_detail!/1`. |
| `lib/scoria_web/live/workflow_live/show.ex` | `lib/scoria_web/live/dataset_live/promote_component.ex` | `promotion_context` passes selected source variant and comparison entry into the modal | ✓ WIRED | [lib/scoria_web/live/workflow_live/show.ex](/Users/jon/projects/scoria/lib/scoria_web/live/workflow_live/show.ex:214) mounts the component with `promotion_context`. |
| `lib/scoria_web/components/workflow_detail_panel_component.ex` | `lib/scoria_web/components/replay_evidence_notebook_component.ex` | Detail panel delegates grouped notebook rendering | ✓ WIRED | Direct component delegation is present at [lib/scoria_web/components/workflow_detail_panel_component.ex](/Users/jon/projects/scoria/lib/scoria_web/components/workflow_detail_panel_component.ex:42). |
| `lib/scoria_web/live/dataset_live/promote_component.ex` | `lib/scoria/eval.ex` | Open dataset submit promotes the selected comparison source | ✓ WIRED | [lib/scoria_web/live/dataset_live/promote_component.ex](/Users/jon/projects/scoria/lib/scoria_web/live/dataset_live/promote_component.ex:65) calls `Eval.promote_workflow_source/1`. |
| `lib/scoria_web/live/dataset_live/promote_component.ex` | `lib/scoria/workflows/dataset_promotion.ex` | Sealed baseline action requests approval | ✓ WIRED | [lib/scoria_web/live/dataset_live/promote_component.ex](/Users/jon/projects/scoria/lib/scoria_web/live/dataset_live/promote_component.ex:110) calls `Workflows.request_baseline_promotion/1`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `lib/scoria/runtime.ex` | `comparison_by_step`, `replay_provenance_strip` | `Workflows.get_run_tree!/1` plus optional source run load | Yes | ✓ FLOWING |
| `lib/scoria_web/live/workflow_live/show.ex` | `selected_comparison_entry`, `promotion_context` | `detail.comparison_by_step` from runtime DTO | Yes, but replay provenance is incomplete | ⚠ HOLLOW |
| `lib/scoria/eval/dataset_promotion.ex` | Dataset item `metadata` | `promotion_context.provenance` / `promotion_snapshot` | Original path yes; replay path no | ⚠ HOLLOW |
| `lib/scoria/workflows/dataset_promotion.ex` | Approval request arguments | Modal `promotion_context` + sealed dataset lookup | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Runtime DTO exposes replay comparison data | `mix test test/scoria/runtime_view_test.exs` | `10 tests, 0 failures` | ✓ PASS |
| Workflow page renders replay provenance and comparison UX | `mix test test/scoria_web/live/workflow_live_test.exs` | `5 tests, 0 failures` | ✓ PASS |
| Open and sealed promotion paths execute | `mix test test/scoria/eval_test.exs test/scoria/workflows/dataset_promotion_test.exs test/scoria/workflows/remote_approval_projection_test.exs test/scoria_web/live/dataset_live/promote_component_test.exs` | `19 tests, 0 failures` | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `RPLY-03` | `39-01`, `39-02` | Operator can inspect replay provenance and compare replay output against the original run, including source checkpoint, overrides, and execution-mode evidence. | ✓ SATISFIED | Runtime DTO and LiveView evidence notebook are wired through [lib/scoria/runtime.ex](/Users/jon/projects/scoria/lib/scoria/runtime.ex:75), [lib/scoria/runtime/run_detail.ex](/Users/jon/projects/scoria/lib/scoria/runtime/run_detail.ex:35), and [lib/scoria_web/live/workflow_live/show.ex](/Users/jon/projects/scoria/lib/scoria_web/live/workflow_live/show.ex:75). |
| `DATA-01` | `39-03` | Operator can promote an original or replayed trace into a draft dataset item backed by a frozen evidence snapshot. | ✗ BLOCKED | Original promotions work, but replay promotions from the actual workflow-page contract drop replay-specific metadata before insertion; see [lib/scoria/runtime/replay_comparison.ex](/Users/jon/projects/scoria/lib/scoria/runtime/replay_comparison.ex:124), [lib/scoria_web/live/workflow_live/show.ex](/Users/jon/projects/scoria/lib/scoria_web/live/workflow_live/show.ex:321), and [lib/scoria/eval/dataset_promotion.ex](/Users/jon/projects/scoria/lib/scoria/eval/dataset_promotion.ex:80). |
| `DATA-02` | `39-03` | Sealed datasets remain immutable, and promotion into release-driving baseline datasets always requires explicit operator approval. | ✓ SATISFIED | The modal separates open/sealed targets and the sealed path routes into workflow approvals without dataset inserts; see [lib/scoria_web/live/dataset_live/promote_component.ex](/Users/jon/projects/scoria/lib/scoria_web/live/dataset_live/promote_component.ex:110) and [lib/scoria/workflows/dataset_promotion.ex](/Users/jon/projects/scoria/lib/scoria/workflows/dataset_promotion.ex:24). |

No orphaned Phase 39 requirement IDs were found in `.planning/REQUIREMENTS.md`.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `lib/scoria_web/live/workflow_live/show.ex` | 209 | References missing `ScoriaWeb.RemoteInvocationEvidenceComponent` | ℹ️ Info | Currently unreachable because [lib/scoria/sre.ex](/Users/jon/projects/scoria/lib/scoria/sre.ex:147) always returns `%{approvals: []}`, but the workflow page would warn or fail if that stub starts returning approvals before the component exists. |
| `test/scoria_web/live/dataset_live/promote_component_test.exs` | 209 | Replay promotion test uses synthetic `promotion_context` instead of runtime-produced DTO | ⚠️ Warning | Allows the replay-metadata persistence mismatch to pass tests. |

### Gaps Summary

Phase 39 mostly achieved the replay inspection and sealed-baseline approval goals. The workflow page, runtime DTOs, grouped comparison notebook, and baseline approval path are all present and exercised by tests.

The remaining gap is goal-critical: replay promotion is not verified from the real workflow-page data path, and the current code shows why. The replay comparison builder writes an incomplete provenance contract, the LiveView forwards that contract unchanged into `promotion_context`, and the dataset promotion service persists replay metadata only from that incomplete provenance map. That means the immutable dataset item created from a replay selection does not reliably preserve the replay provenance Phase 39 promised.

---

_Verified: 2026-05-23T12:51:44Z_
_Verifier: Claude (gsd-verifier)_
