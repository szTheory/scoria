---
phase: 07-seismograph
plan: 04
subsystem: sre
tags: [audit-outbox, incidents, workflows, mcp, ecto, telemetry]
requires:
  - phase: 07-02
    provides: budget reservations and enforcement seams used by MCP execution
  - phase: 07-03
    provides: breaker and telemetry plumbing extended by audit capture
  - phase: 07-07
    provides: durable audit and incident schemas consumed by this slice
provides:
  - transactional audit outbox writes at workflow approval and MCP execution seams
  - durable incident dedupe with page versus review routing
  - public SRE APIs for outbox creation and incident fan-in
affects: [07-05, 07-06, alert-relay, operator-review]
tech-stack:
  added: []
  patterns: [same-transaction audit evidence, redacted durable refs, stable incident keys]
key-files:
  created: [lib/scoria/workflows.ex, lib/scoria/sre/incident_manager.ex, test/scoria/sre/audit_outbox_test.exs, test/scoria/sre/incident_test.exs]
  modified: [lib/scoria/observe/approval.ex, lib/scoria/mcp/executor.ex, lib/scoria/sre.ex, lib/scoria/sre/audit_outbox_event.ex, lib/scoria/sre/budget_engine.ex, test/scoria/mcp/executor_test.exs]
key-decisions:
  - "Reused Scoria.Observe.Redactor at the outbox boundary so durable audit rows keep hashes and redacted refs instead of raw tool arguments."
  - "Inserted policy-sensitive invocation audit rows through the budget reservation transaction when a reservation exists, avoiding a crash window between reservation and evidence."
  - "Used low-cardinality incident keys of tenant, subject kind, policy key, reason code, and window bucket to dedupe alert storms while keeping append-only alert and incident event rows."
patterns-established:
  - "Workflow and MCP truth changes must create audit evidence before external fanout or side effects are treated as complete."
  - "Alert routing escalates fast-burn and breaker signals to page severity while slower regressions default to review severity."
requirements-completed: [SRE-04, SRE-05, SRE-06, SRE-08]
duration: 12min
completed: 2026-05-11
---

# Phase 7 Plan 04: Seismograph Summary

**Transactional audit-outbox capture for approvals and MCP execution, plus stable incident dedupe with routed review and paging severity**

## Performance

- **Duration:** 12 min
- **Started:** 2026-05-11T18:55:00Z
- **Completed:** 2026-05-11T19:07:09Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments
- Workflow approval requests and decisions now persist redacted `AuditOutboxEvent` rows inside the same transaction as the local truth change.
- Sensitive MCP access decisions and policy-sensitive tool invocations now create durable audit evidence before execution is treated as complete.
- Alerts now fan into stable incidents with preserved scorer and baseline evidence, deduped alert rows, and append-only incident events.

## Task Commits

1. **Task 1: Insert Audit Outbox Rows Transactionally** - `b77bdc0` (feat)
2. **Task 2: Build Incident Dedupe and Severity Routing** - `ff6bc45` (feat)

## Files Created/Modified
- `lib/scoria/workflows.ex` - writes approval-requested and approval-decision outbox rows inside workflow transactions
- `lib/scoria/observe/approval.ex` - allows `expired` approvals and optimistic locking on durable approval rows
- `lib/scoria/mcp/executor.ex` - captures sensitive MCP access and policy-sensitive invocation audit rows at the executor seam
- `lib/scoria/sre.ex` - exposes durable outbox helpers, incident APIs, redacted payload shaping, and post-commit telemetry emission
- `lib/scoria/sre/audit_outbox_event.ex` - names the tenant and dedupe unique index for rollback-safe changeset errors
- `lib/scoria/sre/budget_engine.ex` - carries audit envelopes into the reservation persistence seam
- `lib/scoria/sre/incident_manager.ex` - implements stable incident keys, dedupe, evidence retention, and severity routing
- `test/scoria/sre/audit_outbox_test.exs` - proves approval outbox durability, rollback safety, and redaction
- `test/scoria/mcp/executor_test.exs` - proves executor-seam audit persistence before completion and denial auditing without tool execution
- `test/scoria/sre/incident_test.exs` - proves incident evidence retention and repeated-alert dedupe

## Decisions Made
- Kept audit telemetry emission outside the transaction boundary so observers only see committed outbox rows.
- Let `lib/scoria/sre.ex` span both task slices because it is the public context boundary for both outbox and incident APIs; task history is split by commit, not by artificially rewriting a working shared seam.
- Bootstrapped the outbox and incident tables inside the focused tests because the workspace test migration path is currently blocked by a missing `pgvector` extension in an unrelated migration.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added test-local table bootstrap for audit and incident persistence**
- **Found during:** Task 1 and Task 2 verification
- **Issue:** `MIX_ENV=test mix ecto.migrate` could not complete because the unrelated knowledge migration requires the PostgreSQL `pgvector` extension, which is not installed in this workspace.
- **Fix:** Added focused `CREATE TABLE IF NOT EXISTS` setup helpers in the new audit and incident tests so the plan could be verified without changing unrelated migration work.
- **Files modified:** `test/scoria/sre/audit_outbox_test.exs`, `test/scoria/mcp/executor_test.exs`, `test/scoria/sre/incident_test.exs`
- **Verification:** `MIX_ENV=test mix test test/scoria/sre/audit_outbox_test.exs test/scoria/mcp/executor_test.exs test/scoria/sre/incident_test.exs`
- **Committed in:** `b77bdc0`, `ff6bc45`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Verification remained scoped and complete. No product-surface scope creep; the deviation only compensates for an unrelated local migration blocker.

## Issues Encountered
- `lib/scoria/sre.ex` is the shared public context boundary for both plan tasks, so the task split could not be made perfectly file-exclusive without rewriting a working seam. The shared boundary stayed in Task 1, and Task 2 landed the new incident manager plus dedicated routing coverage.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- The relay and adapter plans can now consume durable audit evidence instead of transient execution state.
- Operator notification work can route from stable incidents with preserved evidence and explicit review versus page semantics.
- Remaining local blocker outside this plan: install `pgvector` or gate the unrelated knowledge migration before relying on full `mix ecto.migrate` in fresh environments.

## Self-Check: PASSED

---
*Phase: 07-seismograph*
*Completed: 2026-05-11*
