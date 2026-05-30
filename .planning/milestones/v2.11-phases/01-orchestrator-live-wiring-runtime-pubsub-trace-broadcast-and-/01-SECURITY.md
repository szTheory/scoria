---
phase: 01
slug: orchestrator-live-wiring-runtime-pubsub-trace-broadcast-and-
status: verified
threats_open: 0
asvs_level: 2
created: 2026-05-30
---

# Phase 01 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Runtime → Telemetry | Span metadata may contain PII/secrets before redaction | Raw span attributes, tenant_id |
| Observe → PubSub | Redacted operational data fan-out to tenant topic subscribers | Redacted span views, HITL projections |
| PubSub → LiveView | Tenant-scoped topic isolation is the access control boundary | Trace deltas, HITL events, approval decisions |
| Workflows → PubSub | Approval projections cross tenant topic to OrchestratorLive subscribers | Redacted arguments_preview only |
| LiveView → DOM | HITL modal renders operator-facing approval context | arguments_preview (redacted) |
| Operator → Workflows.approve/3 | Side-effecting resume path gated on explicit approval | actor_id, approval decision |
| Host app → Session | Host must inject correct tenant_id before /scoria mount | session tenant_id, actor_id |
| DB → LiveView hydrate | Historical traces loaded for tenant filter only | Tenant-scoped span attributes |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-01-01 | Information disclosure | OperatorBroadcast | mitigate | Redactor.redact/1 before span_stopped/1; TraceProjection attributes_preview capped — never broadcast raw attributes | closed |
| T-01-02 | Elevation of privilege | OperatorBroadcast | mitigate | Fail closed when tenant_id missing — no broadcast, debug log only; no `scoria:runs:all` topic | closed |
| T-01-03 | Information disclosure | TraceProjection | mitigate | attributes_preview cap (10 keys / 512 chars); deny-list keys excluded from preview | closed |
| T-01-04 | Denial of service | Telemetry hook | mitigate | Broadcast is O(1) per span; incremental deltas, no full snapshot on every stop | closed |
| T-01-05 | Tampering | PubSub messages | accept | Server-side fan-out within BEAM cluster; host app secures /scoria route | closed |
| T-01-06 | Information disclosure | RemoteApprovalProjection | mitigate | arguments_preview via Redactor only; never render raw arguments in HEEx | closed |
| T-01-07 | Elevation of privilege | Workflows.approve/3 | mitigate | not_pending guard rejects stale decisions; audit outbox preserved on success | closed |
| T-01-08 | Tampering | HITL modal | mitigate | Blocking overlay requires explicit approve/reject; dismiss does not call approve/3 | closed |
| T-01-09 | Repudiation | Multi-operator race | mitigate | StaleEntryError → friendly flash; approval_decided broadcast syncs UI | closed |
| T-01-10 | Denial of service | Token coalesce | mitigate | 75ms coalesce + 256 chunk cap per span | closed |
| T-01-11 | Spoofing | approve actor | mitigate | Session actor_id passed to approve/3 attrs; host must set session keys (documented) | closed |
| T-01-12 | Elevation of privilege | DB hydrate query | mitigate | Filter traces/spans by tenant_id in attributes — never hydrate all traces | closed |
| T-01-13 | Spoofing | Session tenant mismatch | mitigate | Document host contract; integration test uses matching session + runtime tenant_id | closed |
| T-01-14 | Repudiation | Hollow test props | mitigate | Integration test forbids send/2; semantic lane pin | closed |
| T-01-15 | Tampering | closeout lane widening | accept | Explicit guard: closeout_order/0 unchanged; integration in semantic lane only | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

### Evidence Summary

| Threat ID | Evidence |
|-----------|----------|
| T-01-01 | `lib/scoria/observe/telemetry.ex:27-28` — Redactor before span_stopped; `lib/scoria/observe/trace_projection.ex:43,65-71` — attributes_preview only; `lib/scoria/observe/operator_broadcast.ex:37` — broadcasts span_view, never raw attributes |
| T-01-02 | `lib/scoria/observe/operator_broadcast.ex:28-77` — fail-closed on missing tenant_id; no `scoria:runs:all` in lib/ |
| T-01-03 | `lib/scoria/observe/trace_projection.ex:9-21,65-71` — preview caps and deny-list |
| T-01-04 | `lib/scoria/observe/operator_broadcast.ex:32-38` — incremental trace_opened + trace_span per stop |
| T-01-05 | Accepted risk (see log); `docs/adoption_lanes.md:31-44` — host secures /scoria |
| T-01-06 | `lib/scoria/workflows/remote_approval_projection.ex:56,126-128`; `lib/scoria_web/live/orchestrator_live.ex:422-424` |
| T-01-07 | `lib/scoria/workflows.ex:641-643,657-691`; `test/scoria/workflows_test.exs:497-515` |
| T-01-08 | `lib/scoria_web/live/orchestrator_live.ex:414-445,150-151` — blocking overlay; dismiss clears assign only |
| T-01-09 | `lib/scoria_web/live/orchestrator_live.ex:909-914,116-123` |
| T-01-10 | `lib/scoria_web/live/orchestrator_live.ex:1183-1196` — 256-chunk cap + 75ms coalesce |
| T-01-11 | `lib/scoria_web/live/orchestrator_live.ex:52-54,885`; `docs/adoption_lanes.md:36-41` |
| T-01-12 | `lib/scoria_web/live/orchestrator_live.ex:985,1019` — tenant_id filter on hydrate |
| T-01-13 | `docs/adoption_lanes.md:36-41`; `test/scoria_web/live/orchestrator_live_integration_test.exs:136-153` |
| T-01-14 | `test/scoria_web/live/orchestrator_live_integration_test.exs:134`; `lib/mix/tasks/scoria.test.semantic_fast_path.ex:12` |
| T-01-15 | Accepted risk (see log); `lib/scoria/verification_lanes.ex:74`; `test/scoria/verification_lanes_test.exs:29-34` |

### Defense-in-Depth Follow-Ups (Informational)

Not register blockers; tracked in `01-REVIEW.md`:

1. Add redaction before `OperatorBroadcast.span_delta/1` when production token streaming lands (ReqLLM adapter).
2. Re-apply `Redactor.redact/1` in `span_view_from_record/1` during DB hydrate for legacy rows.

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-01-01 | T-01-05 | PubSub messages are server-side fan-out within the BEAM cluster. Cross-tenant isolation relies on tenant-scoped topics and host app securing the /scoria route. In-cluster callers can publish to any tenant topic — accepted as BEAM trust boundary per plan disposition. | gsd-security-auditor | 2026-05-30 |
| AR-01-02 | T-01-15 | Integration test runs in semantic lane only; closeout_order/0 unchanged. Lane widening risk accepted with explicit guard in verification_lanes.ex and contract test. | gsd-security-auditor | 2026-05-30 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-30 | 15 | 15 | 0 | gsd-security-auditor |

### Security Audit 2026-05-30

| Metric | Count |
|--------|-------|
| Threats found | 15 |
| Closed | 15 |
| Open | 0 |

**Notes:** All plan-time threat model entries verified against implementation. Span-delta redaction gap noted as defense-in-depth follow-up (not in T-01-01 mitigation scope). No `## Threat Flags` in phase SUMMARY files.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-30
