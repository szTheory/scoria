# Phase 7: SRE, Circuit Breakers & Ecosystem Synergy - Research

**Researched:** 2026-05-11 [VERIFIED: system date]
**Domain:** Phoenix-native runtime governance, circuit breaking, audit export, and incident evidence for Scoria [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
**Confidence:** MEDIUM [VERIFIED: author assessment]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Budget enforcement and circuit breakers
- **D-01:** Use a hybrid control plane: Ecto owns policy, reservations, actual usage, and trip history; Hammer accelerates short-window limits; Fuse handles external-effect breakers. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- **D-02:** Reserve estimated spend before paid LLM steps and high-risk tool steps, then reconcile to actual provider/tool usage after execution. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- **D-03:** Put circuit breakers around external effects only: provider calls, remote MCP servers, and other side-effecting integrations. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- **D-04:** Keep the default policy small and explicit: warn at 80%, trip at 100%, and add only a few loop guards such as max workflow steps, repeated tool hash, and consecutive failure caps. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- **D-05:** Treat Plug-level rate limiting as a secondary ingress perimeter, not as the core spend-governance model. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]

### SLO contract and alerts
- **D-06:** Make the primary SLO contract budget-based, with reason-coded bad events and error budgets. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- **D-07:** Track separate SLIs for latency, quality, cost, and critical tool reliability. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- **D-08:** Page only on fast-burning user-facing budgets or breaker trips. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- **D-09:** CI baseline dips and slower quality/cost regressions should create review alerts or tickets, not production pages by default. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- **D-10:** Keep a composite Scoria health rollup in dashboards, but do not make it the main pager source. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- **D-11:** Version scorers, thresholds, and baselines so incidents always point at a specific scorer/version pair. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]

### Audit export boundary
- **D-12:** Use a hybrid capture model: write a durable audit-outbox row in the same transaction as the local truth change, then fan out telemetry after commit. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- **D-13:** Keep telemetry as the public integration contract, but do not rely on telemetry handlers alone for sensitive audit delivery. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- **D-14:** Export relays are optional and configurable through a behavior or MFA, with a no-op default; Threadline is not a hard dependency of core Scoria. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- **D-15:** Mandatory external-audit candidates are tool approval requested/approved/denied/expired, sensitive MCP access granted/denied, and policy-sensitive tool invocations. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- **D-16:** Redact raw payloads and arguments at the boundary; prefer references, hashes, policy classes, and trace IDs. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]

### Ecosystem posture
- **D-17:** Keep core Scoria Phoenix/Ecto/Telemetry-native. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- **D-18:** Prefer telemetry plus narrow behaviors such as `Scoria.AuditSink` and `Scoria.AlertSink` over hard dependencies. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- **D-19:** Ship first-party optional adapters only where they materially improve day-one ergonomics, especially for Threadline, Chimeway, and Mailglass. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- **D-20:** Keep Parapet integration mostly telemetry-driven, with small helper modules rather than a deep adapter stack. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]

### Operator UX and DX
- **D-21:** Favor boring, least-surprise defaults that surface evidence in the existing trace-first LiveView experience. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- **D-22:** Use stable incident keys so related signals dedupe into one reviewable case. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- **D-23:** Keep notification routing simple in this phase; do not introduce complex alert trees or auto-remediation workflows yet. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- **D-24:** Make every alert and incident deep-link back to the trace explorer and the underlying Ecto evidence. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]

### Phase Discretion
- Exact schema field names for `alert_policies`, `alert_events`, `incidents`, `incident_events`, `notification_deliveries`, and `audit_outbox_events`. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- Exact job transport for the audit relay and alert relay, provided the durability and retry semantics stay intact. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- Exact threshold values beyond the default 80% warn / 100% trip policy. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]

