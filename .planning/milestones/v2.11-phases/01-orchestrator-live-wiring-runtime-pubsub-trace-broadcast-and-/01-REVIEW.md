---
status: issues
phase: 01-orchestrator-live-wiring-runtime-pubsub-trace-broadcast-and-
reviewed: 2026-05-30
depth: standard
files_reviewed: 19
critical: 0
warning: 2
info: 3
total: 5
---

# Phase 01 Code Review

Review of ORCH-LIVE-01 production wiring: Observe-layer tenant PubSub bridge (`OperatorBroadcast`, `TraceProjection`, telemetry hook), HITL fan-out and OrchestratorLive handlers, DB hydrate on reconnect, and integration proof.

**Scope:** 19 files from `01-01-SUMMARY.md`, `01-02-SUMMARY.md`, and `01-03-SUMMARY.md` (12 production modules + 7 test/doc/lane files).

## Summary

Phase 01 closes the HOLLOW_PROP producer gap with a well-structured redact → broadcast → buffer pipeline and tenant-scoped PubSub. Blocking threat-model gates **T-01-01**, **T-01-02**, **T-01-06**, and **T-01-07** are implemented and covered by unit/integration tests. Two defense-in-depth gaps remain around the span-delta streaming path and DB hydrate re-projection; neither blocks the v2.11 acceptance gate (ReqLLM streaming adapter deferred) but should be addressed before token deltas carry production LLM output.

## Findings

| Severity | Area | File | Finding |
|----------|------|------|---------|
| warning | T-01-01 redact-before-broadcast | `lib/scoria/observe/telemetry.ex` | `[:scoria, :observe, :span, :delta]` handler calls `OperatorBroadcast.span_delta/1` directly without `Redactor.redact/1`. Chunks broadcast verbatim on `scoria:runs:{tenant_id}`. Acceptable for the v2.11 stub (D-128), but when the ReqLLM streaming adapter lands, LLM output may contain secrets/PII on PubSub. Apply redaction to `chunk` (or a dedicated delta scrubber) before broadcast. |
| warning | T-01-01 defense in depth | `lib/scoria_web/live/orchestrator_live.ex` | `span_view_from_record/1` (hydrate path) passes DB `span.attributes` into `TraceProjection.span_view/1` without re-running `Redactor.redact/1`. Safe when Buffer persisted redacted attributes (normal telemetry path), but legacy or manually inserted spans could expose non-deny-list secrets in `attributes_preview` after reconnect. Re-apply `Redactor.redact/1` on hydrate for defense in depth. |
| info | PubSub tenant isolation | `lib/scoria_web/live/orchestrator_live.ex` | `mount/3` defaults `session["tenant_id"]` to `"default"` when unset. Hosts that omit the session contract (D-130) cohabit one PubSub topic — operational misconfiguration, not a cross-tenant bypass, but worth surfacing in host onboarding. Documented in `docs/adoption_lanes.md`. |
| info | PubSub tenant isolation | `lib/scoria/observe/operator_broadcast.ex` | `broadcast/2` is public; any in-cluster caller can publish to any tenant topic. Accepted per T-01-05 (BEAM trust boundary). No `scoria:runs:all` fallback exists. |
| info | Trace dedup | `lib/scoria/observe/operator_broadcast.ex` | ETS `trace_seen` dedup for `{:trace_opened, _}` is per-BEAM-node. Clustered deployments may emit duplicate `trace_opened` on different nodes; OrchestratorLive idempotent merge (`maybe_open_trace/2`) handles this correctly. |

## Focus-area verification

### T-01-01: Redact before broadcast

- **Pass:** `Scoria.Observe.Telemetry.handle_event/4` for `:span, :stop` runs `Redactor.redact/1` before `OperatorBroadcast.span_stopped/1` and before `Buffer.cast_span/1` (D-118 ordering).
- **Pass:** `TraceProjection.span_view/1` exposes only `attributes_preview` (capped at 10 keys / 512 chars, deny-list keys excluded) — never raw `:attributes` on PubSub.
- **Pass:** `buffer_span/1` strips broadcast-only top-level keys (`tenant_id`, etc.) before Buffer insert.
- **Pass:** `RemoteApprovalProjection` builds `arguments_preview` via `Redactor.redact/1`; projection map has no `:arguments` key.
- **Gap:** Span-delta path skips redaction (see warning above).

### T-01-02: Fail closed on missing tenant_id

- **Pass:** `OperatorBroadcast.span_stopped/1`, `span_delta/1`, `hitl_request/2`, and `approval_decided/3` all guard `tenant_id when is_binary(tenant_id) and tenant_id != ""`; otherwise `:dropped` + debug log.
- **Pass:** No global `scoria:runs:all` topic in codebase.
- **Pass:** Unit tests assert drop behavior for missing/nil tenant_id.

### HITL: No raw arguments in DOM

- **Pass:** HITL modal renders `@active_approval[:arguments_preview]` only (redacted map); inbox component shows tool/status/connector — no arguments field.
- **Pass:** `Workflows.mark_waiting_for_approval/3` fans out `RemoteApprovalProjection.get_approval_lineage!/1` map, not raw `%Approval{}`.
- **Pass:** Integration tests assert `refute html =~ "super-secret-key"` after HITL modal render.
- **Pass:** `Workflows.approve/3` rejects stale decisions with `:not_pending`; OrchestratorLive maps to operator-friendly flash.

### PubSub tenant isolation

- **Pass:** OrchestratorLive subscribes to `scoria:runs:{session_tenant_id}` only in `connected?(socket)`.
- **Pass:** All operator events fan out via `OperatorBroadcast.tenant_topic/1`.
- **Pass:** `hydrate_traces/2` filters spans with `attributes->>'tenant_id' = ^tenant_id` (tenant-scoped DB read).
- **Pass:** `load_operator_surface/1` scopes approval inbox, runtimes, and connector fleet by `socket.assigns.tenant_id`.
- **Note:** Session/runtime tenant_id alignment is host-owned (documented in adoption fragment).

## Verified patterns

- Single Observe-layer fan-out module (`OperatorBroadcast`) — no broadcast logic in `ScoriaWeb.*`.
- Dual broadcast preserved: run-scoped `scoria:workflow_runs:{run_id}` + tenant-scoped operator events (D-115).
- Incremental trace merge: idempotent `trace_opened`, upsert by span id, depth decoration via `TraceProjection.with_depths/1`.
- Per-span token coalesce (75ms, 256-chunk cap) with `stream_insert` on flush for LiveComponent re-render.
- Producer-path integration test via `Runtime.start_run/2` → adapter → telemetry → PubSub → DOM (no `send/2`).

## Recommended follow-ups

1. Add `Redactor.redact/1` (or chunk-specific scrub) to the span-delta telemetry path before `OperatorBroadcast.span_delta/1`.
2. Re-redact attributes in `span_view_from_record/1` during DB hydrate.
3. Optional: cancel pending `token_timers` in `maybe_clear_token_preview/2` when span completes to avoid stale flush after span stop.

## Test verification

Phase summaries report passing verification (`compile --warnings-as-errors`, unit + integration + semantic lane). Local re-run in this environment failed at DB migration (`pgvector` extension unavailable) — not attributable to phase 01 source changes.

---
*Review depth: standard | Plans: 01-01, 01-02, 01-03*
