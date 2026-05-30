# Phase 01: Orchestrator Live Wiring — Context

**Gathered:** 2026-05-30
**Status:** Ready for planning
**Mode:** Full discuss (--all) with research-backed auto-recommendations

<domain>
## Phase Boundary

Wire **production** runtime→PubSub→OrchestratorLive paths for ORCH-LIVE-01:

1. **Live trace stream** — completed spans appear in the orchestrator trace tree without page refresh or test-only `send/2`.
2. **HITL approval modal** — real `Workflows.mark_waiting_for_approval/3` pauses surface a blocking approval modal; approve/reject flows through existing `Workflows.approve/3` + `Resume.resume_run/1`.

**In scope:** Observe-layer broadcast bridge, trace projection, tenant-scoped PubSub, OrchestratorLive handler updates, DB reconnect hydrate, integration tests proving producer path, adoption doc fragment for session keys.

**Out of scope (v2.11):** OTel export of operator events, multi-tab operator sync/Presence claims, mobile modal polish, widening `VerificationLanes.closeout_order/0`, installer session injection, full ReqLLM streaming adapter (token deltas stub only), separate trace-detail LiveView topic.

</domain>

<decisions>
## Implementation Decisions

### PubSub architecture (D-113–D-115)

- **D-113:** Introduce `Scoria.Observe.OperatorBroadcast` as the **single tenant-scoped fan-out module** in the Observe layer (parallel API to `Workflows.subscribe_run/1` + `broadcast/2`). Do **not** put broadcast logic in `ScoriaWeb.*`.
- **D-114:** OrchestratorLive stays subscribed to **`scoria:runs:{tenant_id}`** (already wired). All operator-dashboard live events (trace deltas, HITL, optional token previews) publish to this topic. Defer optional `scoria:traces:{trace_id}` until a trace-detail LiveView exists.
- **D-115:** Preserve **dual broadcast**: run-scoped `scoria:workflow_runs:{run_id}` with `{:workflow_updated, _}` / `{:approval_requested, run_id, approval_id}` for `WorkflowLive.Show`; tenant-scoped fan-out for `OrchestratorLive`. Never subscribe OrchestratorLive to per-run topics.

### Trace projection & event source (D-116–D-119)

- **D-116:** Broadcast **incremental trace deltas**, not full snapshots on every span:
  - `{:trace_opened, header_map}` — first span for a trace (id, session_id, workflow_run_id, tenant_id)
  - `{:trace_span, trace_id, span_view_map}` — one completed span per message
  - Keep `{:new_trace, trace_map}` as a **test/migration shim** only (maps to opened + spans list).
- **D-117:** Add `Scoria.Observe.TraceProjection` to build UI-safe `span_view` maps (`id`, `name`, `span_kind`, `status_code`, `parent_id`, timing, `attributes_preview` capped/redacted) and `with_depths/1` for `TraceTreeComponent` (reuse depth algorithm from `WorkflowLive.Show`).
- **D-118:** Hook broadcast in **`Scoria.Observe.Telemetry.handle_event/4` immediately after `Redactor.redact/1`, before `Buffer.cast_span/1`. **Do not** hook at Buffer flush (5s default latency is unacceptable for live UI). Buffer remains durability-only.
- **D-119:** On `connected?(socket)`, **hydrate** recent traces for `tenant_id` from `ai_traces`/`ai_spans` (default limit 25, configurable), seed `:traces` stream, then merge PubSub deltas. PubSub alone is insufficient after LiveView reconnect.

**Required span metadata contract:** adapters and runtime must enrich `:span, :stop` metadata with `tenant_id`, `trace_id`, `parent_id`, and `workflow_run_id` before telemetry fires. Missing `tenant_id` → drop broadcast + debug log (fail closed on tenant topic).

### HITL approval wiring (D-120–D-124)

- **D-120:** After successful `Workflows.mark_waiting_for_approval/3`, fan-out to tenant topic:
  ```elixir
  OperatorBroadcast.hitl_request(tenant_id, projection)
  ```
  where `projection = RemoteApprovalProjection` map fetched for the inserted approval. Message tuple: **`{:hitl_request, projection_map}`** (matches existing OrchestratorLive handler shape, but projection not raw `%Approval{}`).
- **D-121:** Extend `RemoteApprovalProjection` with **`arguments_preview`** — redacted via `Scoria.Observe.Redactor` (never render raw `arguments` in DOM). Inbox rows and modal use the **same map shape**.
- **D-122:** Multi-operator safety:
  - `Workflows.approve/3` rejects when `status != "pending"` → `{:error, :not_pending}`
  - Map `StaleEntryError` to friendly flash: *"This approval was already decided by another operator."*
  - After successful approve/reject, broadcast **`{:approval_decided, approval_id, status}`** on tenant topic; OrchestratorLive clears stale `@active_approval` by id.
