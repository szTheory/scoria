# Phase 01 Security Audit

**Phase:** 01 — Orchestrator Live Wiring (Runtime PubSub, Trace Broadcast, HITL)
**Audited:** 2026-05-30
**Auditor:** gsd-security-auditor
**Result:** SECURED (15/15 threats closed)

## ASVS Level

2 (project default; no phase-specific override in PLAN config)

## Threat Verification Summary

| Threat ID | Category | Disposition | Status | Evidence |
|-----------|----------|-------------|--------|----------|
| T-01-01 | Information disclosure | block | CLOSED | `lib/scoria/observe/telemetry.ex:27-28`; `lib/scoria/observe/trace_projection.ex:43,65-71`; `lib/scoria/observe/operator_broadcast.ex:37` |
| T-01-02 | Elevation of privilege | block | CLOSED | `lib/scoria/observe/operator_broadcast.ex:28-44,48-56,59-77`; no `scoria:runs:all` in lib/; `test/scoria/observe/operator_broadcast_test.exs:59-89` |
| T-01-03 | Information disclosure | mitigate | CLOSED | `lib/scoria/observe/trace_projection.ex:9-21,65-71` |
| T-01-04 | Denial of service | mitigate | CLOSED | `lib/scoria/observe/operator_broadcast.ex:32-38` (incremental `trace_opened` + `trace_span` only) |
| T-01-05 | Tampering | accept | CLOSED | Accepted risk log below; `docs/adoption_lanes.md:31-44` |
| T-01-06 | Information disclosure | block | CLOSED | `lib/scoria/workflows/remote_approval_projection.ex:56,126-128`; `lib/scoria_web/live/orchestrator_live.ex:422-424` |
| T-01-07 | Elevation of privilege | block | CLOSED | `lib/scoria/workflows.ex:641-643,657-691`; `test/scoria/workflows_test.exs:497-515` |
| T-01-08 | Tampering | mitigate | CLOSED | `lib/scoria_web/live/orchestrator_live.ex:414-445,150-151` |
| T-01-09 | Repudiation | mitigate | CLOSED | `lib/scoria_web/live/orchestrator_live.ex:909-914,116-123`; `lib/scoria/workflows.ex:692` |
| T-01-10 | Denial of service | mitigate | CLOSED | `lib/scoria_web/live/orchestrator_live.ex:1183-1196` |
| T-01-11 | Spoofing | mitigate | CLOSED | `lib/scoria_web/live/orchestrator_live.ex:52-54,885`; `docs/adoption_lanes.md:36-41` |
| T-01-12 | Elevation of privilege | block | CLOSED | `lib/scoria_web/live/orchestrator_live.ex:985,1019` |
| T-01-13 | Spoofing | block | CLOSED | `docs/adoption_lanes.md:36-41`; `test/scoria_web/live/orchestrator_live_integration_test.exs:136-153` |
| T-01-14 | Repudiation | mitigate | CLOSED | `test/scoria_web/live/orchestrator_live_integration_test.exs:134`; `lib/mix/tasks/scoria.test.semantic_fast_path.ex:12` |
| T-01-15 | Tampering | accept | CLOSED | Accepted risk log below; `lib/scoria/verification_lanes.ex:74`; `test/scoria/verification_lanes_test.exs:29-34` |

## Accepted Risks

### T-01-05 — PubSub message tampering (LOW)

**Risk:** Any in-cluster BEAM process can call `OperatorBroadcast.broadcast/2` and publish to arbitrary tenant topics. PubSub messages are not cryptographically signed.

**Rationale:** Fan-out is server-side within the BEAM cluster. Cross-process trust is the host application's BEAM/OAuth boundary, not Scoria's PubSub layer.

**Transfer / host responsibility:** Host apps must secure `/scoria` (and related operator routes) with authentication and correct session injection. See `docs/adoption_lanes.md` Host session identity section.

**Evidence:** `lib/scoria/observe/operator_broadcast.ex:1-12,23-25`; `01-REVIEW.md` info finding (public `broadcast/2`, accepted per T-01-05).

### T-01-15 — Closeout lane widening (LOW)

**Risk:** Adding integration tests to closeout lanes would slow release gates and blur lane contracts.

**Rationale:** `VerificationLanes.closeout_order/0` remains `[:release_preview, :adoption, :runtime_to_handoff]`. ORCH-LIVE-01 integration proof runs in semantic fast-path lane only.

**Evidence:** `lib/scoria/verification_lanes.ex:74`; `lib/mix/tasks/scoria.test.semantic_fast_path.ex:12`; no `orchestrator_live_integration` in `lib/scoria/verification_lanes.ex`.

## Defense-in-Depth Notes (Informational — Not Register Blockers)

These items were flagged in `01-REVIEW.md` but are **outside** the declared T-01-01 mitigation scope (`Redactor.redact/1` before `span_stopped/1` only):

1. **Span-delta path:** `lib/scoria/observe/telemetry.ex:20-21` calls `OperatorBroadcast.span_delta/1` without prior `Redactor.redact/1`. Acceptable for v2.11 stub (D-128); address before production LLM token streaming.
2. **DB hydrate re-projection:** `lib/scoria_web/live/orchestrator_live.ex:1046-1056` passes DB `span.attributes` into `TraceProjection.span_view/1` without re-redaction. Safe when Buffer persisted redacted attributes; legacy rows could leak non-deny-list keys in `attributes_preview`.

## Unregistered Flags

None — no `## Threat Flags` section in phase SUMMARY files.

## T-01-01 Span-Delta Evaluation

**Verdict: CLOSED** against register.

The threat register mitigation explicitly requires `Redactor.redact/1` before `span_stopped/1` and capped `attributes_preview` — both implemented. The span-delta telemetry path is a separate code path not covered by the T-01-01 mitigation declaration; it is tracked as defense-in-depth follow-up in `01-REVIEW.md`, not as an open register item.
