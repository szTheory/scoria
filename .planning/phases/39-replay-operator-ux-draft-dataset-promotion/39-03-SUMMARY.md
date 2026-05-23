---
phase: 39-replay-operator-ux-draft-dataset-promotion
plan: 3
subsystem: ui
tags: [phoenix, liveview, ecto, approvals, datasets, replay]
requires:
  - phase: 39-01
    provides: replay comparison provenance and source lineage for operator surfaces
  - phase: 39-02
    provides: flat promotion context contract from the workflow detail panel
provides:
  - frozen workflow-source dataset promotion at the eval boundary
  - sealed baseline approval requests through the workflow boundary
  - promotion modal split between open draft targets and sealed baselines
affects: [workflow-detail, dataset-promotion, approval-lineage]
tech-stack:
  added: []
  patterns: [ecto-multi snapshot promotion, workflow-owned sealed baseline approvals, flat promotion_context live component contract]
key-files:
  created: [lib/scoria/eval/dataset_promotion.ex, lib/scoria/workflows/dataset_promotion.ex, test/scoria/workflows/dataset_promotion_test.exs, .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-03-SUMMARY.md]
  modified: [lib/scoria/eval.ex, lib/scoria/eval/eval_spec.ex, lib/scoria/workflows.ex, lib/scoria/workflows/remote_approval_projection.ex, lib/scoria_web/live/dataset_live/promote_component.ex, test/scoria/eval_test.exs, test/scoria/workflows_test.exs, test/scoria/workflows/remote_approval_projection_test.exs, test/scoria_web/live/dataset_live/promote_component_test.exs]
key-decisions:
  - "Open dataset promotions call `Scoria.Eval.promote_workflow_source/1`, while sealed baselines always route to `Scoria.Workflows.request_baseline_promotion/1`."
  - "Baseline approval lineage uses the exact `dataset_baseline_promotion` tool identity so existing workflow projections and audit seams can expose replay provenance."
patterns-established:
  - "Promotion snapshot pattern: freeze workflow evidence into dataset-item input and metadata in one transaction."
  - "Immutable baseline pattern: sealed datasets stay visible in UI but switch to explicit approval confirmation instead of direct mutation."
requirements-completed: [DATA-01, DATA-02]
duration: 12m
completed: 2026-05-23
---

# Phase 39 Plan 3: Replay Operator UX Draft Dataset Promotion Summary

**Frozen original/replay evidence promotion for open datasets plus workflow-owned approval routing for sealed baselines**

## Performance

- **Duration:** 12m
- **Started:** 2026-05-23T12:33:56Z
- **Completed:** 2026-05-23T12:45:38Z
- **Tasks:** 2
- **Files modified:** 12

## Accomplishments

- Added a frozen workflow-source promotion service that inserts one immutable dataset item snapshot with workflow and replay provenance preserved.
- Split dataset promotion UX into open draft targets versus sealed baselines, with a dedicated baseline approval confirmation mode.
- Exposed sealed baseline promotion requests and lineage through the standard workflow approval boundary using `dataset_baseline_promotion`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Build frozen workflow-source draft promotion at the eval boundary** - `0ef1790` (test), `3d67cb3` (feat)
2. **Task 2: Show open versus sealed targets and route baseline requests through workflow approvals** - `5579017` (feat)

**Plan metadata:** pending final docs commit

## Files Created/Modified

- `lib/scoria/eval/dataset_promotion.ex` - Builds preview and immutable insert attrs for workflow-source dataset promotion.
- `lib/scoria/eval.ex` - Exposes `preview_workflow_source_promotion/1` and `promote_workflow_source/1`.
- `lib/scoria/eval/eval_spec.ex` - Aligned eval spec typing with the active test contract so the promotion lane could run.
- `lib/scoria/workflows/dataset_promotion.ex` - Wraps sealed baseline promotion requests in workflow approval semantics.
- `lib/scoria/workflows.ex` - Exposes baseline promotion and approval inspection helpers.
- `lib/scoria/workflows/remote_approval_projection.ex` - Projects baseline approval lineage and target dataset details.
- `lib/scoria_web/live/dataset_live/promote_component.ex` - Splits open/sealed targets, adds confirmation UX, preserves form state on failure.
- `test/scoria/eval_test.exs` - Covers original, replay, and sealed-dataset promotion behavior.
- `test/scoria/workflows/dataset_promotion_test.exs` - Covers the baseline approval wrapper and replay-safe approval payloads.
- `test/scoria/workflows_test.exs` - Verifies workflow boundary persistence for baseline promotion approvals.
- `test/scoria/workflows/remote_approval_projection_test.exs` - Verifies baseline approval projection and lineage visibility.
- `test/scoria_web/live/dataset_live/promote_component_test.exs` - Covers open promotion, sealed baseline approval requests, and seal-during-submit recovery.

## Decisions Made

- Open dataset promotions and sealed baseline promotions now use different boundaries on purpose: eval owns immutable item inserts, workflows owns approval truth.
- The UI keeps sealed baselines visible instead of hiding them, so operators can see release targets while still being forced through explicit approval semantics.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Aligned stale eval spec contract before promotion verification**
- **Found during:** Task 1 (Build frozen workflow-source draft promotion at the eval boundary)
- **Issue:** The eval promotion test lane was blocked by a stale `EvalSpec` schema/test contract mismatch unrelated to the new service API.
- **Fix:** Updated `lib/scoria/eval/eval_spec.ex` to match the active persisted/tested contract so `mix test test/scoria/eval_test.exs` could verify the promotion slice.
- **Files modified:** `lib/scoria/eval/eval_spec.ex`
- **Verification:** `mix test test/scoria/eval_test.exs`
- **Committed in:** `3d67cb3` (part of Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The fix was required to verify the planned dataset-promotion behavior. No scope expansion beyond the blocked test lane.

## Issues Encountered

- LiveComponent event tests needed to target component-scoped buttons rather than the parent live view; the test harness was updated accordingly.
- The seal-during-submit regression needed escaped-HTML assertions for preserved JSON text in the rendered form state.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Replay and original evidence can now be promoted into open datasets with frozen provenance, while sealed baselines require durable approval requests.
- Approval lineage for baseline promotion is available through existing workflow projections, so later operator inbox and release surfaces can reuse the same tool identity and evidence shape.

## Self-Check: PASSED

- Found `.planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-03-SUMMARY.md`
- Verified task commits `0ef1790`, `3d67cb3`, and `5579017` exist in git history
