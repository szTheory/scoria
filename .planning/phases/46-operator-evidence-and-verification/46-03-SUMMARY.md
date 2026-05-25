---
phase: 46-operator-evidence-and-verification
plan: 03
subsystem: workflow-ui
tags: [semantic-cache, operator-evidence, workflow, notebook]
requires:
  - phase: 46-01
    provides: shared semantic evidence DTO
  - phase: 46-02
    provides: runtime semantic summary surface
provides:
  - Canonical workflow semantic evidence notebook
  - Deep semantic inspection for hit and rejected candidates
affects: [workflow-live, workflow-detail-panel, operator-surfaces]
requirements-completed: [EVID-01]
completed: 2026-05-25
one_liner: Added the workflow semantic notebook so operators can inspect full semantic evidence on the run page.
---

# Plan 46-03 Summary

## Outcome

Made the workflow run page the canonical semantic evidence notebook by composing a dedicated semantic component beside the existing replay evidence rail.

## Changes

- added `ScoriaWeb.SemanticEvidenceNotebookComponent` with summary, compatibility, provenance, lifecycle, candidate, append-only events, and raw evidence disclosure sections
- updated `WorkflowDetailPanelComponent` to render the semantic notebook alongside existing replay evidence instead of replacing it
- passed `@run_detail.semantic_evidence` through `WorkflowLive.Show` into the right rail
- added notebook component tests plus workflow LiveView coverage for semantic hit and rejected-candidate cases

## Verification

- `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria_web/components/semantic_evidence_notebook_component_test.exs test/scoria_web/live/workflow_live_test.exs --trace`
