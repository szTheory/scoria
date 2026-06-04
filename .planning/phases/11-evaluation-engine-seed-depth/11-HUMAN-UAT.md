---
status: partial
phase: 11-evaluation-engine-seed-depth
source: [11-VERIFICATION.md]
started: "2026-06-04"
updated: "2026-06-04"
---

## Current Test

[awaiting human testing]

## Tests

### 1. Overlay/drawer state capture (EVAL-01 modal-open states)
expected: `mix scoria.ui.shots` captures the connectors `connector_drawer` + `runtime_drawer` states and the `prompt_release` `approve_modal` state. In the Phase 11 baseline run these three were skipped — the harness's assumed `phx-click` selectors (`open_connector_drawer`, `open_runtime_drawer`, `open_approve`) did not match the rendered DOM, and no release link was found on `/prompts`. All 9 canonical `populated_dark_desktop.png` screens captured fine; only these overlay states are affected.
result: [pending]
fix-owner: Phase 12 (update harness selectors to match the shipped DOM, or add the missing affordances)

## Summary

total: 1
passed: 0
issues: 0
pending: 1
skipped: 0
blocked: 0

## Gaps
