---
phase: 20
slug: policy-stable-tool-identity-and-stateless-invocation
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-17
---

# Phase 20 - Validation Strategy

> Per-phase validation contract for stable local tool identity, drift reconciliation, and dual-plane remote invocation enforcement.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `ExUnit` + `Oban.Testing` + `Ecto SQL Sandbox` + focused grep checks |
| **Config file** | `config/test.exs` and `test/test_helper.exs` |
| **Quick run command** | `mix test test/scoria/connectors/schema_test.exs test/scoria/connectors_test.exs test/scoria/connectors/auth_test.exs test/scoria/mcp/executor_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30 seconds for task-local smoke lanes; ~90 seconds for full phase verification |

---

## Sampling Rate

- **After every task commit:** Run the task-local smoke lane for the active plan.
  - `20-01` smoke: `mix test test/scoria/connectors/schema_test.exs`
  - `20-02` smoke: `mix test test/scoria/connectors/tool_reconciliation_test.exs test/scoria/connectors_test.exs`
  - `20-03` smoke: `mix test test/scoria/connectors/invocation_test.exs test/scoria/connectors/auth_test.exs test/scoria/mcp/executor_test.exs`
- **After Wave 1:** Re-run `20-01` smoke plus grep checks for local-tool schemas and helper exports.
- **After Wave 2:** Run `mix test test/scoria/connectors_test.exs test/scoria/connectors/tool_reconciliation_test.exs`.
- **After Wave 3:** Run the full Phase 20 quick run command.
- **Before `$gsd-verify-work 20`:** Full suite must be green.
- **Max feedback latency:** 90 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 20-01-01 | 01 | 1 | `CONN-03` | `T-20-01`, `T-20-02` | Durable local-tool and alias/history rows exist independently from capability snapshots and preserve stable identity/lifecycle state | schema | `mix test test/scoria/connectors/schema_test.exs` | planned | ⬜ pending |
| 20-01-02 | 01 | 1 | `CONN-03` | `T-20-01` | `Scoria.Connectors` exposes local-tool query helpers so later work uses stable local ids instead of raw snapshot catalog entries | API | `mix test test/scoria/connectors_test.exs && rg -n 'def (get_local_tool|get_local_tool!|list_local_tools)' lib/scoria/connectors.ex` | planned | ⬜ pending |
| 20-02-01 | 02 | 2 | `CONN-03`, `POLI-01` | `T-20-03`, `T-20-04`, `T-20-05` | Reconciliation preserves ids on safe drift and quarantines ambiguous or widening changes | integration | `mix test test/scoria/connectors/tool_reconciliation_test.exs` | planned | ⬜ pending |
| 20-02-02 | 02 | 2 | `CONN-03`, `POLI-01` | `T-20-03`, `T-20-04` | Discovery refresh updates snapshot evidence and local-tool truth in one durable flow without silently widening callable surface area | integration | `mix test test/scoria/connectors_test.exs test/scoria/connectors/tool_reconciliation_test.exs && rg -n 'ToolReconciliation' lib/scoria/connectors/discovery.ex` | planned | ⬜ pending |
| 20-03-01 | 03 | 3 | `AUTH-03`, `POLI-01`, `POLI-02` | `T-20-06`, `T-20-08` | Connector-aware invocation blocks before outbound transport unless local policy and grant scope both pass; default lane stays stateless | integration | `mix test test/scoria/connectors/invocation_test.exs test/scoria/mcp/executor_test.exs` | planned | ⬜ pending |
| 20-03-02 | 03 | 3 | `AUTH-03`, `POLI-01` | `T-20-07` | Auth failure and scope escalation emit durable redacted evidence with missing scopes, local tool identity, and workflow-compatible lineage | integration | `mix test test/scoria/connectors/auth_test.exs test/scoria/connectors/invocation_test.exs test/scoria/workflows_test.exs && rg -n 'connector\\.auth_failed|scope_escalation|missing_scopes|local_tool_id|run_id|step_id|audit_outbox_event_id|workflow_event_id' lib/scoria/connectors/auth.ex lib/scoria/sre.ex lib/scoria/workflows.ex` | planned | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave Coverage

| Wave | Plans | Coverage Goal | Automated Proof |
|------|-------|---------------|-----------------|
| 1 | `20-01` | Establish stable local-tool identity, lifecycle state, and alias/history persistence | `mix test test/scoria/connectors/schema_test.exs` |
| 2 | `20-02` | Prove refresh-time reconciliation preserves ids on safe drift and quarantines risky drift | `mix test test/scoria/connectors_test.exs test/scoria/connectors/tool_reconciliation_test.exs` |
| 3 | `20-03` | Prove dual-plane invocation enforcement, typed auth/scope outcomes, and stateless-first default execution | `mix test test/scoria/connectors/invocation_test.exs test/scoria/connectors/auth_test.exs test/scoria/mcp/executor_test.exs` |

---

## Wave 0 Requirements

- [x] Existing ExUnit, Oban-testing, and Ecto sandbox patterns already cover connector durability, refresh jobs, auth flows, and executor envelopes.
- [x] Existing audit outbox and workflow seams already provide the durable evidence style this phase must reuse.
- [ ] `test/scoria/connectors/tool_reconciliation_test.exs` must be added in Wave 2.
- [ ] `test/scoria/connectors/invocation_test.exs` must be added in Wave 3.
- [ ] Workflow-lineage coverage for auth failure and scope escalation must exist by the end of Wave 3 in `test/scoria/workflows_test.exs` or an equivalent focused test.
- [ ] Existing connector schema coverage must be extended for local-tool and alias/history rows in Wave 1.

---

## Automated Closure Notes

- `CapabilitySnapshot` remains evidence input, not invocation identity truth.
- Phase 20 verification is not complete until the new reconciliation and invocation test files exist and pass.
- The final phase closeout should include one full-suite run because invocation changes touch the shared executor seam.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verification
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all existing infrastructure dependencies
- [x] No watch-mode flags
- [x] Feedback latency target is under 90 seconds
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated on 2026-05-17. Phase 20 now has a Nyquist-compatible validation contract covering stable local tool identity, conservative drift reconciliation, and stateless dual-plane invocation enforcement.
