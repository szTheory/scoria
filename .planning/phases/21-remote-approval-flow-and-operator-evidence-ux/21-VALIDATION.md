---
phase: 21
slug: remote-approval-flow-and-operator-evidence-ux
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-18
---

# Phase 21 - Validation Strategy

> Per-phase validation contract for workflow-owned remote approvals, embedded operator inbox/fleet UX, and run-centric remote evidence.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `ExUnit` + `Phoenix.LiveViewTest` + focused telemetry assertions + grep checks |
| **Config file** | `config/test.exs` and `test/test_helper.exs` |
| **Quick run command** | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/workflows_test.exs test/scoria/connectors/invocation_test.exs test/scoria_web/live/orchestrator_live_test.exs test/scoria_web/live/orchestrator_live_sre_test.exs test/scoria/sre/telemetry_test.exs` |
| **Full suite command** | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test` |
| **Estimated runtime** | ~45 seconds for task-local smoke lanes; ~120 seconds for the full phase quick run |

---

## Sampling Rate

- **After every task commit:** Run the task-local smoke lane for the active plan.
  - `21-01` Task 1 smoke: `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/workflows_test.exs test/scoria/connectors/invocation_test.exs`
  - `21-01` Task 2 smoke: `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/workflows_test.exs`
  - `21-02` Task 1 smoke: `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_sre_test.exs`
  - `21-02` Task 2 smoke: `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_test.exs test/scoria_web/live/orchestrator_live_sre_test.exs`
  - `21-03` Task 1 smoke: `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/connectors/invocation_test.exs test/scoria/workflows_test.exs`
  - `21-04` Task 1 smoke: `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_sre_test.exs test/scoria/sre/telemetry_test.exs`
- **After Wave 1:** Re-run the `21-01` smoke lane plus grep checks for connector-aware approval lineage fields.
- **After Wave 2:** Run the Phase 21 quick run command.
- **Before `$gsd-verify-work 21`:** Full suite must be green.
- **Max feedback latency:** 120 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 21-01-01 | 01 | 1 | `POLI-03`, `EVID-02` | `T-21-01`, `T-21-02` | Remote write/exec and auth/scope blockers enter workflow-owned approval waits with connector/local-tool/evidence lineage instead of UI-local state | integration | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/workflows_test.exs test/scoria/connectors/invocation_test.exs && rg -n 'connector_id|local_tool_id|blocker_kind|audit_outbox_event_id|workflow_event_id' lib/scoria/observe/approval.ex lib/scoria/workflows.ex` | planned | ⬜ pending |
| 21-01-02 | 01 | 1 | `POLI-03`, `EVID-02`, `EVID-03` | `T-21-03` | Inbox and notebook projections load from workflow-owned queries without moving exact ids into metric labels | integration | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/workflows_test.exs && rg -n 'approval_id|connector_id|local_tool_id|audit_outbox_event_id' lib/scoria/workflows/remote_approval_projection.ex` | planned | ⬜ pending |
| 21-02-01 | 02 | 2 | `EVID-01`, `POLI-03` | `T-21-04`, `T-21-05` | Fleet and drawer projections expose durable connector/grant/snapshot/local-tool state plus approval links without faking live control-plane truth | LiveView + projection | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_sre_test.exs` | planned | ⬜ pending |
| 21-02-02 | 02 | 2 | `EVID-01`, `POLI-03` | `T-21-04`, `T-21-06` | The embedded dashboard renders inbox-first triage and connector detail drilldown while routing actions through explicit backend APIs | LiveView | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_test.exs test/scoria_web/live/orchestrator_live_sre_test.exs` | planned | ⬜ pending |
| 21-03-01 | 03 | 3 | `EVID-02`, `POLI-03` | `T-21-07`, `T-21-08` | Typed remediation stays separate from approval status and replay remains explicit after fresh durable evidence | integration | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/connectors/invocation_test.exs test/scoria/workflows_test.exs` | planned | ⬜ pending |
| 21-04-01 | 04 | 4 | `EVID-02`, `EVID-03` | `T-21-08`, `T-21-09` | Run-centric evidence notebook follows the locked reading order and telemetry labels stay low-cardinality while exact ids remain in refs and links | LiveView + telemetry | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_sre_test.exs test/scoria/sre/telemetry_test.exs && rg -n 'def (labels|refs)' lib/scoria/sre/telemetry_identity.ex` | planned | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave Coverage

| Wave | Plans | Coverage Goal | Automated Proof |
|------|-------|---------------|-----------------|
| 1 | `21-01` | Establish workflow-owned approval truth and connector-aware projection seams for remote write/exec and auth/scope blockers | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/workflows_test.exs test/scoria/connectors/invocation_test.exs` |
| 2 | `21-02` | Prove the embedded operator inbox/fleet UX over the shared workflow/connectors projection seams | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_test.exs test/scoria_web/live/orchestrator_live_sre_test.exs` |
| 3 | `21-03` | Prove typed remediation and backend evidence projection after the dashboard/query seam changes settle | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/connectors/invocation_test.exs test/scoria/workflows_test.exs` |
| 4 | `21-04` | Prove the run-centric evidence notebook and low-cardinality telemetry contract | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_sre_test.exs test/scoria/sre/telemetry_test.exs` |

---

## Wave 0 Requirements

- [x] Existing ExUnit and Phoenix LiveView seams already cover workflow approvals, connector invocation evidence, and embedded dashboard rendering.
- [x] Existing telemetry helpers provide the label-vs-refs contract that `EVID-03` must preserve.
- [x] The phase has a concrete verification lane for each planned task, including a dedicated telemetry lane.
- [x] The environment caveat is explicit: DB-backed verification must run with `SCORIA_DB_PORT=55432 MIX_ENV=test`.

---

## Automated Closure Notes

- `POLI-03` is not complete until remote write/exec approval gating is covered in the same workflow-owned approval spine as auth/scope blockers.
- `EVID-03` is not complete until telemetry tests prove exact connector, approval, and invocation ids stay out of label space.
- The final phase closeout should include one full-suite run because workflow, connector, SRE, and LiveView seams all change.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verification
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all existing infrastructure dependencies
- [x] No watch-mode flags
- [x] Feedback latency target is under 120 seconds
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated on 2026-05-18. Phase 21 now has a Nyquist-compatible validation contract for workflow-owned remote approvals, embedded operator triage surfaces, run-centric evidence, and low-cardinality telemetry verification.