- **D-123:** **Blocking overlay modal** (Governors: Verification) for push-triggered approvals. Show: tool name, reason, redacted args preview, connector badge/scopes when `connector_label` or `blocker_kind == "connector"`, link to `/workflows/{workflow_run_id}`. **Dismiss ("Decide later")** closes modal without calling `approve/3`; item stays in inbox.
- **D-124:** **Hybrid UX:** push modal when `@active_approval` is nil OR new approval matches focused `@runtime_query`; otherwise inbox-only highlight. Single `@active_approval` — no modal stack. Reject footer copy: *"Reject records a durable rejection and keeps the workflow paused. To continue, the run needs a new approval request or operator retry."*

### Token streaming (D-125–D-128)

- **D-125:** **v2.11 acceptance gate** = live span/trace updates + real HITL. Character-level LLM token preview is **best-effort**, not release-blocking (ReqLLM adapter currently emits `:span, :stop` only).
- **D-126:** Replace global `@token_text` coalescer with **per-`span_id` buffers**; default **75ms** via `config :scoria, :live_token_coalesce_ms, 75`. Backpressure: cap ~256 buffered chunks per span between flushes (merge/drop intermediate).
- **D-127:** Remove global `#token-stream` strip. Show coalesced preview **only on the active LLM span row** in `TraceTreeComponent`; hide/freeze when span completes.
- **D-128:** Add telemetry event **`[:scoria, :observe, :span, :delta]`** (metadata: `tenant_id`, `trace_id`, `span_id`, `chunk`) → `OperatorBroadcast` → `{:trace_delta, %{trace_id, span_id, chunk}}`. Ship handler + UI slot in v2.11; ReqLLM/runtime streaming adapter can land in a follow-up without blocking ORCH-LIVE-01.

### Verification, reconnect & adopter DX (D-129–D-131)

- **D-129:** Add **`test/scoria_web/live/orchestrator_live_integration_test.exs`** proving ORCH-LIVE-01 via `Runtime.start_run` → LiveView DOM (`eventually` until modal/trace) **without `send/2`**. Register in `mix scoria.test.semantic_fast_path` file list (+ matching contract test). Keep existing `orchestrator_live_test.exs` `send/2` tests as **UI unit tier**. Do **not** widen `closeout_order/0`.
- **D-130:** Document host session contract in adoption fragments: host apps must set **`session["tenant_id"]`** and **`session["actor_id"]`** before `/scoria` so PubSub scoping and audit refs match runtime identity. **`mix scoria.install` unchanged** (auth-agnostic).
- **D-131:** One semantic-lane test: `render_disconnect` → trigger real approval → `render_reconnect` → modal visible from **DB catch-up** (pending approval projection on mount, not only PubSub).

### External patterns & footguns (locked principles)

- **Trace-first, calm control room:** Live span names/kinds/status/timing; lazy-load retrieval/incident/budget evidence via existing `assign_async` (do not broadcast raw prompts/responses).
- **Redact → broadcast → buffer:** PII/secrets never on PubSub; attribute previews capped; approval args always redacted in projection.
- **Idempotent LiveView merge:** upsert spans by `span.id`; ignore duplicate `trace_opened` if trace already in `trace_records`.
- **Workflow-owned HITL:** UI never calls `Resume.resume_run/1` before successful `approve/3`; reject never resumes (preserve existing guard).
- **Lessons applied:** LangGraph interrupt + Temporal durable signal model; GitHub PR stale-review UX for multi-operator; OpenAI Agents SDK separate run vs trace updates; avoid Langfuse polling-only "live" views and global chat-style token strips.

### Claude's Discretion

Planner may choose exact module file layout under `lib/scoria/observe/`, hydrate query limits, and plan wave split — bounded by decisions above.

### Suggested plan waves (non-binding)

| Wave | Focus |
|------|-------|
| **01-01** | `OperatorBroadcast` + `TraceProjection` + Telemetry hook + span metadata enrichment |
| **01-02** | HITL tenant fan-out + projection `arguments_preview` + multi-operator broadcasts + modal/inbox UX |
| **01-03** | DB hydrate on mount + integration tests + semantic lane pins + adoption doc fragment |

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & vision
- `.planning/REQUIREMENTS.md` — ORCH-LIVE-01 requirement definition
- `.planning/PROJECT.md` — v2.11 milestone goal and preserve constraints
- `.planning/ROADMAP.md` — Phase 01 scope