### Deferred Ideas (OUT OF SCOPE)
- Full production anomaly detection beyond thresholded windows. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- Auto-remediation or runbook execution. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- Cross-service SLO math in Parapet/Grafana-class detail. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- Fine-grained per-tenant paging policies. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- ML-driven alert correlation. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- Complex notification routing trees beyond simple Chimeway/Mailglass adapters. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SRE-01 | Persist budget policies, spend reservations, actual usage reconciliation, and trip history in Ecto. [VERIFIED: .planning/MILESTONES.md] | `Standard Stack`, `Recommended Data Contracts`, and `Architecture Patterns` define the durable control-plane model. |
| SRE-02 | Enforce preflight reservations and loop guards at workflow-step and MCP execution boundaries before external effects run. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md; VERIFIED: lib/scoria/workflows/runtime.ex; VERIFIED: lib/scoria/mcp/executor.ex] | `Architectural Responsibility Map` and `Pattern 1` place enforcement in `Scoria.Workflows.Runtime` and `Scoria.MCP.Executor`. |
| SRE-03 | Wrap provider calls, remote MCP servers, and other side-effecting integrations in circuit breakers, but not local pure code paths. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md] | `Standard Stack`, `Pattern 2`, and `Common Pitfalls` keep Fuse at external-effect seams only. |
| SRE-04 | Emit reason-coded latency, quality, cost, and tool-reliability signals that can back budget-based SLOs and incident dedupe. [VERIFIED: .planning/MILESTONES.md; VERIFIED: .planning/memory/parapet-synergy.md] | `Recommended Data Contracts`, `Operator UX Guidance`, and `Validation Architecture` define incident and alert records. |
| SRE-05 | Write durable audit-outbox rows in the same transaction as approval, MCP-access, and policy-sensitive tool events, with optional Threadline relay after commit. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md; VERIFIED: lib/scoria/workflows.ex] | `Pattern 3`, `Standard Stack`, and `Resolved Execution Choices` define the outbox-first export model. |
| SRE-06 | Create review alerts and notification deliveries for CI/eval regressions and breaker or budget incidents using optional Chimeway/Mailglass sinks with no-op defaults. [VERIFIED: .planning/MILESTONES.md; VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md] | `Standard Stack`, `Recommended Data Contracts`, and `Alternatives Considered` keep notification routing simple and optional. |
| SRE-07 | Surface incidents, budget state, breaker state, and audit evidence in the existing trace-first LiveView surface with deep links to run evidence. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md; VERIFIED: lib/scoria_web/live/orchestrator_live.ex] | `Operator UX Guidance` and `Recommended Project Structure` keep the UI additive to `ScoriaWeb.OrchestratorLive`. |
| SRE-08 | Keep the implementation Phoenix/Ecto/Telemetry-native and package optional ecosystem integrations behind narrow behaviors instead of hard dependencies. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md; VERIFIED: prompts/sztheory-elixir-dna.md] | `Summary`, `Standard Stack`, and `Resolved Execution Choices` constrain the architecture. |
</phase_requirements>

## Summary

Phase 7 should add a small `Scoria.SRE` subsystem that behaves like the rest of the repo: Ecto-backed truth, explicit context functions, narrow optional adapter behaviors, and LiveView projections over persisted evidence instead of hidden background magic. `Scoria.Workflows` already owns durable state transitions, `Scoria.Workflows.Runtime` already owns pre-step execution, `Scoria.MCP.Executor` already isolates side effects, and `Scoria.Observe.Redactor` already owns payload sanitization, so the new work should attach to those seams rather than inventing a second control plane. [VERIFIED: lib/scoria/workflows.ex; VERIFIED: lib/scoria/workflows/runtime.ex; VERIFIED: lib/scoria/mcp/executor.ex; VERIFIED: lib/scoria/observe/redactor.ex]

The cleanest slice order is: 1) land the `Scoria.SRE` context plus Ecto schemas for policies, reservations, breaker trips, incidents, notification deliveries, and audit outbox rows; 2) add budget reservation/reconciliation and loop guards around workflow steps and MCP execution; 3) wrap external effects in Fuse-backed breakers; 4) add outbox relays and optional sinks for Threadline, Chimeway, and Mailglass; 5) project incident evidence into `ScoriaWeb.OrchestratorLive`; 6) add telemetry helpers for Parapet-facing SLI/SLO consumers without taking a hard dependency on a Parapet package. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md; VERIFIED: .planning/MILESTONES.md; VERIFIED: lib/scoria_web/live/orchestrator_live.ex; VERIFIED: mix hex.info parapet returned no package]

