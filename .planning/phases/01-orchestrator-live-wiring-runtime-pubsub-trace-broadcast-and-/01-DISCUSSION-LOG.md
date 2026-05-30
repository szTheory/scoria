# Phase 01: Orchestrator Live Wiring — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `01-CONTEXT.md`.

**Date:** 2026-05-30
**Phase:** 01-orchestrator-live-wiring
**Areas discussed:** PubSub architecture, trace projection, event source, HITL wiring, token streaming scope, verification/reconnect, adopter DX
**Mode:** `--all` with subagent research + auto-recommendations (user requested one-shot coherent recommendations)

---

## PubSub topic model

| Option | Description | Selected |
|--------|-------------|----------|
| Tenant-only `scoria:runs:{tenant}` | Matches OrchestratorLive; one subscription | ✓ |
| Run/trace-only topics | Precise but N subscriptions | |
| Dual fan-out (tenant + trace) | Flexible; defer trace topic | partial |
| Phoenix.Channel per run | Overkill for embedded lib | |

**Choice:** D-113–D-115 — `Scoria.Observe.OperatorBroadcast`; primary tenant topic; preserve run-scoped workflow topic for WorkflowLive.

---

## Trace projection shape

| Option | Description | Selected |
|--------|-------------|----------|
| Full trace snapshot every span | Simple; bandwidth/render cost | |
| Span deltas + trace_opened | Incremental; idempotent merge | ✓ |
| DB poll only | No live feel | |
| Snapshot on open + deltas | Same as chosen pattern | ✓ |

**Choice:** D-116–D-117 — `TraceProjection` module; `trace_opened` + `trace_span` messages.

---

## Event source hook

| Option | Description | Selected |
|--------|-------------|----------|
| Buffer flush (5s) | Post-persist only | |
| Buffer handle_cast | Couples UI to persistence backpressure | |
| Telemetry after redaction | Immediate; redaction preserved | ✓ |
| Dedicated GenServer relay | Extra process | |

**Choice:** D-118 — extend `Observe.Telemetry` before `Buffer.cast_span`.

---

## HITL approval wiring

| Option | Description | Selected |
|--------|-------------|----------|
| Tenant approval fan-out from Workflows | Bridges run vs tenant topic gap | ✓ |
| Subscribe to all workflow run topics | Does not scale | |
| Inbox poll only | Misses urgent approvals | |
| Raw `%Approval{}` in LiveView | PII/schema coupling | |
| Projection map + redacted preview | Inbox/modal parity | ✓ |

**Choice:** D-120–D-124 — hybrid push modal + inbox; blocking overlay; multi-operator broadcasts.

---

## Token streaming

| Option | Description | Selected |
|--------|-------------|----------|
| Global `{:token, chunk}` PubSub | No trace/span correlation | |
| Per-span delta telemetry | Aligns with trace tree | ✓ |
| Both token + span channels | Duplicate pipelines | |
| Defer all token UI | Wastes existing coalescer | |

**Choice:** D-125–D-128 — span-attached preview; 75ms per-span coalesce; v2.11 gate = spans + HITL not char streaming.

---

## Verification & reconnect

| Option | Description | Selected |
|--------|-------------|----------|
| Keep send/2 as only ORCH-LIVE proof | Hollow production | |
| New integration test file | Real producer path | ✓ |
| Widen closeout_order | Violates v2.4 contract | |
| Semantic fast-path pin | Fits CI topology | ✓ |
| DB hydrate on mount | Reconnect safety | ✓ |

**Choice:** D-129–D-131 — integration test; semantic lane; session doc fragment; disconnect/reconnect test.

---

## Claude's Discretion

User requested full auto-recommendations without interactive turns. All gray areas resolved via four parallel research subagents cross-checked against `prompts/` research and codebase. Planner discretion limited to file layout and exact query limits within locked decisions.

---

## Deferred Ideas

See `<deferred>` section in `01-CONTEXT.md`.
