---
phase: 13-orientation-spine-ia
plan: "08"
subsystem: ui
tags: [phoenix-liveview, information-architecture, quality-loop]
requires:
  - phase: 13-orientation-spine-ia
    provides: Object-aware origin chips from plan 13-05
  - phase: 13-orientation-spine-ia
    provides: Incident and review ingress threading from plan 13-07
provides:
  - run egress links through replay, dataset promotion, incidents, and prompts
  - prompt release links into eval result and baseline-run evidence
  - dataset item source-run links from persisted promotion metadata
  - eval result links into prompt release and regressed workflow runs
affects: [workflow-show, release-workbench, dataset-promotion, eval-workbench]
tech-stack:
  added: []
  patterns:
    - flat next-step verb clusters
    - base-aware dashboard links using `assigns[:scoria_base]`
    - encoded `from={noun}:{id}` origin query propagation
key-files:
  created: []
  modified:
    - lib/scoria_web/live/workflow_live/show.ex
    - lib/scoria_web/live/prompt_live/release_workbench_live.ex
    - lib/scoria_web/live/dataset_live/promote_component.ex
    - lib/scoria_web/live/eval_spec_live/index.ex
    - test/scoria_web/live/workflow_live_test.exs
    - test/scoria_web/live/prompt_live/release_workbench_live_test.exs
    - test/scoria_web/live/dataset_live/promote_component_test.exs
    - test/scoria_web/live/eval_spec_live/index_test.exs
    - lib/mix/tasks/scoria.ui.e2e.ex
    - priv/dev/e2e/uat.spec.mjs
    - test/scoria_web/live/orchestrator_live_integration_test.exs
key-decisions:
  - "`Replay run` links to the honest Replay Playground stub with run origin context because no replay-launch route exists yet."
  - "`Open source run` is derived from persisted dataset item promotion metadata, preferring `source_run_id` and falling back to `workflow_run_id`."
  - "Eval result rows live on the existing Eval Workbench and link to prompt release and failing score workflow evidence when those persisted IDs exist."
patterns-established:
  - "Quality-loop threading remains contextual verb links, not a loop rail, stepper, wizard, or current-step state."
  - "Prompt and eval links with multiple query params should be asserted through parsed hrefs because rendered HTML escapes `&`."
requirements-completed: [IA-05]
duration: 13 min
completed: 2026-06-12
---

# Phase 13 Plan 08: Run And Prompt Egress Threading

**Run, dataset, eval, and prompt release pages now expose the remaining quality-loop verbs**

## Performance

- **Duration:** 13 min
- **Started:** 2026-06-12T14:35:10Z
- **Completed:** 2026-06-12T14:48:14Z
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments

- Added LiveView tests for the exact run verbs `Replay run`, `Promote span to dataset`, `Open incident`, and `Open prompt`.
- Added release workbench tests for `View eval results` and `View baseline runs`.
- Added dataset promotion component tests proving `Open source run` preserves `from=dataset:<item-id>`.
- Added eval workbench tests proving eval rows expose `Open prompt release`, `Open regressed runs`, and `from=eval:<eval-run-id>`.
- Added a run-page next-step cluster that reuses existing modal behavior for dataset promotion and only renders incident/prompt links when existing records support them.
- Added release workbench links back to eval result evidence for draft and active/baseline prompt runs.
- Added dataset source-run links from existing dataset item metadata.
- Added an Eval Workbench result table from recent `EvalRun` rows with score-evidence links to prompt release and failing workflow runs.
- Hardened the browser e2e lane so destructive approval-toast specs top up their own pending fixtures before Playwright starts.
- Removed a sandbox race from the orchestrator LiveView integration test by settling async mount work and flushing observe buffers before test teardown.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add object egress threading tests** - `582336a` (test)
2. **Task 2: Implement quality-loop egress links** - `d35b92b` (feat)
3. **Phase verification hardening** - `f80451b` (test)

## Files Created/Modified