**Primary recommendation:** Build Phase 7 around a new `Scoria.SRE` context with transactionally durable policy and outbox rows, Hammer for short-window counters, Fuse for external-effect breakers, and optional sink adapters behind `Scoria.SRE.AuditSink` and `Scoria.SRE.AlertSink`. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md; CITED: https://hexdocs.pm/hammer/Hammer.html; CITED: https://hexdocs.pm/fuse/fuse.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Budget policy, reservations, reconciled usage, breaker trips, incidents, audit outbox | Database / Storage | API / Backend | Ecto is already Scoria's durable source of truth, and Phase 7 explicitly locks policy, usage, and trip history into Ecto. [VERIFIED: .planning/STATE.md; VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md] |
| Reservation preflight and loop-guard checks | API / Backend | Database / Storage | `Scoria.Workflows.Runtime.execute_step/2` and `Scoria.MCP.Executor.execute/4` are the current enforcement seams before side effects occur. [VERIFIED: lib/scoria/workflows/runtime.ex; VERIFIED: lib/scoria/mcp/executor.ex] |
| Circuit breaker evaluation for provider or MCP effects | API / Backend | — | Fuse is a runtime gate and should protect external thunks, not LiveView or database rendering. [CITED: https://hexdocs.pm/fuse/fuse.html; VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md] |
| Telemetry fanout and optional ecosystem adapters | API / Backend | — | Telemetry is the public event seam, while sink adapters should remain narrow optional modules. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md; VERIFIED: prompts/sztheory-elixir-dna.md] |
| Incident review, budget status, and audit evidence drilldown | Frontend Server (LiveView) | Browser / Client | `ScoriaWeb.OrchestratorLive` is already the trace-first operator projection surface and should stay that way. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex; VERIFIED: .planning/phases/06-corpus/06-CONTEXT.md] |
| Parapet-facing SLI/SLO consumption | API / Backend | — | The repo goal is telemetry-driven helper modules, not a deep SRE platform adapter. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md; VERIFIED: .planning/memory/parapet-synergy.md] |

## Standard Stack

### Core

