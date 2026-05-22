---
phase: 26
plan: 03
subsystem: "UI"
tags: ["liveview", "prompt-release", "workbench", "approval"]
requires: ["26-01", "26-02"]
provides: ["ScoriaWeb.PromptLive.ReleaseWorkbenchLive"]
affects: ["ScoriaWeb.Router"]
tech-stack:
  added: []
  patterns: ["LiveView Async Evidence Loading", "Workflow Approvals & Audit Trails"]
key-files:
  created: ["lib/scoria_web/live/prompt_live/release_workbench_live.ex"]
  modified: ["lib/scoria_web/router.ex"]
decisions:
  - "Used a two-column LiveView layout to visually compare draft prompt template evaluation runs against the active version."
  - "Leveraged `assign_async` to lazily fetch heavy embedded EvalRuns and Workflow run histories."
  - "Disabled final approval CTA unless both draft and active versions have resolved and comparable evaluation evidence."
metrics:
  tasks: 2
  files: 3
---

# Phase 26 Plan 03: Release Workbench LiveView UI Summary

Built the embedded LiveView workbench for prompt comparison, allowing operators to review EvalRun metrics side-by-side and approve drafts.

## Work Completed
- Scaffolded `ScoriaWeb.PromptLive.ReleaseWorkbenchLive` and added a route for `/scoria/prompts/:id/release`.
- Implemented visual comparison of metrics (e.g. latency, cost, success rate) using async assignments.
- Built interactive approval rails connecting the UI to `Scoria.Workflows.PromptRelease.request_remote_approval/3` and `approve/3`.
- Handled state transitions, validation, and user feedback dynamically in the LiveView.

## Deviations from Plan
None - plan executed exactly as written.

## Self-Check: PASSED
- `lib/scoria_web/live/prompt_live/release_workbench_live.ex` exists and routes properly.
- All 11 `ReleaseWorkbenchLiveTest` cases passed with 0 failures, ensuring full end-to-end alignment.