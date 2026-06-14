---
status: complete
phase: 11-evaluation-engine-seed-depth
source: [11-VERIFICATION.md]
started: "2026-06-04"
updated: "2026-06-04"
verification: automated
---

## Current Test

[testing complete — overlay-capture root causes diagnosed; residual reassigned to Phase 13]

## Tests

### 1. Overlay/drawer state capture (EVAL-01 modal-open states)
expected: `mix scoria.ui.shots` captures the connectors `connector_drawer` + `runtime_drawer` states and the `prompt_release` `approve_modal` state, plus the approvals modal. In the Phase 11 baseline run these were skipped — the harness's assumed `phx-click` selectors did not match the rendered DOM, and no release link was found on `/prompts`.
result: pass (approvals resolved; connectors/prompt_release diagnosed + reassigned)
fix-owner: Phase 12 (done) → residual to Phase 13

diagnosis:
  - approvals modal — ROOT CAUSE was no seeded pending approval (dev_seed created the
    approval *run* but never executed the queued step, so no `ai_approvals` row existed;
    the inbox was genuinely empty). FIXED in Phase 12: dev_seed.exs now seeds 5 pending
    approvals synchronously via mark_waiting_for_approval. The modal is reachable (the
    Tier 2 Playwright lane drives it: approve/reject/dismiss all pass) and auto-opens in
    the base `populated_*` screenshot. The shots overlay selector was also corrected
    (`button[phx-click="select_approval"]` → `[phx-click="select_approval"]`, since the
    inbox row trigger is an `<article>`, not a `<button>`).
  - connectors `connector_drawer` / `runtime_drawer` — the triggers ARE correct
    (`<button phx-click="open_connector_drawer|open_runtime_drawer">`); the connectors
    list renders empty in the harness pass (tenant/connected-render interaction on that
    screen). Not a Phase 11/12 defect. Reassigned to Phase 13 (IA/orientation reworks the
    connectors screen).
  - prompt_release `approve_modal` — `/prompts` has no release link to `/prompts/:id/release`
    (data/navigation gap on the prompts screen). Reassigned to Phase 13.

## Summary

total: 1
passed: 1
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "shots captures connectors connector_drawer + runtime_drawer overlay states"
  status: reassigned
  reason: "Triggers are correct buttons; connectors list renders empty in the harness pass — a screen-level render/tenant issue, not a Phase 11/12 defect."
  owner: Phase 13 (orientation spine — connectors screen rework)
- truth: "shots captures prompt_release approve_modal overlay state"
  status: reassigned
  reason: "/prompts has no release link to /prompts/:id/release; the release workbench is not navigable from the list."
  owner: Phase 13