| Library / Layer | Version | Purpose | Why It Fits |
|-----------------|---------|---------|-------------|
| Ecto + PostgreSQL | `ecto 3.13.6`, `ecto_sql 3.13.5`, PostgreSQL 14.17 [VERIFIED: mix.lock; VERIFIED: `psql --version`] | Durable policies, reservations, outbox rows, incidents, and delivery history | Matches shipped Scoria phases and the locked decision that Ecto owns policy and history. [VERIFIED: .planning/STATE.md; VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md] |
| Phoenix LiveView | `phoenix_live_view 1.1.30` [VERIFIED: mix.lock] | Operator projection for incidents, budgets, and evidence | Matches the existing dashboard and keeps the UX trace-first. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex; VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md] |
| Telemetry | `telemetry 1.4.1` [VERIFIED: mix.lock] | Public integration seam for SLI/SLO, alerts, and adapter fanout | Already used in observability and MCP execution paths. [VERIFIED: lib/scoria/mcp/executor.ex; VERIFIED: test/scoria/observe/telemetry_test.exs] |
| Hammer | `7.3.0` published 2026-03-31 [VERIFIED: mix hex.info hammer] | Short-window counter acceleration for per-tenant/per-user budget windows and ingress perimeter checks | Official docs show built-in ETS support and `hit/3` / `hit/4` return allow-or-deny tuples with retry timing, which fits lightweight window checks without external infra. [CITED: https://hexdocs.pm/hammer/Hammer.html] |
| Fuse | `2.5.0` published 2021-07-01 [VERIFIED: mix hex.info fuse] | External-effect circuit breaking around provider and remote MCP calls | Official docs expose exactly the small API Phase 7 needs: `install/2`, `ask/2`, `run/3`, `melt/1`, and `reset/1`. [CITED: https://hexdocs.pm/fuse/fuse.html] |

### Optional ecosystem adapters

| Library / Layer | Version | Purpose | When to Use |
|-----------------|---------|---------|-------------|
| Threadline | `0.5.0` published 2026-05-08 [VERIFIED: mix hex.info threadline] | Immutable audit export target | Use only when the host app wants audit history in the same Phoenix/Ecto estate; Threadline documents trigger-backed capture, semantic actions, and JSON export APIs. [CITED: https://hexdocs.pm/threadline/readme.html] |
| Chimeway | `1.0.0` published 2026-05-08 [VERIFIED: mix hex.info chimeway] | Review-alert and incident notification sink | Use as an optional alert sink; keep core Scoria functional with a no-op sink when absent. [VERIFIED: mix hex.info chimeway] |
| Mailglass | `1.0.0` published 2026-05-07 [VERIFIED: mix hex.info mailglass] | Email-based alert delivery sink | Use when the host app already runs Mailglass; Mailglass documents telemetry spans for delivery and webhook ingestion that fit Scoria's event-driven posture. [CITED: https://hexdocs.pm/mailglass/getting-started.html; CITED: https://hexdocs.pm/mailglass/telemetry.html] |
| Parapet helpers | No Hex package found as of 2026-05-11 [VERIFIED: mix hex.info parapet returned no package] | Telemetry naming and helper modules only | Keep Parapet-facing work to helper functions and stable telemetry metadata until an official package exists. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md] |

## Recommended Project Structure

```text
lib/
├── scoria/
│   ├── sre.ex
│   ├── workflows.ex                      # add transactional reservation / outbox hooks
│   ├── workflows/runtime.ex              # add preflight guard + breaker boundary
│   ├── mcp/executor.ex                   # add reservation + breaker wrapper
│   ├── observe/redactor.ex               # reuse for audit/alert payload scrubbing
│   └── sre/
│       ├── budget_policy.ex
│       ├── budget_reservation.ex
│       ├── breaker_trip.ex
│       ├── alert_policy.ex
│       ├── alert_event.ex
│       ├── incident.ex
│       ├── incident_event.ex
│       ├── notification_delivery.ex
│       ├── audit_outbox_event.ex
│       ├── audit_sink.ex
│       ├── alert_sink.ex
│       ├── relay.ex
│       ├── telemetry.ex
│       ├── budget_engine.ex
│       ├── breaker_registry.ex
│       └── adapters/
│           ├── threadline.ex
│           ├── chimeway.ex
│           ├── mailglass.ex
│           └── parapet.ex
├── scoria_web/
│   ├── components/
│   │   └── incident_evidence_component.ex
│   └── live/
│       └── orchestrator_live.ex
priv/repo/migrations/
└── *_create_sre_tables.exs
```

The structure above keeps all new nouns under one `Scoria.SRE` context, preserves the existing runtime seams, and avoids scattering budget or incident logic across unrelated modules. [VERIFIED: lib/scoria/workflows.ex; VERIFIED: lib/scoria/workflows/runtime.ex; VERIFIED: lib/scoria/mcp/executor.ex]

## Recommended Data Contracts

### Durable control-plane nouns

- `BudgetPolicy`: scope key (`tenant_id`, `actor_id`, `workflow_name`, or `global`), resource kind (`token_in`, `token_out`, `cost_usd`, `tool_calls`, `workflow_steps`), window config, warn threshold, trip threshold, and loop-guard caps. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- `BudgetReservation`: run and step linkage, subject key, policy snapshot, estimated units, actual units, status (`reserved`, `reconciled`, `released`, `tripped`), provider/tool reference, and trace linkage. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md; VERIFIED: lib/scoria/workflows.ex]
- `BreakerTrip`: breaker key, integration kind (`provider`, `remote_mcp`, `tool`), reason code, state (`closed`, `open`, `half_open`), failure counters, last failure hash, opened-at, reset-at, and run or step linkage. [CITED: https://hexdocs.pm/fuse/fuse.html; VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- `AlertPolicy`: SLI kind, severity routing (`review`, `page`), burn-window metadata, scorer or baseline version, sink routing class, and enabled flag. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- `AlertEvent`: incident key, reason code, measured value, threshold snapshot, subject refs, scorer or baseline refs, and status (`new`, `deduped`, `acked`, `resolved`). [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- `Incident`: stable dedupe key, state, severity, summary, first-seen and last-seen timestamps, primary trace or run refs, and evidence summary. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- `IncidentEvent`: append-only evidence line items for incident state changes, linked alert events, linked budget trips, and operator notes. [ASSUMED]
- `NotificationDelivery`: sink kind, incident or alert linkage, delivery payload hash, attempt count, last error, and delivery status. [ASSUMED]
- `AuditOutboxEvent`: event type, actor ref, run or step refs, approval or access refs, policy class, redacted payload, payload hash, sink status, and dedupe key. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md; VERIFIED: lib/scoria/observe/redactor.ex]

### Canonical reservation shape

Use one internal map shape for runtime preflight and reconciliation:

```elixir
%{
  subject: %{tenant_id: tenant_id, actor_id: actor_id},
  resource: :cost_usd,
  estimated_units: Decimal.new("0.0150"),
  actual_units: nil,
  policy_key: "tenant:default:cost_usd",
  reason_code: :llm_completion,
  run_id: run_id,
  step_id: step_id,
  trace_id: trace_id
}
```

This keeps reservation, reconciliation, and incident emission deterministic across workflow and MCP paths. [ASSUMED]

### Canonical incident key

Use a stable, low-cardinality incident key everywhere:

```elixir
"#{tenant_id}:#{subject_kind}:#{policy_key}:#{reason_code}:#{window_bucket}"
```

That shape preserves the locked dedupe requirement while staying explainable to operators. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]

