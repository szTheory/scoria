---
phase: 09
slug: restore-audited-approval-and-incident-delivery-wiring
status: planned
nyquist_compliant: true
wave_0_required: false
created: 2026-05-12
---

# Phase 9 - Validation Strategy

## Phase Goal

Restore the live approval and incident-delivery seams so operator approvals flow through audited workflow mutations, incident routing produces durable delivery intent rows, relay fanout runs post-commit, and the existing trace-first notebook can prove the real evidence lineage.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit + Phoenix.LiveViewTest |
| Config file | `test/test_helper.exs` |
| Quick run command | `MIX_ENV=test mix test test/scoria/workflows/runtime_test.exs test/scoria/sre/incident_test.exs test/scoria/sre/relay_test.exs test/scoria_web/live/orchestrator_live_sre_test.exs` |
| Full suite command | `MIX_ENV=test mix test` |
| Estimated feedback loop | targeted suites under 30 seconds, full suite at plan-wave boundaries |

## Requirement Mapping

| Requirement | Covered By Plans | Primary Verification Commands |
|-------------|------------------|-------------------------------|
| SRE-05 | `09-01` | `MIX_ENV=test mix test test/scoria/workflows/runtime_test.exs test/scoria/workflows/integration_test.exs test/scoria_web/live/orchestrator_live_test.exs` |
| SRE-06 | `09-02` | `MIX_ENV=test mix test test/scoria/sre/incident_test.exs test/scoria/sre/relay_test.exs` |
| SRE-07 | `09-03` | `MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_sre_test.exs test/scoria/workflows/integration_test.exs test/scoria/sre/incident_test.exs test/scoria/sre/relay_test.exs` |

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|--------|
| 09-01-01 | 01 | 1 | SRE-05 | T-09-01-01 | Approval UI delegates every decision to `Scoria.Workflows.approve/3` and preserves actor, tenant, and trace attribution | integration | `MIX_ENV=test mix test test/scoria/workflows/integration_test.exs test/scoria_web/live/orchestrator_live_test.exs` | planned |
| 09-01-02 | 01 | 1 | SRE-05 | T-09-01-02 | Approval transitions write workflow truth and audit-outbox evidence before any resume action runs | unit | `MIX_ENV=test mix test test/scoria/workflows/runtime_test.exs test/scoria/sre/audit_outbox_test.exs` | planned |
| 09-02-01 | 02 | 2 | SRE-06 | T-09-02-01 | Incident open and escalation paths create durable `NotificationDelivery` rows inside the same transaction as incident graph changes | unit | `MIX_ENV=test mix test test/scoria/sre/incident_test.exs` | planned |
| 09-02-02 | 02 | 2 | SRE-06 | T-09-02-02 | Unconfigured or noop routing still preserves durable local delivery evidence instead of dropping the notification | unit | `MIX_ENV=test mix test test/scoria/sre/relay_test.exs` | planned |
| 09-03-01 | 03 | 3 | SRE-07 | T-09-03-01 | Relay drains real delivery rows post-commit and persists outcome evidence without mutating incident truth in-place | integration | `MIX_ENV=test mix test test/scoria/sre/incident_test.exs test/scoria/sre/relay_test.exs` | planned |
| 09-03-02 | 03 | 3 | SRE-07 | T-09-03-02 | The trace-first notebook lazily renders approval, audit, incident, and delivery lineage produced by the real path rather than seeded placeholders | liveview | `MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_sre_test.exs test/scoria/workflows/integration_test.exs` | planned |

## Sampling Rate

- After each task commit: run the task's targeted command from the table above.
- After each plan: run the plan-level targeted suite named in the plan's `<verify>`.
- After plan 03: run `MIX_ENV=test mix test`.
- Before verification/UAT: full suite must be green, or any remaining unrelated baseline failures must be explicitly documented.

## Multi-Source Coverage Audit

### GOAL Coverage

| Source | Item | Covered By |
|--------|------|------------|
| GOAL | Workflow approvals are audited and resume through workflow-owned seams | `09-01` |
| GOAL | Incident routing produces durable delivery rows consumed by relay | `09-02` |
| GOAL | Operator evidence proves the real approval -> audit and incident -> delivery -> relay lineage in the existing notebook | `09-03` |

### REQ Coverage

| Source | Item | Covered By |
|--------|------|------------|
| REQ | SRE-05 | `09-01` |
| REQ | SRE-06 | `09-02` |
| REQ | SRE-07 | `09-03` |

### RESEARCH Coverage

| Source | Item | Covered By |
|--------|------|------------|
| RESEARCH | Use `Scoria.Workflows.approve/3` as the only blessed approval mutation path | `09-01` |
| RESEARCH | Add `NotificationDelivery` creation inside `IncidentManager`'s `Ecto.Multi` | `09-02` |
| RESEARCH | Keep relay fanout post-commit and prove real notebook lineage with lazy loading | `09-03` |
| RESEARCH | Avoid relying on seeded placeholder tests as final proof | `09-03` |

### CONTEXT Decision Coverage

| Decision | Covered By |
|----------|------------|
| D-01, D-02, D-03, D-04, D-05, D-06 | `09-01` |
| D-07, D-08, D-09, D-10, D-11, D-12 | `09-02` |
| D-13, D-14, D-15, D-16, D-17, D-18 | `09-03` |

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Notebook readability under combined approval, audit, incident, and delivery evidence | SRE-07 | visual judgment on density and operator scanability | Load a run with one approval action and one delivered or noop incident notification; confirm the notebook remains trace-first, heavy evidence is opt-in, and every displayed fact deep-links back to the same run or trace lineage. |

## Validation Sign-Off

- [x] Every requirement maps to at least one plan and targeted automated command.
- [x] Every task has an automated verify command.
- [x] No verification relies on `mix test` alone.
- [x] Deferred scope such as new dashboards, telemetry wiring, and bootstrap cleanup is excluded.
- [x] Locked decisions are traced to plan coverage.
