---
phase: 39-replay-operator-ux-draft-dataset-promotion
plan: 4
subsystem: ui
tags: [liveview, workflows, approvals, dataset-promotion, replay]
requires:
  - phase: 39-02
    provides: replay workflow comparison notebook and projection-backed operator surface
  - phase: 39-03
    provides: frozen workflow-source draft promotion snapshots for open datasets
provides:
  - workflow-owned sealed baseline promotion approvals with `dataset_baseline_promotion`
  - remote approval projection coverage for baseline lineage and replay evidence
  - promotion modal confirmation flow that keeps sealed baselines visible but immutable
affects: [phase-40-online-scoring, workflow-operator-ux, dataset-promotion]
tech-stack:
  added: []
  patterns: [workflow-owned approval wrappers, sealed-vs-open dataset modal lanes]
key-files:
  created: [.planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-04-SUMMARY.md]
  modified:
    - lib/scoria/workflows.ex
    - lib/scoria/workflows/dataset_promotion.ex
    - lib/scoria/workflows/remote_approval_projection.ex
    - lib/scoria_web/live/dataset_live/promote_component.ex
    - test/scoria/workflows_test.exs
    - test/scoria/workflows/dataset_promotion_test.exs
    - test/scoria/workflows/remote_approval_projection_test.exs
    - test/scoria_web/live/dataset_live/promote_component_test.exs
key-decisions:
  - "Baseline promotion requests keep the exact workflow tool identity `dataset_baseline_promotion` so inbox and lineage reads stay auditable."
  - "Sealed baseline targets remain visible in the modal, but the sealed path only proceeds through explicit confirmation and `Scoria.Workflows.request_baseline_promotion/1`."
patterns-established:
  - "Workflow-owned baseline promotion wrapper: sealed dataset promotion becomes a remote approval request instead of a dataset item mutation."
  - "Promotion modal dataset split: open targets stay directly selectable while sealed baselines render in a dedicated approval-required lane."
requirements-completed: [DATA-02]
duration: 6min
completed: 2026-05-23
---

# Phase 39 Plan 4: Replay Operator UX Draft Dataset Promotion Summary

**Sealed baseline promotions now persist as workflow approvals with replay-safe lineage while the promotion modal keeps baselines visible, immutable, and confirmation-gated**

## Performance

- **Duration:** 6 min
- **Started:** 2026-05-23T13:09:44Z
- **Completed:** 2026-05-23T13:15:44Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments
- Exposed a workflow-owned baseline promotion service through `Scoria.Workflows` and projected pending baseline approvals with explicit `tool_name`, target details, and replay lineage.
- Kept sealed baseline datasets visible in the promotion modal while separating them from open draft targets and requiring a dedicated `Baseline Promotion Approval` confirmation step.
- Verified the full `39-04` coverage lane across workflow, projection, and LiveComponent tests with `19` passing tests.

## Task Commits

The plan-owned implementation was already present in the working tree history because the phase plans were reshuffled after checker feedback:

1. **Task 1: Add workflow-owned baseline promotion wrappers and approval projection coverage** - `5579017` (feat)
2. **Task 2: Add sealed-baseline visibility, approval-required copy, and confirmation flow to the promotion modal** - `5579017` (feat)

**Plan metadata:** pending current execution commit

## Files Created/Modified
- `lib/scoria/workflows/dataset_promotion.ex` - workflow-owned approval wrapper for sealed baseline promotion requests.
- `lib/scoria/workflows.ex` - public workflow boundary helpers for requesting and inspecting baseline promotion approvals.
- `lib/scoria/workflows/remote_approval_projection.ex` - operator projection of baseline target details and replay lineage.
- `lib/scoria_web/live/dataset_live/promote_component.ex` - modal split between open draft targets and sealed baseline approval flow.
- `test/scoria/workflows_test.exs` - end-to-end workflow evidence coverage for baseline approval requests.
- `test/scoria/workflows/dataset_promotion_test.exs` - wrapper contract coverage for sealed-only requests.
- `test/scoria/workflows/remote_approval_projection_test.exs` - pending approval projection coverage for `dataset_baseline_promotion`.
- `test/scoria_web/live/dataset_live/promote_component_test.exs` - UI confirmation, immutability, and failure-state coverage for sealed baselines.
- `.planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-04-SUMMARY.md` - execution summary for this plan.

## Decisions Made
- Reused the existing workflow approval boundary instead of creating a dataset-specific mutation path for sealed baselines.
- Kept sealed targets operator-visible in the modal so baseline existence is never hidden even though direct mutation stays blocked.

## Deviations from Plan

### Execution Alignment

The code and test work for both `39-04` tasks had already landed in `5579017` under the earlier `39-03` label before `51bdba2` revised the phase plans. This execution therefore performed verification, summary creation, and normal GSD tracking closeout instead of producing new task-level code commits.

**Total deviations:** 1 execution alignment note
**Impact on plan:** No scope change and no missing functionality; verification confirmed the current tree satisfies `39-04`.

## Issues Encountered
None in the owned files. The verification run emitted unrelated existing compile warnings from connector and workflow UI modules outside this plan's ownership.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `39-04` leaves sealed-baseline approvals visible and durable for later review-queue work.
- Phase `39-05` can focus on replay promotion lineage/metadata regressions and runtime-driven end-to-end coverage without reopening the sealed-baseline approval design.

## Self-Check: PASSED

- Verified `.planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-04-SUMMARY.md` exists on disk.
- Verified historical implementation commits `5579017` and `cabde55` exist in git history.

---
*Phase: 39-replay-operator-ux-draft-dataset-promotion*
*Completed: 2026-05-23*