## Architecture Patterns

### Data flow

```text
workflow step / MCP call
  -> preflight policy load
  -> budget reservation + loop-guard check
  -> external-effect breaker check
  -> side effect executes
  -> actual usage reconciliation
  -> alert / incident evaluation
  -> audit outbox insert + telemetry fanout
  -> LiveView incident projection
  -> optional Threadline / Chimeway / Mailglass sinks
```

The order matters: reservation and breaker checks happen before the side effect, while reconciliation and sink delivery happen after local truth is durable. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md; VERIFIED: lib/scoria/workflows/runtime.ex; VERIFIED: lib/scoria/mcp/executor.ex]

### Pattern 1: Reserve-before-effect runtime guard

**What:** Wrap `Scoria.Workflows.Runtime.execute_step/2` and `Scoria.MCP.Executor.execute/4` with one preflight function that loads policy, evaluates loop guards, reserves estimated units, and rejects the step before side effects if the request would trip policy. [VERIFIED: lib/scoria/workflows/runtime.ex; VERIFIED: lib/scoria/mcp/executor.ex]

**When to use:** Any paid LLM step, any remote MCP call, and any tool with material side effects or spend. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]

**Example:**

```elixir
with {:ok, reservation} <- Scoria.SRE.reserve_step(run, step, ctx),
     :ok <- Scoria.SRE.check_breaker(step, ctx),
     {:ok, result} <- invoke_external_effect(step, ctx) do
  Scoria.SRE.reconcile_step(reservation, result)
else
  {:error, :budget_tripped, details} -> Scoria.SRE.trip_incident(run, step, details)
  {:error, :breaker_open, details} -> Scoria.SRE.trip_incident(run, step, details)
end
```

The exact module names are discretionary, but the flow is locked by D-01 through D-04. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]

### Pattern 2: External-effect Fuse wrapper

**What:** Install one fuse per external integration target and execute the remote thunk via `:fuse.run/3`; call `:fuse.melt/1` or return `{melt, result}` on failure paths so repeated faults open the circuit. [CITED: https://hexdocs.pm/fuse/fuse.html]

**When to use:** Provider calls, remote MCP servers, and other external effect surfaces only. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]

**Example:**

```elixir
case :fuse.run({:provider, provider_key}, fn ->
       case Provider.call(request) do
         {:ok, response} -> {:ok, response}
         {:error, reason} -> {:melt, {:error, reason}}
       end
     end, :sync) do
  {:ok, response} -> {:ok, response}
  :blown -> {:error, :breaker_open}
  {:error, :not_found} -> {:error, :breaker_missing}
end
```

### Pattern 3: Transactional audit outbox plus post-commit fanout

**What:** Insert `AuditOutboxEvent` rows inside the same `Ecto.Multi` that mutates the underlying approval or policy truth, then emit telemetry after commit and let a supervised relay claim pending rows for optional sink delivery. [VERIFIED: lib/scoria/workflows.ex; VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]

**When to use:** Approval requested/approved/denied/expired, sensitive MCP access decisions, and policy-sensitive tool invocations. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]

**Example:**

```elixir
Multi.new()
|> Multi.update(:approval, Approval.changeset(approval, %{status: "approved"}))
|> Multi.insert(:audit_outbox, AuditOutboxEvent.changeset(%AuditOutboxEvent{}, attrs))
|> Repo.transaction()
|> case do
  {:ok, %{audit_outbox: event}} ->
    :telemetry.execute([:scoria, :audit, :outbox, :created], %{}, %{event_id: event.id})
    {:ok, event}
  error ->
    error
end
```

### Anti-patterns to avoid

- Do not treat `Hammer.Plug` or ingress request throttling as the core spend-governance model; D-05 explicitly rejects that. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- Do not put Fuse around local pure functions, Ecto writes, or LiveView rendering; the locked breaker scope is external effects only. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- Do not send sensitive audit facts straight to telemetry-only handlers or webhooks without a durable outbox row first. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- Do not page on every CI or eval regression; slower quality and cost drifts should open review cases, not production pages. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- Do not persist raw arguments or prompt payloads in incident or audit export rows when `Scoria.Observe.Redactor` can store references, hashes, and redacted fields instead. [VERIFIED: lib/scoria/observe/redactor.ex; VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]

