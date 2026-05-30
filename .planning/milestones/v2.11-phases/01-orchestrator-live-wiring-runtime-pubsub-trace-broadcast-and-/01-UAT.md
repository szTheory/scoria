---
status: complete
phase: 01-orchestrator-live-wiring-runtime-pubsub-trace-broadcast-and-
source: [01-01-SUMMARY.md, 01-02-SUMMARY.md, 01-03-SUMMARY.md]
started: 2026-05-30T12:00:00Z
updated: 2026-05-30T14:00:00Z
---

## Current Test

none — automated coverage complete

## Tests

### 1. Cold Start Smoke Test
expected: Start support_copilot from scratch (DB up, migrations applied). Navigate to /scoria orchestrator dashboard. Page loads without errors; trace panel and approval inbox render.
result: passed
automation: examples/support_copilot/test/support_copilot_web/orchestrator_smoke_test.exs (`GET /scoria orchestrator dashboard mounts with session contract`); CI advisory lane `mix scoria.test.support_copilot`

### 2. Live Trace Stream
expected: Trigger a workflow run from the orchestrator. Completed spans appear incrementally in the trace tree without page refresh.
result: passed
automation: test/scoria_web/live/orchestrator_live_integration_test.exs (`live trace appears in orchestrator without send/2`); CI merge gate `mix test.semantic_fast_path --warnings-as-errors`

### 3. Trace DB Hydrate on Reconnect
expected: After at least one trace exists, refresh or reconnect LiveView. Recent traces reappear from database hydrate.
result: passed
automation: test/scoria_web/live/orchestrator_live_integration_test.exs (`reconnect hydrates traces from DB after missed PubSub`, `reconnect hydrates redacted span attributes from DB`); CI merge gate semantic lane

### 4. HITL Approval Modal Opens
expected: When a workflow pauses for human approval, a blocking overlay modal opens showing tool name, reason, and connector badge when applicable.
result: passed
automation: test/scoria_web/live/orchestrator_live_integration_test.exs (`real approval surfaces blocking modal without send/2`, `reconnect shows modal from DB pending approval`); CI merge gate semantic lane

### 5. Redacted Approval Arguments
expected: Modal and inbox rows show redacted arguments preview only — no raw secrets in the DOM.
result: passed
automation: test/scoria_web/live/orchestrator_live_integration_test.exs (integration tests refute `super-secret-key` in DOM); test/scoria/observe/trace_projection_test.exs; CI merge gate semantic lane

### 6. Approve Workflow from Modal
expected: Click Approve in the modal. Approval succeeds, modal closes, and the workflow run advances past waiting_for_approval.
result: passed
automation: test/scoria_web/live/orchestrator_live_integration_test.exs (`approve decision clears modal via producer path` asserts approval approved and run status completed); CI merge gate semantic lane

### 7. Reject Workflow from Modal
expected: Click Reject. Rejection is recorded, modal closes, workflow remains paused with durable-rejection copy.
result: passed
automation: test/scoria_web/live/orchestrator_live_integration_test.exs (`reject decision clears modal and keeps run paused`); CI merge gate semantic lane

### 8. Dismiss Approval (Decide Later)
expected: Click "Decide later". Modal closes without approving or rejecting; approval remains pending in inbox.
result: passed
automation: test/scoria_web/live/orchestrator_live_integration_test.exs (`dismiss closes modal without approving via producer path`); CI merge gate semantic lane

### 9. Stale Approval Flash
expected: Attempt to approve an already-decided approval shows friendly flash about another operator deciding.
result: passed
automation: test/scoria_web/live/orchestrator_live_integration_test.exs (`stale approval decision surfaces friendly flash via producer path`); CI merge gate semantic lane

### 10. Inbox Highlight for Non-Focused Approval
expected: Approval for a session outside current focus highlights inbox row instead of replacing the active modal.
result: passed
automation: test/scoria_web/live/orchestrator_live_integration_test.exs (`non-focused approval highlights inbox without replacing modal via producer path`); CI merge gate semantic lane

### 11. LLM Token Preview on Span Row
expected: During LLM span activity, coalesced token preview appears inline on the active LLM span row — not in a global token strip.
result: passed
automation: test/scoria_web/live/orchestrator_live_integration_test.exs (`token delta coalesces into span preview via producer path`); CI merge gate semantic lane

## Summary

total: 11
passed: 11
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

none — automated coverage complete