- `test/scoria_web/live/workflow_live_test.exs` - Run next-step verb and origin-link assertions.
- `test/scoria_web/live/prompt_live/release_workbench_live_test.exs` - Release workbench eval/baseline href assertions.
- `test/scoria_web/live/dataset_live/promote_component_test.exs` - Dataset item source-run link assertions.
- `test/scoria_web/live/eval_spec_live/index_test.exs` - Eval result prompt-release and regressed-run assertions.
- `lib/scoria_web/live/workflow_live/show.ex` - Run next-step cluster plus linked incident/prompt discovery.
- `lib/scoria_web/live/prompt_live/release_workbench_live.ex` - Release workbench eval result links.
- `lib/scoria_web/live/dataset_live/promote_component.ex` - Dataset item source-run links.
- `lib/scoria_web/live/eval_spec_live/index.ex` - Recent eval result rows and quality-loop links.
- `lib/mix/tasks/scoria.ui.e2e.ex` - Repeatable e2e pending-approval fixture top-up.
- `priv/dev/e2e/uat.spec.mjs` - Updated e2e fixture contract notes.
- `test/scoria_web/live/orchestrator_live_integration_test.exs` - Deterministic buffer flush and reconnect synchronization.

## Decisions Made

- `Replay run` routes to `/coming/replay-playground?from=run:<id>` instead of pretending a replay launch exists.
- `Promote span to dataset` uses a distinct LiveView event name that forwards to the same modal state as the existing detail-panel promote button, avoiding duplicate test selectors while preserving behavior.
- Eval result `Open regressed runs` links to the first workflow run ID found in failed/regressed score evidence refs. Multi-run list filtering remains future work because no routed run-filter surface exists today.

## Deviations from Plan

- No DS-06 baseline change was needed; new affordances use existing `scoria-button` classes.
- The plan referenced `test/scoria_web/live/prompt_live_test.exs`; the local test file is `test/scoria_web/live/prompt_live/release_workbench_live_test.exs`, matching the existing codebase layout.

**Total deviations:** 2 implementation-shape corrections. **Impact:** no behavior loss; tests cover the intended contracts.

## Issues Encountered

- The first red test run exposed an invalid fixture: sealed datasets reject item inserts. The test now creates items while open and seals afterward.
- The first implementation used the same `open_promote_modal` selector as the existing detail-panel promote button. A dedicated forwarding event removed the selector collision.
- Prompt href assertions needed Floki parsing because rendered HTML escapes `&` as `&amp;`.
- Phase-level web verification exposed an existing sandbox race in `orchestrator_live_integration_test.exs`; the test now settles async mount work before disconnecting and flushes observe buffers before teardown.
- Re-running the browser lane against the same dev DB exposed consumed approval fixtures; `mix scoria.ui.e2e` now tops up pending approvals before Playwright starts, so local and CI reruns do not require manual reseeding.

## User Setup Required

None - no external service configuration required.

## Verification

- Red step: `mix test test/scoria_web/live/workflow_live_test.exs test/scoria_web/live/prompt_live/release_workbench_live_test.exs test/scoria_web/live/dataset_live/promote_component_test.exs test/scoria_web/live/eval_spec_live/index_test.exs --max-failures 1` - failed on missing `Eval results`.
- Focused pass: `mix test test/scoria_web/live/workflow_live_test.exs test/scoria_web/live/prompt_live/release_workbench_live_test.exs test/scoria_web/live/dataset_live/promote_component_test.exs test/scoria_web/live/eval_spec_live/index_test.exs test/scoria_web/ds06_drift_guard_test.exs --max-failures 1` - 33 tests, 0 failures.
- Determinism pass: `mix test test/scoria_web/live/orchestrator_live_integration_test.exs --seed 547352` - 4 tests, 0 failures.
- Syntax/compile: `node --check priv/dev/e2e/uat.spec.mjs` and `mix compile` - passed.
- Phase web pass: `mix test test/scoria_web/` - 164 tests, 0 failures.
- Browser e2e pass: `mix scoria.ui.e2e --base-url http://localhost:4001/scoria` - 8 passed, 3 skipped. Re-run passed after the task topped up consumed approval fixtures.

## Self-Check: PASSED

- Run pages render replay, promote, linked incident, and prompt next-step verbs when backed by existing data.
- Prompt release pages render eval and baseline-run links when eval evidence exists.
- Dataset rows render source-run links when item metadata contains workflow provenance.
- Eval result rows render prompt-release and regressed-run links when prompt/run context exists.
- Links preserve `from=run:`, `from=prompt:`, `from=dataset:`, or `from=eval:` context where applicable.
- No loop rail, numbered stepper, wizard, or current-step state was added.
- DS-06 raw palette baseline did not change.

## Next Phase Readiness

Phase 13 is complete and ready for Phase 14 planning.

---
*Phase: 13-orientation-spine-ia*
*Completed: 2026-06-12*