## Operator UX Guidance

- Keep the first operator surface inside `ScoriaWeb.OrchestratorLive` and its existing trace selection flow; do not add a second standalone incident app. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex; VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- Show budget state as a compact evidence strip on the selected run: policy key, reserved units, reconciled actuals, warn or trip state, and the exact threshold snapshot used. [ASSUMED]
- Show breaker state as calm badges with explicit next action: `closed`, `open until <time>`, `half-open`, or `admin-disabled`. [CITED: https://hexdocs.pm/fuse/fuse.html]
- Render incident panels as append-only evidence notebooks: incident summary, reason code, first and last seen, linked traces, linked approvals, baseline or scorer version, and notification delivery outcomes. [VERIFIED: prompts/scoria-brand-book-deep-research.md; VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- Keep every row deep-linkable back to the durable trace or run view; the incident screen is a lens over evidence, not a replacement for the trace explorer. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- Load heavy incident evidence asynchronously with the same LiveView patterns already used for retrieval evidence, rather than pushing full payloads into long-lived assigns. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex]

## Common Pitfalls

- **Fake durability:** Writing incident or audit rows after the local truth change commits will create unverifiable gaps under crash conditions; the outbox row has to share the transaction. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md; VERIFIED: lib/scoria/workflows.ex]
- **Double-spend from missing reservations:** If the runtime only records actual usage after the fact, Scoria cannot stop runaway loops before money or tool quota is burned. [VERIFIED: .planning/MILESTONES.md; VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- **Breaker sprawl:** Installing a fuse per run or per trace ID would create high-cardinality runtime state with little operator value; use stable integration keys instead. [ASSUMED]
- **Paging fatigue:** Promoting every regression to page severity would violate D-08 and D-09 and train operators to ignore alerts. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- **Leaky payload exports:** Copying raw tool args or prompt bodies into incident, audit, or notification payloads would bypass the existing redaction boundary. [VERIFIED: lib/scoria/observe/redactor.ex]
- **Hard-coupling optional ecosystem libs:** Making Threadline, Mailglass, or Chimeway required dependencies would contradict the locked adapter posture and raise install friction. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md; VERIFIED: prompts/sztheory-elixir-dna.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir / Mix | All Phase 7 code and tests | ✓ [VERIFIED: `mix --version`] | Elixir 1.19.5 / Mix 1.19.5 [VERIFIED: `mix --version`] | — |
| PostgreSQL | Durable policies, incidents, outbox rows | ✓ [VERIFIED: `psql --version`] | 14.17 [VERIFIED: `psql --version`] | — |
| Hammer | Short-window counters | Not installed yet in repo [VERIFIED: rg mix.exs,mix.lock] | Latest 7.3.0 [VERIFIED: mix hex.info hammer] | Plain Ecto counters if adoption must be staged, but this weakens D-01. [ASSUMED] |
| Fuse | Circuit breakers | Not installed yet in repo [VERIFIED: rg mix.exs,mix.lock] | Latest listed 2.5.0 [VERIFIED: mix hex.info fuse] | A custom breaker is possible but explicitly not recommended for this phase. [ASSUMED] |
| Threadline | Optional audit sink | Not installed yet in repo [VERIFIED: rg mix.exs,mix.lock] | 0.5.0 [VERIFIED: mix hex.info threadline] | No-op audit sink with local outbox only. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md] |
| Chimeway | Optional notification sink | Not installed yet in repo [VERIFIED: rg mix.exs,mix.lock] | 1.0.0 [VERIFIED: mix hex.info chimeway] | No-op alert sink or Mailglass-only sink. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md] |
| Mailglass | Optional email sink | Not installed yet in repo [VERIFIED: rg mix.exs,mix.lock] | 1.0.0 [VERIFIED: mix hex.info mailglass] | No-op alert sink or Chimeway-only sink. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md] |

**Missing dependencies with no fallback:**
- None for planning; core Phase 7 can begin with local Ecto truth and no-op sinks. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]

