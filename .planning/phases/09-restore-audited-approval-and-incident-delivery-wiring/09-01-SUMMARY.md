---
phase: 09-restore-audited-approval-and-incident-delivery-wiring
plan: 01
subsystem: workflows
tags: [workflows, approvals, audit, liveview, sre]
requires: []
provides:
  - "Workflow-owned approval decisions from the operator LiveView"
  - "Durable approval decision audit lineage with actor, tenant, and trace attribution"
  - "Focused runtime and LiveView coverage for approval resume and expiration behavior"
affects: [workflows, liveview, sre]
tech-stack:
  added: []
  patterns:
    - "Approval UI delegates decisions to `Scoria.Workflows.approve/3` and resumes only through `Scoria.Workflows.Resume.resume_run/1`."
    - "Approval decision audit rows inherit request lineage when callers omit trace or actor fields."
key-files:
  created: []
  modified:
    - lib/scoria/workflows.ex
    - lib/scoria_web/live/orchestrator_live.ex
    - test/scoria/sre/audit_outbox_test.exs
    - test/scoria/workflows/integration_test.exs
    - test/scoria/workflows/runtime_test.exs
    - test/scoria_web/live/orchestrator_live_test.exs
key-decisions:
  - "Reject decisions keep runs paused; only approved decisions trigger workflow-owned resume."
  - "Decision audit rows fall back to the prior `approval.requested` event for tenant, actor, and trace lineage when needed."
patterns-established:
  - "Use the prior `approval.requested` outbox row as the durable attribution source for later approval decisions."
requirements-completed: [SRE-05]
duration: 1h
completed: 2026-05-12
---

# Phase 9 Plan 01 Summary

**The operator approval flow now mutates approval truth only through `Scoria.Workflows.approve/3`, writes durable decision lineage with attributable audit context, and resumes paused runs only through workflow-owned resume logic.**

## Accomplishments
- Replaced direct `Repo.update/2` approval mutations in `ScoriaWeb.OrchestratorLive` with workflow-owned approve and reject paths.
- Updated the approval modal copy to the Phase 9 UI contract, including `Approve Decision` and `Reject Decision`.
- Added LiveView and integration coverage proving approve resumes from durable workflow state and reject leaves the run paused.
- Extended approval audit coverage to assert approved, rejected, and expired decision rows carry actor, tenant, trace, approval id, and decision lineage.
- Added focused runtime coverage proving expiration preserves paused workflow truth while still writing durable audit evidence.

## Task Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 | `9d1b758ad259c3622864dce65f60821c311beec4` | Restore workflow-owned approval UI path and resume behavior |
| 2 | `7583cd7b9ea66014b877c381d6a96ab2effc2f78` | Lock approval audit attribution and expiration coverage |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Test Harness] Normalized isolated audit-outbox unique-index setup**
- **Found during:** Task 2
- **Issue:** Focused audit/runtime suites created a local unique index name that did not match the approval outbox schema constraint, making duplicate-key rollback checks unreliable in isolation.
- **Fix:** Updated the test-local DDL to use `ai_audit_outbox_events_tenant_id_dedupe_key_index`, matching the schema contract.
- **Impact:** No product behavior change; isolated verification is now trustworthy.

## Verification

- `MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_test.exs test/scoria/workflows/integration_test.exs`
- `MIX_ENV=test mix test test/scoria/sre/audit_outbox_test.exs test/scoria/workflows/runtime_test.exs`
- `MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_test.exs test/scoria/workflows/integration_test.exs test/scoria/sre/audit_outbox_test.exs test/scoria/workflows/runtime_test.exs`

## Next Phase Readiness

Incident routing and relay work can now build on a restored approval boundary with durable, attributable decision evidence and workflow-owned continuation behavior.
