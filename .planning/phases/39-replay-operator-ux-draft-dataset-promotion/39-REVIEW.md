---
phase: 39-replay-operator-ux-draft-dataset-promotion
reviewed: 2026-05-23T12:52:08Z
depth: standard
files_reviewed: 21
files_reviewed_list:
  - lib/scoria/runtime.ex
  - lib/scoria/runtime/run_detail.ex
  - lib/scoria/runtime/replay_comparison.ex
  - lib/scoria_web/live/workflow_live/show.ex
  - lib/scoria_web/components/workflow_detail_panel_component.ex
  - lib/scoria_web/components/replay_evidence_notebook_component.ex
  - lib/scoria_web/live/dataset_live/promote_component.ex
  - lib/scoria/eval.ex
  - lib/scoria/eval/dataset_promotion.ex
  - lib/scoria/eval/eval_spec.ex
  - lib/scoria/workflows.ex
  - lib/scoria/workflows/dataset_promotion.ex
  - lib/scoria/workflows/remote_approval_projection.ex
  - test/scoria/runtime_view_test.exs
  - test/scoria/runtime_test.exs
  - test/scoria_web/live/workflow_live_test.exs
  - test/scoria/eval_test.exs
  - test/scoria/workflows_test.exs
  - test/scoria/workflows/dataset_promotion_test.exs
  - test/scoria/workflows/remote_approval_projection_test.exs
  - test/scoria_web/live/dataset_live/promote_component_test.exs
findings:
  critical: 0
  warning: 2
  info: 0
  total: 2
status: issues_found
---

# Phase 39: Code Review Report

**Reviewed:** 2026-05-23T12:52:08Z
**Depth:** standard
**Files Reviewed:** 21
**Status:** issues_found

## Summary

Reviewed the executed Phase 39 runtime, LiveView, dataset-promotion, and approval-projection changes plus the new regression tests. The scoped test suite passes, but two contract regressions remain: the workflow page can hand the promotion modal an invalid `notes` type that crashes on open, and replay promotion metadata drops or misstates provenance fields when the data comes from the actual runtime DTO path instead of hand-built test fixtures.

Verification run:

- `mix test test/scoria/runtime_test.exs test/scoria/runtime_view_test.exs test/scoria_web/live/workflow_live_test.exs test/scoria/eval_test.exs test/scoria/workflows_test.exs test/scoria/workflows/dataset_promotion_test.exs test/scoria/workflows/remote_approval_projection_test.exs test/scoria_web/live/dataset_live/promote_component_test.exs`

## Warnings

### WR-01: Workflow Promotion Modal Crashes On Real Phase 39 Context

**File:** `lib/scoria_web/live/workflow_live/show.ex:329-331`, `lib/scoria_web/live/dataset_live/promote_component.ex:340-346`, `lib/scoria_web/live/dataset_live/promote_component.ex:397-399`
**Issue:** `build_promotion_context/1` seeds `notes` as `%{}`, but the modal initializer treats `notes` as a string and calls `to_string/1`. `to_string(%{})` raises `Protocol.UndefinedError`, so opening the Phase 39 promotion modal from the workflow page will fail before render. The component tests miss this because their helper builds `notes: ""` instead of exercising the real `WorkflowLive.Show` payload shape.
**Fix:**
```elixir
# lib/scoria_web/live/workflow_live/show.ex
defp build_promotion_context(selected_entry) do
  %{
    workflow_run_id: get_in(selected_entry, [:provenance, :workflow_run_id]),
    workflow_step_id: get_in(selected_entry, [:provenance, :workflow_step_id]),
    source_variant: get_in(selected_entry, [:provenance, :source_variant]),
    provenance: Map.get(selected_entry, :provenance, %{}),
    checkpoint_output: Map.get(selected_entry, :checkpoint_output, %{}),
    safety: Map.get(selected_entry, :safety, %{}),
    promotion_snapshot: Map.get(selected_entry, :promotion_snapshot, %{}),
    notes: "",
    expected_output: %{}
  }
end
```
Add a LiveView test that clicks `open_promote_modal` from `/scoria/workflows/:id` and asserts the modal renders.

### WR-02: Replay Promotion Metadata Loses Durable Lineage

**File:** `lib/scoria/runtime/replay_comparison.ex:124-133`, `lib/scoria/eval/dataset_promotion.ex:80-95`
**Issue:** The replay-side provenance map uses the replay checkpoint id (`checkpoint.id`) as `source_checkpoint_id`, and it never carries `replay_disposition` at all. `DatasetPromotion.build_metadata/1` then reads `replay_disposition` and `replay_reason_code` from `provenance`, so real promotions from `WorkflowLive.Show.build_promotion_context/1` will persist incorrect or nil replay lineage even though the runtime DTO already has that information in `safety` and checkpoint metadata. Current tests miss this because they construct promotion params manually with the desired provenance fields instead of round-tripping the runtime DTO into the eval boundary.
**Fix:**
```elixir
# lib/scoria/runtime/replay_comparison.ex
defp provenance_group(run, step, checkpoint, source_variant) do
  %{
    workflow_run_id: run.id,
    workflow_step_id: step.id,
    source_variant: source_variant,
    source_run_id: run.source_run_id,
    source_checkpoint_id:
      map_value(checkpoint && checkpoint.metadata, "source_checkpoint_id") ||
        run.source_checkpoint_id,
    execution_mode: run.execution_mode
  }
end

# lib/scoria/eval/dataset_promotion.ex
defp build_metadata(attrs) do
  provenance = normalize_map(attrs["provenance"])
  safety = normalize_map(attrs["safety"])

  %{
    "replay_disposition" => safety["replay_disposition"],
    "replay_reason_code" => safety["replay_reason_code"],
    ...
  }
end
```
Add an integration-style test that takes `Runtime.get_run_detail!/1` output for a replay run, feeds its selected comparison entry through the same promotion-context shaping used by `WorkflowLive.Show`, and asserts the persisted dataset item keeps the original `source_checkpoint_id`, `replay_disposition`, and `replay_reason_code`.

---

_Reviewed: 2026-05-23T12:52:08Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