**Missing dependencies with fallback:**
- Hammer, Fuse, Threadline, Chimeway, and Mailglass are all absent from the repo today, but only Hammer and Fuse are part of the locked core stack; the sink libraries remain optional. [VERIFIED: rg mix.exs,mix.lock; VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit + Phoenix.LiveViewTest [VERIFIED: test/**/*.exs] |
| Config file | `test/test_helper.exs` [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/scoria/mcp/executor_test.exs test/scoria/workflows/runtime_test.exs test/scoria_web/live/orchestrator_live_test.exs` [VERIFIED: command run on 2026-05-11; 18 tests, 0 failures] |
| Full suite command | `mix test` [VERIFIED: existing repo convention] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SRE-01 | Budget policy persistence and reservation reconciliation | unit + context | `mix test test/scoria/sre/budget_engine_test.exs` | ❌ Wave 0 |
| SRE-02 | Runtime preflight rejection before side effects | unit | `mix test test/scoria/workflows/runtime_test.exs` | ✅ extend existing |
| SRE-03 | MCP executor breaker wrapping and error mapping | unit | `mix test test/scoria/mcp/executor_test.exs` | ✅ extend existing |
| SRE-04 | Incident dedupe, severity routing, and baseline-version capture | unit + context | `mix test test/scoria/sre/incident_test.exs` | ❌ Wave 0 |
| SRE-05 | Outbox written in same transaction as approval/policy truth | integration | `mix test test/scoria/sre/audit_outbox_test.exs` | ❌ Wave 0 |
| SRE-06 | Optional sink delivery retry and no-op fallback | unit | `mix test test/scoria/sre/relay_test.exs` | ❌ Wave 0 |
| SRE-07 | LiveView incident evidence and budget status projection | liveview | `mix test test/scoria_web/live/orchestrator_live_sre_test.exs` | ❌ Wave 0 |
| SRE-08 | Telemetry helpers emit low-cardinality Parapet-facing metadata | unit | `mix test test/scoria/sre/telemetry_test.exs` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `mix test test/scoria/mcp/executor_test.exs test/scoria/workflows/runtime_test.exs` [VERIFIED: existing targeted suites]
- **Per wave merge:** `mix test` [VERIFIED: repo convention]
- **Phase gate:** Full suite green before `/gsd-verify-work` [VERIFIED: workflow convention]

### Wave 0 Gaps

- `test/scoria/sre/budget_engine_test.exs` to cover reservation math, warn/trip thresholds, and loop guards. [ASSUMED]
- `test/scoria/sre/incident_test.exs` to cover incident-key dedupe, severity routing, and scorer-version capture. [ASSUMED]
- `test/scoria/sre/audit_outbox_test.exs` to prove transactional outbox insertion around approvals and policy-sensitive actions. [ASSUMED]
- `test/scoria/sre/relay_test.exs` to cover no-op, Threadline, Chimeway, and Mailglass sink behaviors behind common contracts. [ASSUMED]
- `test/scoria_web/live/orchestrator_live_sre_test.exs` to keep new incident evidence isolated from the existing retrieval tests. [ASSUMED]

## Security Domain

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Reuse host-app auth around the existing embedded dashboard and any sink-triggering operator actions. [VERIFIED: prompts/sztheory-elixir-dna.md; VERIFIED: lib/scoria_web/router.ex] |
| V4 Access Control | yes | Keep operator actions policy-backed and audit every approval or sensitive MCP access decision through the outbox. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md] |
| V5 Input Validation | yes | Validate sink payloads, policy attrs, and incident attrs through Ecto changesets before persistence or delivery. [VERIFIED: repo-wide Ecto pattern in lib/scoria/workflows.ex; VERIFIED: .planning/STATE.md] |
| V7 Error Handling | yes | Prefer explicit reason codes and redacted error envelopes over raw exceptions in incidents and notifications. [VERIFIED: lib/scoria/observe/redactor.ex; VERIFIED: lib/scoria/mcp/executor.ex] |
| V8 Data Protection | yes | Redact payloads at export and notification boundaries; store references, hashes, and trace IDs instead of full sensitive bodies. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md; VERIFIED: lib/scoria/observe/redactor.ex] |

## Alternatives Considered

| Option | Why Not Default |
|--------|------------------|
| Ingress-only request throttling with Plug or `Hammer.Plug` | Conflicts with D-05 because it limits entry points, not actual spend or loop behavior inside workflows and tools. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md; CITED: https://hexdocs.pm/hammer/Hammer.html] |
| Custom in-house breaker instead of Fuse | The locked decision already names Fuse, and Fuse exposes the exact circuit lifecycle Phase 7 needs without hand-rolling breaker state. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md; CITED: https://hexdocs.pm/fuse/fuse.html] |
| Threadline as a required dependency | Conflicts with D-14 and D-18; local outbox truth plus optional relay keeps core Scoria install friction low. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md] |
| Oban as a required relay substrate | Oban is not present in the repo, and a supervised relay with durable rows is sufficient for this phase's simpler retry model. [VERIFIED: rg mix.exs,mix.lock; ASSUMED] |
| Standalone incident LiveView or new dashboard app | Conflicts with D-21 and the existing trace-first operator mental model. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md; VERIFIED: lib/scoria_web/live/orchestrator_live.ex] |
| Direct webhook delivery without a local outbox | Violates D-12 and makes audit delivery unverifiable under crashes or retries. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md] |

## Resolved Execution Choices

- Land a new `Scoria.SRE` public context and keep all new nouns beneath it; do not bury Phase 7 logic inside `Scoria.Workflows` or `Scoria.MCP` modules alone. [VERIFIED: prompts/phoenix-ai-lib-deep-research.md; VERIFIED: repo context naming pattern]
- Use `Scoria.Workflows.Runtime` and `Scoria.MCP.Executor` as the only preflight enforcement seams for reservations and breakers. [VERIFIED: lib/scoria/workflows/runtime.ex; VERIFIED: lib/scoria/mcp/executor.ex]
- Use a supervised relay worker plus durable Ecto rows for audit and alert delivery instead of introducing Oban in this phase. [VERIFIED: rg mix.exs,mix.lock; ASSUMED]
- Keep first-party adapters thin: `Scoria.SRE.Adapters.Threadline`, `Scoria.SRE.Adapters.Chimeway`, `Scoria.SRE.Adapters.Mailglass`, and `Scoria.SRE.Adapters.Parapet`. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- Deduplicate incidents by stable incident key and keep related alert events append-only under the same incident. [VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md]
- Plan Phase 7 as at least five executable slices: `Wave 0 schemas/contracts`, `budget engine`, `breaker wiring`, `outbox + sinks`, and `operator evidence`. [VERIFIED: author synthesis from locked scope and repo seams]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `IncidentEvent` and `NotificationDelivery` should be append-only evidence records rather than mutable status blobs. [ASSUMED] | Recommended Data Contracts | Minor schema churn if a different persistence style is chosen. |
| A2 | A supervised relay worker with durable rows is sufficient for Phase 7, so Oban is unnecessary right now. [ASSUMED] | Alternatives Considered / Resolved Execution Choices | Planner may need an extra transport slice if delivery volume or retry semantics are stricter than expected. |
| A3 | Budget strips and incident notebooks should be additive panels inside `OrchestratorLive` instead of new routes. [ASSUMED] | Operator UX Guidance | UI tasks may need re-splitting if the planner chooses separate routes. |
| A4 | Breaker keys should be integration-scoped rather than run-scoped to avoid high-cardinality runtime state. [ASSUMED] | Common Pitfalls | Wrong granularity could produce noisy or ineffective breaker behavior. |
| A5 | The canonical reservation map and incident key formats shown here are the best low-friction defaults. [ASSUMED] | Recommended Data Contracts | Exact field names may change during planning. |

## Sources

### Primary

- Local repo code and planning artifacts:
  - `lib/scoria/workflows.ex`
  - `lib/scoria/workflows/runtime.ex`
  - `lib/scoria/mcp/executor.ex`
  - `lib/scoria/observe/redactor.ex`
  - `lib/scoria_web/live/orchestrator_live.ex`
  - `.planning/MILESTONES.md`
  - `.planning/STATE.md`
  - `.planning/phases/05-caldera/05-CONTEXT.md`
  - `.planning/phases/06-corpus/06-CONTEXT.md`
  - `.planning/phases/07-seismograph/07-CONTEXT.md`
- Hammer docs: https://hexdocs.pm/hammer/Hammer.html
- Fuse docs: https://hexdocs.pm/fuse/fuse.html
- Threadline docs: https://hexdocs.pm/threadline/readme.html
- Mailglass docs: https://hexdocs.pm/mailglass/getting-started.html
- Mailglass telemetry docs: https://hexdocs.pm/mailglass/telemetry.html

### Version verification

- `mix hex.info hammer`
- `mix hex.info fuse`
- `mix hex.info threadline`
- `mix hex.info chimeway`
- `mix hex.info mailglass`
- `mix hex.info parapet`

## RESEARCH COMPLETE