### Prompts / research SSOT
- `prompts/phoenix-ai-lib-deep-research.md` — PubSub+LiveView streaming (§9.2–9.3), trace-first ops loop, Governors/HITL patterns, footguns (coalesce, reconnect, redaction)
- `prompts/scoria-brand-book-deep-research.md` — Field Engineer voice, evidence-over-intuition, calm operator UX, no raw chain-of-thought
- `prompts/scoria-gsd-kickoff.md` — batteries-included LiveView operator UI objective
- `prompts/sztheory-elixir-dna.md` — embedded LiveView dashboard, Ecto-native state, operator-first DX

### Code anchors
- `lib/scoria_web/live/orchestrator_live.ex` — subscriber, handlers, modal, token coalesce (to refactor per D-126–D-127)
- `lib/scoria/workflows.ex` — `mark_waiting_for_approval/3`, run-scoped PubSub, `@topic_prefix`
- `lib/scoria/observe/telemetry.ex` — telemetry attach point for D-118
- `lib/scoria/observe/buffer.ex` — durability path (not live UI hook)
- `lib/scoria/observe/redactor.ex` — redaction boundary
- `lib/scoria/workflows/remote_approval_projection.ex` — inbox + modal DTO base
- `lib/scoria/repo/trace.ex`, `lib/scoria/repo/span.ex` — hydrate source
- `test/scoria_web/live/orchestrator_live_test.exs` — existing UI tests (keep as unit tier)
- `test/scoria/integration/runtime_integration_test.exs` — precedent for real PubSub integration tests
- `lib/mix/tasks/scoria.test.semantic_fast_path.ex` — lane pin location for D-129

### Constraints
- `VerificationLanes.closeout_order/0` — do not widen (v2.4 contract)
- `.planning/milestones/v2.10-phases/82-docs-truth-milestone-closeout/82-VERIFICATION.md` — hollow-prop pattern to close

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **OrchestratorLive** — PubSub subscribe, `stream(:traces)`, token coalesce timer, HITL modal, `ApprovalInboxComponent`, `TraceTreeComponent`, `load_operator_surface/1`
- **Workflows** — durable approval creation, audit outbox, run-scoped broadcast pattern to mirror
- **RemoteApprovalProjection** — curated approval maps for inbox; extend with `arguments_preview`
- **Observe.Telemetry + Redactor + Buffer** — redaction boundary and span persistence pipeline
- **WorkflowLive.Show** — depth/tree patterns and run-scoped PubSub consumer precedent

### Established Patterns
- Context modules own topic prefixes (`Workflows.@topic_prefix`)
- LiveView subscribes only in `connected?(socket)`
- High-frequency UI coalescing in LiveView (75ms token buffer today)
- Integration tests use `Scoria.IntegrationCase` + `eventually/1` + dedicated Endpoint

### Integration Points
- `mark_waiting_for_approval/3` success path → tenant `OperatorBroadcast.hitl_request/2`
- `Observe.Telemetry` span stop → `OperatorBroadcast.span_stopped/1`
- OrchestratorLive mount → DB hydrate + existing subscribe
- `Workflows.approve/3` success → `approval_decided` broadcast + existing resume path

### Known gaps (HOLLOW_PROP)
- No producer for `{:new_trace, _}`, `{:token, _}`, `{:hitl_request, _}` on `scoria:runs:*`
- Tests use `send(view.pid, ...)` — not production path
- Buffer not guaranteed started in host app (install/docs may need note when operator broadcast enabled)

</code_context>

<specifics>
## Specific Ideas

- Unified message contract on **`scoria:runs:{tenant_id}`** minimizes subscription churn and matches existing OrchestratorLive mount.
- Model HITL as **LangGraph interrupt + Temporal signal**: interrupt = `mark_waiting_for_approval`; signal = `approve/3`; UI = GitHub-style inbox + blocking verify modal.
- Brand copy already in modal: *"Record a workflow-owned decision… durably before any resume attempt."* — keep and extend with accurate reject copy (D-124).
- Shape of AI Governors: show action context (tool, reason, redacted args) before side-effecting resume — not a bare approve button.

</specifics>

<deferred>
## Deferred Ideas

- **Separate `scoria:approvals:{tenant_id}` topic** — rejected for v2.11; single tenant runs topic is simpler (D-114)
- **`scoria:traces:{trace_id}` topic** — defer until trace-detail LiveView
- **Full ReqLLM streaming adapter** — stub delta telemetry in v2.11; adapter in follow-up
- **OTel export of operator PubSub events** — separate milestone
- **Multi-tab operator sync / approval claims via Presence** — v2.12+
- **Mobile-responsive HITL modal** — polish pass
- **Gallery `/scoria` landing smoke in advisory lane** — optional supplement to integration tests (D-126 note from research)
- **Global token strip** — remove (D-127)
- **Installer session key injection** — host-owned; document only (D-130)

</deferred>

---

*Phase: 01-orchestrator-live-wiring*
*Context gathered: 2026-05-30*
