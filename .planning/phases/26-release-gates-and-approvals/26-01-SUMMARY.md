---
phase: 26
plan: 01
subsystem: "Runtime"
tags: ["release-gate", "middleware", "prompt-lifecycle"]
requires: []
provides: ["Scoria.Runtime.ReleaseGate"]
affects: ["Scoria.Runtime"]
tech-stack:
  added: []
  patterns: ["Runtime Guarding"]
key-files:
  created: ["lib/scoria/runtime/release_gate.ex"]
  modified: ["lib/scoria/runtime.ex"]
decisions:
  - "Implemented `ReleaseGate` to intercept runtime calls and enforce safety against draft prompts being served to production traffic."
  - "Used Ecto `PromptTemplate` pattern matching for direct checking and runtime metadata map parsing for nested `prompt_ref` cases."
metrics:
  tasks: 1
  files: 3
---

# Phase 26 Plan 01: Release Gate Middleware Summary

Implemented a human-in-the-loop release gate before a draft prompt template is promoted to active.

## Work Completed
- Created `Scoria.Runtime.ReleaseGate` middleware to check if an invoked prompt is currently in a `draft` status.
- Wired `ReleaseGate.check/1` into `Scoria.Runtime.start_run/2`.
- Added tests in `test/scoria/runtime/release_gate_test.exs` ensuring that production traffic falls back properly or returns `:unapproved_draft`.

## Deviations from Plan
None - plan executed exactly as written.

## Self-Check: PASSED
- `lib/scoria/runtime/release_gate.ex` correctly implements the expected functionality.
- Tests pass.