---
phase: 12
slug: canonical-runtime-identity
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-13
---

# Phase 12 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` |
| **Quick run command** | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/workflows_test.exs test/scoria/workflows/runtime_test.exs test/scoria/mcp/executor_test.exs test/scoria/sre/audit_outbox_test.exs test/scoria/sre/telemetry_test.exs` |
| **Full suite command** | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test` |
| **Estimated runtime** | ~30-90 seconds |

## Sampling Rate

- **After every task commit:** Run `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/workflows_test.exs test/scoria/workflows/runtime_test.exs test/scoria/mcp/executor_test.exs test/scoria/sre/audit_outbox_test.exs test/scoria/sre/telemetry_test.exs`
- **After every plan wave:** Run `SCORIA_DB_PORT=55432 MIX_ENV=test mix test`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 90 seconds

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 12-01-01 | 01 | 1 | IDEN-01 | T-12-01-01 | Run creation persists canonical `actor_id`, `tenant_id`, and `session_id` once | unit/integration | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/workflows_test.exs` | ✅ | ✅ green |
| 12-01-02 | 01 | 1 | IDEN-01 | T-12-01-02 | Host adapter helpers normalize input into one identity envelope | unit | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/identity_test.exs` | ✅ | ✅ green |
| 12-02-01 | 02 | 2 | IDEN-02 | T-12-02-01 | Approval and workflow seams inherit immutable root identity without `session_id` actor fallback | integration | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/workflows/runtime_test.exs test/scoria/workflows/integration_test.exs test/scoria/sre/audit_outbox_test.exs` | ✅ | ✅ green |
| 12-03-01 | 03 | 3 | IDEN-02 | T-12-03-01 | Runtime and MCP telemetry project canonical identity without adding high-cardinality actor/session labels | integration | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/workflows/runtime_telemetry_test.exs test/scoria/mcp/executor_telemetry_test.exs test/scoria/sre/telemetry_test.exs` | ✅ | ✅ green |

*Status legend: ✅ green · ❌ red · ⚠️ flaky*

## Wave 0 Requirements

- [x] `test/scoria/identity_test.exs` is planned in `12-01` for dedicated canonical identity normalization coverage
- [x] workflow/approval fixture updates are covered by `12-01` and `12-02`
- [x] migration verification coverage for run and approval identity columns plus indexes is covered by `12-01` and `12-02`

## Manual-Only Verifications

1. Start the app or harness and select one run that carries explicit `actor_id`, `tenant_id`, and `session_id`.
2. Open the workflow or operator LiveView for that same run and confirm the workflow header or summary shows the expected canonical identity values.
3. Open the approval evidence or drilldown for the same run and confirm the same `actor_id`, `tenant_id`, and `session_id` remain visible without fallback or mismatch.
4. Open the audit or telemetry-facing evidence surface referenced for the same run and confirm the same identity lineage is still coherent there.
5. Record one short outcome note using the block below. If identity diverges, name the exact surface where the divergence appears.

**Expected observation:** one run shows the same canonical `actor_id`, `tenant_id`, and `session_id` across workflow summary, approval evidence, and audit or telemetry evidence.

**Operator observation:** run `470ddbcc-33e5-4b38-9059-919d44040e0b` showed `actor_id=manual-actor`, `tenant_id=manual-tenant`, and `session_id=manual-session` consistently across `Scoria.get_run/1`, the pending approval record, and the `approval.requested` audit outbox row.

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** the automated identity lanes, the downstream Phase 13 smoke lane, and the bounded manual operator walkthrough all passed on 2026-05-16 against `localhost:55432`; run `470ddbcc-33e5-4b38-9059-919d44040e0b` kept the same canonical `actor_id`, `tenant_id`, and `session_id` across summary, approval, and audit evidence.
