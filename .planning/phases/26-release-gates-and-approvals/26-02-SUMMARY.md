---
phase: 26
plan: 02
subsystem: "Workflows"
tags: ["prompt-release", "approval", "workflow"]
requires: ["26-01"]
provides: ["Scoria.Workflows.PromptRelease"]
affects: ["Scoria.Repo"]
tech-stack:
  added: []
  patterns: ["Workflow Approvals & Audit Trails"]
key-files:
  created: ["lib/scoria/workflows/prompt_release.ex"]
  modified: []
decisions:
  - "Wrapped approval mutation in a transaction to ensure strong consistency with audit outbox events."
  - "Used `Scoria.Workflows.mark_waiting_for_approval/3` to manage the lifecycle of prompt release requests."
metrics:
  tasks: 1
  files: 2
---

# Phase 26 Plan 02: Prompt Release Workflow Summary

Implemented the event-driven workflow for prompt release approvals using `Scoria.Workflows.PromptRelease`.

## Work Completed
- Created `Scoria.Workflows.PromptRelease`.
- Implemented `request_remote_approval/3` to generate a run step that pauses and waits for manual approval.
- Implemented `approve/3` to record the operator's decision (`approved`, `rejected`) and emit durable `AuditOutboxEvent` markers within a transaction.
- Added test coverage in `test/scoria/workflows/prompt_release_test.exs`.

## Deviations from Plan
None - plan executed exactly as written.

## Self-Check: PASSED
- `lib/scoria/workflows/prompt_release.ex` correctly creates approvals and logs audit events.
- Tests pass.